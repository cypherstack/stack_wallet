# Repair flattened symlinks in the three legacy hosted frameworks, only after
# CocoaPods has copied them into the app. Never modify package/cache sources.
require 'digest'
require 'fileutils'
require 'pathname'
require 'shellwords'

module StackFrameworkPackaging
  NAMES = %w[MoneroWallet WowneroWallet SalviumWallet].freeze
  PARALLEL = 'COCOAPODS_PARALLEL_CODE_SIGN="${COCOAPODS_PARALLEL_CODE_SIGN:-false}"'.freeze
  INSERTION = "  local basename\n".freeze
  MARKER = '# Stack Wallet: validate staged legacy framework layout before stripping/signing.'.freeze

  def self.inventory(path)
    raise "Expected a real directory: #{path}" unless path.directory? && !path.symlink?
    entries = {}
    path.children.sort.each do |entry|
      raise "Unexpected symlink in flattened framework: #{entry}" if entry.symlink?
      if entry.directory?
        entries[entry.basename.to_s] = [:directory, inventory(entry)]
      elsif entry.file?
        entries[entry.basename.to_s] = [:file, entry.size, Digest::SHA256.file(entry).hexdigest]
      else
        raise "Unexpected filesystem entry: #{entry}"
      end
    end
    entries
  end

  def self.normalize(staging_root, framework)
    path = Pathname.new(framework).expand_path
    name = path.basename.to_s.delete_suffix('.framework')
    return unless NAMES.include?(name) && path.basename.to_s == "#{name}.framework"

    root = Pathname.new(staging_root).realpath
    unless !path.symlink? && path.directory? && path.parent.realpath == root
      raise "Framework must be a direct staged copy: #{path}"
    end
    unless path.children.map { |entry| entry.basename.to_s }.sort == [name, 'Resources', 'Versions'].sort
      raise "Unexpected top-level framework entries: #{path}"
    end
    versions = path / 'Versions'
    canonical = versions / 'A'
    raise "Unexpected Versions symlink: #{versions}" if versions.symlink?
    unless versions.children.map { |entry| entry.basename.to_s }.sort == %w[A Current]
      raise "Unexpected framework versions: #{versions}"
    end
    canonical_inventory = inventory(canonical)
    unless (canonical / name).file? && (canonical / 'Resources').directory?
      raise "Missing canonical framework binary/resources: #{path}"
    end
    links = {
      versions / 'Current' => ['A', canonical],
      path / name => ["Versions/Current/#{name}", canonical / name],
      path / 'Resources' => ['Versions/Current/Resources', canonical / 'Resources'],
    }
    # Validate every entry before any mutation, including partially repaired layouts.
    links.each do |entry, (target, original)|
      if entry.symlink?
        raise "Unexpected framework link: #{entry}" unless entry.readlink.to_s == target
      elsif original.directory?
        expected = original == canonical ? canonical_inventory : inventory(original)
        raise "Nonidentical framework directory: #{entry}" unless inventory(entry) == expected
      else
        unless entry.file? && FileUtils.compare_file(entry, original)
          raise "Nonidentical framework binary: #{entry}"
        end
      end
    end
    links.each do |entry, (target, _original)|
      next if entry.symlink?
      entry.directory? ? FileUtils.remove_entry(entry.to_s) : entry.unlink
      entry.make_symlink(target)
    end
  end

  def self.patch_embed_script(path)
    script = File.read(path)
    helper = File.expand_path(__FILE__)
    command = "  /usr/bin/ruby #{Shellwords.escape(helper)} normalize \"${destination}\" \"${destination}/$(basename \"$1\")\"\n"
    replacement = "  #{MARKER}\n#{command}#{INSERTION}"
    if script.include?(MARKER)
      unless script.scan(replacement).length == 1 && script.scan('COCOAPODS_PARALLEL_CODE_SIGN=false').length == 1 && !script.include?(PARALLEL)
        raise "Unexpected previously patched CocoaPods embed script: #{path}"
      end
      return
    end
    boundaries = /install_framework\(\)\n\{\n.*?\n\}\n/m
    sections = script.scan(boundaries)
    raise "Expected one install_framework function: #{path}" unless sections.length == 1
    section = sections.first
    copy = '  rsync --delete -av '

    sign = '  code_sign_if_enabled "${destination}/$(basename "$1")"'
    unless script.scan(PARALLEL).length == 1 && section.scan(INSERTION).length == 1 &&
           section.scan(copy).length == 1 && section.scan(sign).length == 1 &&
           section.index(copy) < section.index(INSERTION) && section.index(INSERTION) < section.index(sign)
      raise "CocoaPods embed script changed; review staged framework repair integration: #{path}"
    end
    script = script.sub(PARALLEL) { 'COCOAPODS_PARALLEL_CODE_SIGN=false' }
    script = script.sub(section) { section.sub(INSERTION) { replacement } }
    File.write(path, script)
  end
end

if $PROGRAM_NAME == __FILE__
  unless ARGV.length == 3 && ARGV[0] == 'normalize'
    abort 'Usage: normalize_frameworks.rb normalize STAGING_FRAMEWORKS_DIR FRAMEWORK'
  end
  StackFrameworkPackaging.normalize(ARGV[1], ARGV[2])
end
