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
        # Single source of truth for the toolchain versions; the Homebrew
        # helper and the Makefile read the same file.
        bom = builtins.fromTOML (builtins.readFile ./stack-bom.toml);
        rustVersion = bom.toolchain.rust;
        clangMajor = lib.versions.major pkgs.llvmPackages.clang.version;

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
          tpm2-tss
          ocl-icd
          opencl-headers
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

            # Resolve the repository root, not the directory the shell was
            # entered from; .nix-bin and the rustup override are per checkout.
            export APP_PROJECT_ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
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
             rustup override set ${rustVersion} --path "$APP_PROJECT_ROOT_DIR" >/dev/null 2>&1 || true

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
              export BINDGEN_EXTRA_CLANG_ARGS="-isystem ${pkgs.llvmPackages.libclang.lib}/lib/clang/${clangMajor}/include"
              export PROTOC="${pkgs.protobuf}/bin/protoc"
            ''}

            # ==========================================
            # MACOS XCODE SANDBOX ESCAPE
            # ==========================================
            ${lib.optionalString pkgs.stdenv.isDarwin ''
              # Nix supplies the host tools, never Apple's compiler or SDK.
              # Flutter, CocoaPods and Xcode use the toolchain selected by
              # xcode-select. Do not export SDKROOT here: it makes an iOS build
              # compile against the macOS SDK.
              SELECTED_DEVELOPER="$(env -u DEVELOPER_DIR xcode-select -p 2>/dev/null || true)"
              case "$SELECTED_DEVELOPER" in
                *.app/Contents/Developer) ;;
                *)
                  echo "[WARN] No full Xcode selected. Install Xcode and run 'make bootstrap-xcode'."
                  SELECTED_DEVELOPER="/Applications/Xcode.app/Contents/Developer"
                  ;;
              esac
              export DEVELOPER_DIR="$SELECTED_DEVELOPER"
              # nixpkgs' Darwin stdenv exports its own macOS SDK here before
              # this hook runs; leave the SDK choice to Xcode per build.
              unset SDKROOT
              export MACOSX_DEPLOYMENT_TARGET="12.0"

              # Force Apple's tools even though the Nix shell puts its own
              # clang and binutils first on PATH.
              export CC=/usr/bin/clang
              export CXX=/usr/bin/clang++
              unset LD
              export AR=/usr/bin/ar
              export AS=/usr/bin/as
              export NM=/usr/bin/nm
              export RANLIB=/usr/bin/ranlib
              export STRIP=/usr/bin/strip

              export BINDGEN_EXTRA_CLANG_ARGS="-isysroot $(/usr/bin/xcrun --sdk macosx --show-sdk-path)"
              export PROTOC="${pkgs.protobuf}/bin/protoc"

              NIX_BIN="$APP_PROJECT_ROOT_DIR/.nix-bin"
              mkdir -p "$NIX_BIN"
              ln -sf /usr/bin/clang "$NIX_BIN/cc"
              ln -sf /usr/bin/clang++ "$NIX_BIN/c++"
              ln -sf /usr/bin/xcodebuild "$NIX_BIN/xcodebuild"
              ln -sf /usr/bin/clang "$NIX_BIN/clang"
              ln -sf /usr/bin/clang++ "$NIX_BIN/clang++"

              # SMART LIPO & XCRUN WRAPPER
              # lipo wrapper: the Nix store copy of FlutterMacOS.framework is
              # read-only, so make its containing dir writable before handing
              # off to the real lipo.
              rm -f "$NIX_BIN/lipo" "$NIX_BIN/xcrun"

              cat > "$NIX_BIN/lipo" <<'LIPO_EOF'
#!/bin/bash
for arg in "$@"; do
    if [[ "$arg" == *"FlutterMacOS.framework"* ]]; then
        chmod -R u+w "$(dirname "$arg")" 2>/dev/null || true
    fi
done
exec /usr/bin/lipo "$@"
LIPO_EOF
              chmod +x "$NIX_BIN/lipo"

              # xcrun wrapper: `xcrun -f lipo` must resolve to the wrapper above.
              # Everything else passes straight through, so an iOS build keeps
              # its deployment target and SDK.
              cat > "$NIX_BIN/xcrun" <<'XCRUN_EOF'
#!/bin/bash
if [ "$1" = "-f" ] && [ "$2" = "lipo" ]; then
    echo "__NIX_BIN_DIR__/lipo"
    exit 0
fi
exec /usr/bin/xcrun "$@"
XCRUN_EOF
              sed -i.bak "s|__NIX_BIN_DIR__|$NIX_BIN|" "$NIX_BIN/xcrun" && rm -f "$NIX_BIN/xcrun.bak"
              chmod +x "$NIX_BIN/xcrun"

              export PATH="$NIX_BIN:$PATH"
            ''}

          '';
        };
      }
    );
}
