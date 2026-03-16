{
  description = "Stack Wallet Build Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
          (python3.withPackages (ps: with ps; [ 
            pip toml tomli jinja2 markdown markupsafe pygments typogrify 
          ]))
        ];

        linuxPackages = lib.optionals pkgs.stdenv.isLinux (with pkgs; [
          gtk3 glib openssl xz clang libgcrypt gobject-introspection
          llvmPackages.libclang
          llvmPackages.clang
          protobuf
        ]);

        macPackages = lib.optionals pkgs.stdenv.isDarwin (with pkgs; [
          cocoapods 
          libiconv 
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
            if ! rustup toolchain list | grep -q "1.89.0"; then
              echo "Initializing Rust toolchains (this happens only once)..."
              rustup install 1.89.0 1.85.1 1.81.0
              rustup default 1.89.0
              
              if [[ "${system}" == *"darwin"* ]]; then
                rustup target add aarch64-apple-darwin aarch64-apple-ios
              fi
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
              
              #unset CPATH
              #export CPATH="$SDKROOT/usr/include"
              #export LIBRARY_PATH="$SDKROOT/usr/lib"
              #export CXXFLAGS="-isysroot $SDKROOT -I$SDKROOT/usr/include/c++/v1"
              #export CFLAGS="-isysroot $SDKROOT"
              #export LDFLAGS="-isysroot $SDKROOT"
              export BINDGEN_EXTRA_CLANG_ARGS="-isysroot $SDKROOT"
              
              mkdir -p .nix-bin
              ln -sf /usr/bin/xcodebuild .nix-bin/xcodebuild
              ln -sf /usr/bin/xcrun .nix-bin/xcrun
              ln -sf /usr/bin/lipo .nix-bin/lipo
              ln -sf /usr/bin/clang .nix-bin/clang
              ln -sf /usr/bin/clang++ .nix-bin/clang++
                                                            
              export PATH="$PWD/.nix-bin:$PATH"
            ''}
          '';
        };
      }
    );
}
