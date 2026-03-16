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
          gtk3 glib openssl xz clang
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
            # MACOS XCODE SANDBOX ESCAPE
            # ==========================================
            # Enables cargo-lipo to access the host's native Apple build tools
            ${lib.optionalString pkgs.stdenv.isDarwin ''
              export CPATH="$(xcrun --show-sdk-path)/usr/include:$CPATH"
              
              mkdir -p .nix-bin
              ln -sf /usr/bin/xcodebuild .nix-bin/xcodebuild
              ln -sf /usr/bin/xcrun .nix-bin/xcrun
              ln -sf /usr/bin/lipo .nix-bin/lipo
              export PATH="$PWD/.nix-bin:$PATH"
            ''}
          '';
        };
      }
    );
}
