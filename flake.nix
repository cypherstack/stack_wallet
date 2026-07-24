{
  description = "Stack Wallet Build Environment";

  inputs = {
    # Pinned to a specific nixpkgs rev for reproducible Flutter/Rust toolchain
    # versions. Update via `nix flake lock --update-input nixpkgs` and re-test
    # `make build-macos` and `make build-linux` before bumping.
    nixpkgs.url = "github:NixOS/nixpkgs/5b2c2d84341b2afb5647081c1386a80d7a8d8605";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;

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
            
            # ==========================================
            # RUST TOOLCHAIN AUTOMATION
            # ==========================================
            if ! rustup toolchain list | grep -q "stable" || ! rustup toolchain list | grep -q "1.85.1"; then
              echo "Initializing Rust toolchains (this happens only once)..."
              rustup toolchain install --no-self-update stable 1.85.1
            fi

            rustup default stable
            
            if [[ "${system}" == *"darwin"* ]]; then
              rustup target add aarch64-apple-darwin aarch64-apple-ios --toolchain stable
              rustup target add aarch64-apple-darwin --toolchain 1.85.1
            fi

            if ! command -v cbindgen >/dev/null 2>&1 || ! command -v cargo-lipo >/dev/null 2>&1; then
              echo "Installing required Cargo tools..."
              cargo install cargo-ndk cbindgen cargo-lipo
            fi

            # ==========================================
            # LINUX (NixOS) SPECIFICS
            # ==========================================
            ${lib.optionalString pkgs.stdenv.isLinux ''
            # echo "🐧 Linux detected: Patching shebangs for NixOS..."
            # patchShebangs scripts/ crypto_plugins/ > /dev/null 2>&1 || true
              export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib"
              export BINDGEN_EXTRA_CLANG_ARGS="-isystem ${pkgs.llvmPackages.libclang.lib}/lib/clang/${pkgs.llvmPackages.clang.version}/include"
              export PROTOC="${pkgs.protobuf}/bin/protoc"
            ''}

            # ==========================================
            # MACOS XCODE SANDBOX ESCAPE
            # ==========================================
            ${lib.optionalString pkgs.stdenv.isDarwin ''
              export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
              export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
              export MACOSX_DEPLOYMENT_TARGET="11.0"
              
              # --- NIX C++ COMPILER OVERRIDE ---
              export CC=/usr/bin/clang
              export CXX=/usr/bin/clang++
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
              rm -f .nix-bin/lipo .nix-bin/xcrun
              
              echo '#!/bin/bash' > .nix-bin/lipo
              echo 'for arg in "$@"; do' >> .nix-bin/lipo
              echo '    if [[ "$arg" == *"FlutterMacOS.framework"* ]]; then' >> .nix-bin/lipo
              echo '        chmod -R u+w "$(dirname "$arg")" 2>/dev/null || true' >> .nix-bin/lipo
              echo '    fi' >> .nix-bin/lipo
              echo 'done' >> .nix-bin/lipo
              echo 'exec /usr/bin/lipo "$@"' >> .nix-bin/lipo
              chmod +x .nix-bin/lipo 

              echo '#!/bin/bash' > .nix-bin/xcrun
              echo 'if [ "$1" = "-f" ] && [ "$2" = "lipo" ]; then' >> .nix-bin/xcrun
              echo '    echo "'$PWD'/.nix-bin/lipo"' >> .nix-bin/xcrun
              echo '    exit 0' >> .nix-bin/xcrun
              echo 'fi' >> .nix-bin/xcrun
              echo "" >> .nix-bin/xcrun
              echo '# Keep xcrun tool invocations pinned to macOS deployment context.' >> .nix-bin/xcrun
              echo 'unset IPHONEOS_DEPLOYMENT_TARGET TVOS_DEPLOYMENT_TARGET WATCHOS_DEPLOYMENT_TARGET' >> .nix-bin/xcrun
              echo 'unset XROS_DEPLOYMENT_TARGET XR_DEPLOYMENT_TARGET VISIONOS_DEPLOYMENT_TARGET DRIVERKIT_DEPLOYMENT_TARGET' >> .nix-bin/xcrun
              echo 'export MACOSX_DEPLOYMENT_TARGET="''${MACOSX_DEPLOYMENT_TARGET:-11.0}"' >> .nix-bin/xcrun
              echo 'export SDKROOT="''${SDKROOT:-$(/usr/bin/xcrun --sdk macosx --show-sdk-path)}"' >> .nix-bin/xcrun
              echo 'exec /usr/bin/xcrun "$@"' >> .nix-bin/xcrun
              chmod +x .nix-bin/xcrun
                                                              
              export PATH="$PWD/.nix-bin:$PATH"
            ''}

          '';
        };
      }
    );
}
