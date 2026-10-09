require 'minitest/autorun'
require 'tmpdir'
require 'open3'
require_relative '../normalize_frameworks'

class NormalizeFrameworksTest < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir('framework-packaging-test')
    @root = Pathname.new(@tmp) / 'stage'
    @root.mkdir
    @framework = @root / 'MoneroWallet.framework'
    @version = @framework / 'Versions/A'
    FileUtils.mkdir_p(@version / 'Resources')
    (@version / 'MoneroWallet').write('binary')
    (@version / 'Resources/Info.plist').write('metadata')
    FileUtils.cp_r(@version, @framework / 'Versions/Current')
    FileUtils.cp(@version / 'MoneroWallet', @framework / 'MoneroWallet')
    FileUtils.cp_r(@version / 'Resources', @framework / 'Resources')
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def normalize
    StackFrameworkPackaging.normalize(@root, @framework)
  end

  def assert_unmodified_after_failure
    before = StackFrameworkPackaging.inventory(@framework)
    assert_raises(RuntimeError) { normalize }
    assert_equal before, StackFrameworkPackaging.inventory(@framework)
  end

  def test_identical_copies_become_links_and_repeated_runs_preserve_signed_content
    normalize
    assert_equal 'A', (@framework / 'Versions/Current').readlink.to_s
    assert_equal 'Versions/Current/MoneroWallet', (@framework / 'MoneroWallet').readlink.to_s
    assert_equal 'Versions/Current/Resources', (@framework / 'Resources').readlink.to_s
    FileUtils.mkdir_p(@version / '_CodeSignature')
    (@version / '_CodeSignature/CodeResources').write('signed resource seal')
    normalize
    assert_equal 'signed resource seal', (@framework / 'Versions/Current/_CodeSignature/CodeResources').read
  end

  def test_binary_mismatch_does_not_partially_repair_directories
    (@framework / 'MoneroWallet').write('different')
    assert_unmodified_after_failure
  end

  def test_resource_mismatch_does_not_partially_repair_any_entry
    (@framework / 'Resources/Info.plist').write('different')
    assert_unmodified_after_failure
  end

  def test_current_extra_signature_is_not_discarded
    (@framework / 'Versions/Current/extra-signature').write('stale')
    assert_unmodified_after_failure
  end

  def test_extra_top_level_entry_is_rejected
    (@framework / 'unexpected').write('extra')
    assert_unmodified_after_failure
  end

  def test_nested_symlink_is_rejected_before_mutation
    (@version / 'Resources/escape').make_symlink(@root)
    assert_raises(RuntimeError) { normalize }
    refute (@framework / 'Versions/Current').symlink?
  end

  def test_unexpected_main_symlink_is_rejected
    FileUtils.remove_entry(@framework / 'Resources')
    (@framework / 'Resources').make_symlink(@root)
    assert_raises(RuntimeError) { normalize }
    refute (@framework / 'Versions/Current').symlink?
  end

  def test_source_outside_staging_is_rejected
    other = Pathname.new(@tmp) / 'other'
    other.mkdir
    assert_raises(RuntimeError) { StackFrameworkPackaging.normalize(other, @framework) }
    refute (@framework / 'Versions/Current').symlink?
  end

  def test_unknown_framework_is_untouched
    other = @root / 'Other.framework'
    FileUtils.mv(@framework, other)
    before = StackFrameworkPackaging.inventory(other)
    StackFrameworkPackaging.normalize(@root, other)
    assert_equal before, StackFrameworkPackaging.inventory(other)
  end

  def test_embed_patch_is_idempotent_and_forces_synchronous_signing
    path = Pathname.new(@tmp) / 'embed.sh'
    path.write("#{StackFrameworkPackaging::PARALLEL}\ninstall_framework()\n{\n  rsync --delete -av source dest\n#{StackFrameworkPackaging::INSERTION}" +
               '  code_sign_if_enabled "${destination}/$(basename "$1")"' + "\n}\n")
    StackFrameworkPackaging.patch_embed_script(path)
    once = path.read
    StackFrameworkPackaging.patch_embed_script(path)
    assert_equal once, path.read
    assert_includes once, 'COCOAPODS_PARALLEL_CODE_SIGN=false'
    assert_operator once.index(' normalize '), :<, once.index('  local basename')
  end

  def test_actual_cocoapods_script_with_dsym_and_other_rsync_calls
    path = Pathname.new(@tmp) / 'embed.sh'
    fixture = Pathname.new(__dir__) / 'fixtures/cocoapods-frameworks.sh'
    path.write(fixture.read)
    StackFrameworkPackaging.patch_embed_script(path)
    once = path.read
    StackFrameworkPackaging.patch_embed_script(path)
    assert_equal once, path.read
    assert_equal 1, once.scan(' normalize ').length
    assert_includes once, 'codesign --force --sign ${EXPANDED_CODE_SIGN_IDENTITY}'
    assert_operator once.index(' normalize '), :<, once.index('    strip_invalid_archs "$binary"')
    assert_operator once.index(' normalize '), :>, once.index('  rsync --delete -av ')
    assert system('/bin/bash', '-n', path.to_s)
  end

  def test_altered_previous_patch_fails_without_editing
    path = Pathname.new(@tmp) / 'embed.sh'
    path.write((Pathname.new(__dir__) / 'fixtures/cocoapods-frameworks.sh').read)
    StackFrameworkPackaging.patch_embed_script(path)
    path.write(path.read.sub('COCOAPODS_PARALLEL_CODE_SIGN=false', 'COCOAPODS_PARALLEL_CODE_SIGN=true'))
    before = path.read
    assert_raises(RuntimeError) { StackFrameworkPackaging.patch_embed_script(path) }
    assert_equal before, path.read
  end

  def test_failed_signing_stops_script_and_preserves_identity_and_disabled_signing
    path = Pathname.new(@tmp) / 'embed.sh'
    path.write((Pathname.new(__dir__) / 'fixtures/cocoapods-frameworks.sh').read)
    StackFrameworkPackaging.patch_embed_script(path)
    signer = Pathname.new(@tmp) / 'fake-codesign'
    args = Pathname.new(@tmp) / 'signer-args'
    reached = Pathname.new(@tmp) / 'reached'
    signer.write("#!/bin/sh\nprintf '%s\\n' \"$@\" > #{Shellwords.escape(args.to_s)}\nexit 42\n")
    signer.chmod(0755)
    path.write(path.read.sub('/usr/bin/codesign', signer.to_s) +
               "\ncode_sign_if_enabled '#{@root}/Other.framework'\ntouch '#{reached}'\n")
    env = {
      'FRAMEWORKS_FOLDER_PATH' => 'Frameworks', 'CONFIGURATION_BUILD_DIR' => @tmp,
      'TOOLCHAIN_DIR' => @tmp, 'PLATFORM_NAME' => 'macosx', 'CONFIGURATION' => 'Test',
      'EXPANDED_CODE_SIGN_IDENTITY' => 'configured-identity',
      'EXPANDED_CODE_SIGN_IDENTITY_NAME' => 'Configured Identity',
      'CODE_SIGNING_REQUIRED' => 'YES', 'CODE_SIGNING_ALLOWED' => 'YES',
      'COCOAPODS_PARALLEL_CODE_SIGN' => 'true',
    }
    _out, _err, status = Open3.capture3(env, '/bin/bash', path.to_s)
    assert_equal 42, status.exitstatus
    refute reached.exist?
    assert_equal ['--force', '--sign', 'configured-identity', '--preserve-metadata=identifier,entitlements', "#{@root}/Other.framework"], args.read.lines.map(&:chomp)
    args.unlink
    [
      { 'CODE_SIGNING_ALLOWED' => 'NO' },
      { 'CODE_SIGNING_REQUIRED' => 'NO' },
      { 'EXPANDED_CODE_SIGN_IDENTITY' => '' },
    ].each do |disabled|
      _out, _err, status = Open3.capture3(env.merge(disabled), '/bin/bash', path.to_s)
      assert status.success?
      assert reached.exist?
      refute args.exist?
      reached.unlink
    end
  end

  def test_changed_embed_script_fails_without_editing
    path = Pathname.new(@tmp) / 'embed.sh'
    path.write("#{StackFrameworkPackaging::PARALLEL}\nunknown new copy routine\n")
    before = path.read
    assert_raises(RuntimeError) { StackFrameworkPackaging.patch_embed_script(path) }
    assert_equal before, path.read
  end
end
