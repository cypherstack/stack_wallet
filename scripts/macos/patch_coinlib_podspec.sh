#!/usr/bin/env bash
set -euo pipefail

PUB_CACHE_DIR="${PUB_CACHE:-$PWD/.pub-cache}"
COINLIB_SPEC=""

if [ -d "$PUB_CACHE_DIR/git" ]; then
  COINLIB_SPEC="$(find "$PUB_CACHE_DIR/git" -maxdepth 4 -type f -path '*/coinlib_flutter/darwin/coinlib_flutter.podspec' | head -n 1)"
fi

if [ -z "$COINLIB_SPEC" ]; then
  echo "[WARN] coinlib_flutter.podspec not found under PUB_CACHE=$PUB_CACHE_DIR; skipping patch"
  exit 0
fi

if grep -q "STACK_WALLET_COINLIB_PATCH" "$COINLIB_SPEC"; then
  echo "[OK] coinlib podspec already patched: $COINLIB_SPEC"
  exit 0
fi

TMP_FILE="$(mktemp)"
cat > "$TMP_FILE" <<'RUBY'
# STACK_WALLET_COINLIB_PATCH: make secp setup idempotent for reproducible pod install.
require 'fileutils'
secp_dir = File.expand_path('build/secp256k1', __dir__)
unless Dir.exist?(secp_dir)
  FileUtils.mkdir_p(File.dirname(secp_dir))
  system('git', 'clone', 'https://github.com/bitcoin-core/secp256k1', secp_dir) or raise 'coinlib: failed to clone secp256k1'
end
Dir.chdir(secp_dir) do
  system('git', 'checkout', 'e3a885d42a7800c1ccebad94ad1e2b82c4df5c65') or raise 'coinlib: failed to checkout pinned secp256k1 commit'
end

Pod::Spec.new do |s|
  s.name             = 'coinlib_flutter'
  s.module_name      = 'secp256k1'
  s.version          = '0.5.0'
  s.summary          = 'Cryptographic primitives from the secp256k1 library'
  s.description      = <<-DESC
The secp256k1 library bundled into the flutter plugin via cocoapods.
                       DESC
  s.homepage         = 'http://peercoin.net'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Peercoin Developers'

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/*.c'
  s.compiler_flags = '-Wno-unused-function', '-Wno-shorten-64-to-32'

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.14'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

end
RUBY

cp "$TMP_FILE" "$COINLIB_SPEC"
rm -f "$TMP_FILE"

echo "[OK] patched coinlib podspec: $COINLIB_SPEC"
