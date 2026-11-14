{
  description = "Stack Wallet Build Environment";

  inputs = {
    # Pinned to a specific nixpkgs rev for reproducible Flutter/Rust toolchain
    # versions. Update via `nix flake lock --update-input nixpkgs` and re-test
    # `make build-macos` and `make build-linux` before bumping.
    nixpkgs.url = "github:NixOS/nixpkgs/b1b875982b17dabde9b4a37f3e229e74913e6db3";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        rustVersion = "1.99.1";

        commonPackages = with pkgs; [
          flutter
          dart
          go
          rustup
          cmake
          meson
          ninja
          pkg-config
          gnumake
          gnused
          rsync
          protobuf
          (python3.withPackages (ps: with ps; [
            pip toml tomli jinja2 markdown markupsafe pygments typogrify
          ]))
        ];

        linuxPackages = lib.optionals pkgs.stdenv.isLinux (with pkgs; [
          gtk3 glib openssl xz clang libgcrypt gobject-introspection
          llvmPackages.libclang
          llvmPackages.clang
          opencv
          sysprof
          libsysprof-capture
          patchelf
          binutils
        ]);

        macPackages = lib.optionals pkgs.stdenv.isDarwin (with pkgs; [
          cocoapods
          libiconv
          autoconf
          automake
          libtool
        ]);

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = commonPackages ++ linuxPackages ++ macPackages;

          shellHook = ''
            echo "==================================================="
            echo "Stack Wallet Dev-Environment activated!"
            echo "Target System: ${system}"
            echo "==================================================="

            export APP_PROJECT_ROOT_DIR=$(pwd)
            export PATH="$HOME/.cargo/bin:$PATH"

            # The standalone Dart in the Nix Flutter wrapper cannot find the Flutter SDK on its own,
            # so `dart run`/`dart pub` in a Flutter project fail ("Flutter users should use flutter pub").
            export FLUTTER_ROOT="$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")"

            # ==========================================
             # RUST TOOLCHAIN AUTOMATION
             # Host Rust toolchain; native-assets crates select their own pinned toolchain.
             # ==========================================
             if ! rustup toolchain list | grep -q "${rustVersion}"; then
               echo "Initializing Rust toolchain (this happens only once)..."
               rustup toolchain install --no-self-update ${rustVersion}
             fi

             # Pin this checkout without replacing the user's global rustup default.
             rustup override set ${rustVersion} --path "$PWD" >/dev/null 2>&1 || true

             if [[ "${system}" == *"darwin"* ]]; then
               rustup target add aarch64-apple-darwin aarch64-apple-ios --toolchain ${rustVersion}
             fi

            if ! command -v cargo-ndk >/dev/null 2>&1; then
              echo "Installing optional Android Cargo tooling..."
              cargo install cargo-ndk
            fi

            # ==========================================
            # LINUX (NixOS) SPECIFICS
            # ==========================================
            ${lib.optionalString pkgs.stdenv.isLinux ''
            # echo "🐧 Linux detected: Patching shebangs for NixOS..."
              export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib"
              export BINDGEN_EXTRA_CLANG_ARGS="-isystem ${pkgs.llvmPackages.libclang.lib}/lib/clang/${pkgs.llvmPackages.clang.version}/include"
              export PROTOC="${pkgs.protobuf}/bin/protoc"
            ''}

            # ==========================================
            # MACOS XCODE SANDBOX ESCAPE
            # ==========================================
            ${lib.optionalString pkgs.stdenv.isDarwin ''
              # Nix cannot provide Xcode itself (Apple's license forbids
              # redistributing it), so this only works once it's installed
              # separately -- run `make bootstrap-xcode` if this warns.
              if [ ! -d /Applications/Xcode.app ]; then
                echo "[WARN] /Applications/Xcode.app not found. Full Xcode (not just Command Line Tools) is required for macOS/iOS builds. Run: make bootstrap-xcode"
              fi
              # Respect whatever Xcode is actually active via `xcode-select`
              # instead of forcing the default install location -- hardcoding
              # this broke `sudo xcode-select --switch` to a differently
              # named/located Xcode (e.g. testing a second version side by
              # side), causing exactly the kind of toolchain/SDK mismatch
              # this whole escape hatch exists to prevent. `xcode-select -p`
              # itself just echoes back an already-set DEVELOPER_DIR (per its
              # man page), and nixpkgs' own Darwin stdenv sets one earlier in
              # this shellHook (to its vendored apple-sdk) -- so it must be
              # unset first to actually query the real system-wide selection.
              export DEVELOPER_DIR="$(env -u DEVELOPER_DIR xcode-select -p 2>/dev/null || echo /Applications/Xcode.app/Contents/Developer)"
              export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
              export MACOSX_DEPLOYMENT_TARGET="12.0"

              # --- NIX C++ COMPILER OVERRIDE ---
              export CC=/usr/bin/clang
              export CXX=/usr/bin/clang++
              unset LD
              export AR=/usr/bin/ar
              export AS=/usr/bin/as
              export NM=/usr/bin/nm
              export RANLIB=/usr/bin/ranlib
              export STRIP=/usr/bin/strip

              export BINDGEN_EXTRA_CLANG_ARGS="-isysroot $SDKROOT"
              export PROTOC="${pkgs.protobuf}/bin/protoc"

              mkdir -p .nix-bin
              ln -sf /usr/bin/clang .nix-bin/cc
              ln -sf /usr/bin/clang++ .nix-bin/c++
              ln -sf /usr/bin/xcodebuild .nix-bin/xcodebuild
              ln -sf /usr/bin/clang .nix-bin/clang
              ln -sf /usr/bin/clang++ .nix-bin/clang++

              # SMART LIPO & XCRUN WRAPPER
              # lipo wrapper: the Nix store copy of FlutterMacOS.framework is
              # read-only, so make its containing dir writable before handing
              # off to the real lipo.
              rm -f .nix-bin/lipo .nix-bin/xcrun

              cat > .nix-bin/lipo <<'LIPO_EOF'
#!/bin/bash
for arg in "$@"; do
    if [[ "$arg" == *"FlutterMacOS.framework"* ]]; then
        chmod -R u+w "$(dirname "$arg")" 2>/dev/null || true
    fi
done
exec /usr/bin/lipo "$@"
LIPO_EOF
              chmod +x .nix-bin/lipo

              # xcrun wrapper: `xcrun -f lipo` must resolve to the wrapper
              # above rather than the real /usr/bin/lipo. Everything else
              # passes through to the real xcrun, with deployment-target/SDK
              # env vars pinned to macOS so a leaked iOS/tvOS/etc value from
              # the outer environment doesn't leak in.
              cat > .nix-bin/xcrun <<'XCRUN_EOF'
#!/bin/bash
if [ "$1" = "-f" ] && [ "$2" = "lipo" ]; then
    echo "__NIX_BIN_DIR__/lipo"
    exit 0
fi

unset IPHONEOS_DEPLOYMENT_TARGET TVOS_DEPLOYMENT_TARGET WATCHOS_DEPLOYMENT_TARGET
unset XROS_DEPLOYMENT_TARGET XR_DEPLOYMENT_TARGET VISIONOS_DEPLOYMENT_TARGET DRIVERKIT_DEPLOYMENT_TARGET
export MACOSX_DEPLOYMENT_TARGET="''${MACOSX_DEPLOYMENT_TARGET:-12.0}"
export SDKROOT="''${SDKROOT:-$(/usr/bin/xcrun --sdk macosx --show-sdk-path)}"
exec /usr/bin/xcrun "$@"
XCRUN_EOF
              sed -i.bak "s|__NIX_BIN_DIR__|$PWD/.nix-bin|" .nix-bin/xcrun && rm -f .nix-bin/xcrun.bak
              chmod +x .nix-bin/xcrun

              export PATH="$PWD/.nix-bin:$PATH"
            ''}

          '';
        };
      }
    );
}
