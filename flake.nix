{
  description = "Stack Wallet Build Environment";

  inputs = {
    # Pinned to a specific nixpkgs rev for reproducible Flutter/Rust toolchain
    # versions. To bump it, edit the rev below and run `nix flake lock`
    # (`--update-input` cannot move a rev-pinned URL), then re-test
    # `make build-macos` and `make build-linux`.
    nixpkgs.url = "github:NixOS/nixpkgs/b1b875982b17dabde9b4a37f3e229e74913e6db3";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        # Single source of truth for the toolchain versions; the Homebrew
        # helper and the Makefile read the same file.
        bom = builtins.fromTOML (builtins.readFile ./stack-bom.toml);
        rustVersion = let
          v = bom.toolchain.rust or (throw "stack-bom.toml: missing [toolchain].rust");
        in
          if builtins.isString v && builtins.match "[0-9]+\\.[0-9]+\\.[0-9]+" v != null
          then v
          else throw "stack-bom.toml: [toolchain].rust must be a version string";
        dnssecRustVersion = let
          v = bom.toolchain.dnssec_rust or (throw "stack-bom.toml: missing [toolchain].dnssec_rust");
        in
          if builtins.isString v && builtins.match "[0-9]+\\.[0-9]+\\.[0-9]+" v != null
          then v
          else throw "stack-bom.toml: [toolchain].dnssec_rust must be a version string";
        clangMajor = lib.versions.major pkgs.llvmPackages.clang.version;

        commonPackages = with pkgs; [
          flutter
          go
          rustup
          git
          nix
          cmake
          meson
          ninja
          pkg-config
          gnumake
          rsync
          protobuf
          (python3.withPackages (ps: with ps; [
            pip toml tomli jinja2 markdown markupsafe pygments typogrify
          ]))
        ];

        linuxPackages = lib.optionals pkgs.stdenv.hostPlatform.isLinux (with pkgs; [
          gtk3 glib openssl xz libgcrypt gobject-introspection
          llvmPackages.libclang
          llvmPackages.clang
          opencv
          sysprof
          libsysprof-capture
          # 0.18 is the first patchelf with --clear-execstack, which
          # prepare_release_bundle.py requires.
          patchelfUnstable
          binutils
          tpm2-tss
          ocl-icd
          opencl-headers
        ]);

        macPackages = lib.optionals pkgs.stdenv.hostPlatform.isDarwin (with pkgs; [
          cocoapods
          libiconv
          autoconf
          automake
          libtool
        ]);

      in
      {
        checks.dev-shell = self.devShells.${system}.default;

        devShells.default = pkgs.mkShell {
          buildInputs = commonPackages ++ linuxPackages ++ macPackages;

          shellHook = ''
            echo "==================================================="
            echo "Stack Wallet Dev-Environment activated!"
            echo "Target System: ${system}"
            echo "==================================================="

            # Resolve the repository root, not the directory the shell was
            # entered from; .nix-bin and the rustup override are per checkout.
            APP_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
            if [ ! -f "$APP_ROOT/flake.nix" ]; then
              APP_ROOT="$PWD"
            fi
            export APP_PROJECT_ROOT_DIR="$APP_ROOT"
            if [ -d "$HOME/.cargo/bin" ]; then
              case ":$PATH:" in
                *":$HOME/.cargo/bin:"*) ;;
                *) export PATH="$PATH:$HOME/.cargo/bin" ;;
              esac
            fi

            # The standalone Dart in the Nix Flutter wrapper cannot find the Flutter SDK on its own,
            # so `dart run`/`dart pub` in a Flutter project fail ("Flutter users should use flutter pub").
            if command -v flutter >/dev/null 2>&1; then
              FLUTTER_BIN_DIR="$(cd "$(dirname "$(command -v flutter)")" && pwd -P)"
              export FLUTTER_ROOT="$(dirname "$FLUTTER_BIN_DIR")"
            else
              echo "[WARN] flutter not on PATH; FLUTTER_ROOT not set." >&2
            fi

            # ==========================================
             # RUST TOOLCHAIN AUTOMATION
             # Host Rust toolchain; native-assets crates select their own pinned toolchain.
             # ==========================================
             for v in ${rustVersion} ${dnssecRustVersion}; do
               if ! rustup toolchain list | grep -q "^$v"; then
                 echo "Initializing Rust $v (this happens only once)..."
                 rustup toolchain install --no-self-update "$v"
               fi
             done

             if [[ "${system}" == *"darwin"* ]]; then
               rustup target add aarch64-apple-darwin x86_64-apple-darwin aarch64-apple-ios aarch64-apple-ios-sim --toolchain ${rustVersion}
             fi

            # ==========================================
            # LINUX (NixOS) SPECIFICS
            # ==========================================
            ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
            # echo "🐧 Linux detected: Patching shebangs for NixOS..."
              # Flutter's Linux CMake build forces CC=clang/CXX=clang++. libclang
              # also puts the unwrapped clang first on PATH, which cannot find
              # the NixOS crt/libstdc++ paths; prefer the clang wrapper.
              # Unconditional: buildInputs always puts these somewhere on PATH,
              # so a membership test would never prepend them. Runs once per shell.
              export PATH="${pkgs.llvmPackages.clang}/bin:$PATH"
              # stdenv also provides patchelf 0.15; put 0.18 first.
              export PATH="${pkgs.patchelfUnstable}/bin:$PATH"
              export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib"
              export BINDGEN_EXTRA_CLANG_ARGS="-isystem ${pkgs.llvmPackages.libclang.lib}/lib/clang/${clangMajor}/include"
              export PROTOC="${pkgs.protobuf}/bin/protoc"
              export SYSPROF_PC_DIR="${pkgs.libsysprof-capture}/lib/pkgconfig"
            ''}

            # ==========================================
            # MACOS XCODE SANDBOX ESCAPE
            # ==========================================
            ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
              # Nix supplies the host tools, never Apple's compiler or SDK.
              # Flutter, CocoaPods and Xcode use the toolchain selected by
              # xcode-select. Do not export SDKROOT here: it makes an iOS build
              # compile against the macOS SDK.
              SELECTED_DEVELOPER="$(env -u DEVELOPER_DIR xcode-select -p 2>/dev/null || true)"
              case "$SELECTED_DEVELOPER" in
                *.app/Contents/Developer) ;;
                *)
                  echo "[WARN] No full Xcode selected. Install Xcode and run 'make bootstrap-xcode'."
                  ;;
              esac
              # nixpkgs' Darwin stdenv exports its vendored apple-sdk here
              # before this hook runs; clear it so xcrun and xcodebuild use the
              # live xcode-select. A per-command DEVELOPER_DIR=... still works.
              unset DEVELOPER_DIR
              # Leave the SDK choice to Xcode per build.
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

              SDK_PATH="$(/usr/bin/xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
              if [ -n "$SDK_PATH" ]; then
                if [ -n "$BINDGEN_EXTRA_CLANG_ARGS" ]; then
                  export BINDGEN_EXTRA_CLANG_ARGS="-isysroot $SDK_PATH $BINDGEN_EXTRA_CLANG_ARGS"
                else
                  export BINDGEN_EXTRA_CLANG_ARGS="-isysroot $SDK_PATH"
                fi
              fi
              export PROTOC="${pkgs.protobuf}/bin/protoc"

              # Stable, per-checkout wrapper directory instead of a fresh
              # mktemp dir on every entry. A random temp path is lost on the
              # next clean and forces the hooks to rebuild native libs; a
              # stable path under .dart_tool is recreated (never deleted) on
              # every shell entry, so a second `nix develop` reuses the same
              # wrappers and the native build cache stays valid.
              NIX_BIN="$APP_ROOT/.dart_tool/nix-bin"
              mkdir -p "$NIX_BIN"
              # Stable TMPDIR for the wrappers; keeps extracted build scratch
              # under the checkout so it is not orphaned in /tmp.
              export TMPDIR="$APP_ROOT/.dart_tool/tmp"
              mkdir -p "$TMPDIR"

              # Symlinks for the system compilers. Recreated every entry; the
              # directory itself is never removed.
              ln -sf /usr/bin/clang "$NIX_BIN/cc"
              ln -sf /usr/bin/clang++ "$NIX_BIN/c++"
              ln -sf /usr/bin/clang "$NIX_BIN/clang"
              ln -sf /usr/bin/clang++ "$NIX_BIN/clang++"

              # SMART LIPO & XCRUN WRAPPER
              # lipo wrapper: a build-tree copy of FlutterMacOS.framework may
              # need to be made writable. Never touch the Nix store path.
              rm -f "$NIX_BIN/lipo" "$NIX_BIN/xcrun"

              cat > "$NIX_BIN/lipo" <<'LIPO_EOF'
#!/bin/bash
for arg in "$@"; do
    if [[ "$arg" == *"FlutterMacOS.framework"* ]]; then
        framework="''${arg%%FlutterMacOS.framework*}FlutterMacOS.framework"
        case "$framework" in
          "$APP_ROOT"/*|"''${TMPDIR:-/tmp}"/*) chmod -R u+w "$framework" 2>/dev/null || true ;;
          *) ;;
        esac
    fi
done
exec /usr/bin/lipo "$@"
LIPO_EOF
              chmod +x "$NIX_BIN/lipo"

              # xcrun wrapper: `xcrun -f lipo` must resolve to the wrapper above.
              # Everything else passes straight through, so an iOS build keeps
              # its deployment target and SDK.
              cat > "$NIX_BIN/xcrun" <<XCRUN_EOF
#!/bin/bash
case "\$1" in
  -f|--find)
    if [ "\$2" = "lipo" ]; then
      echo "$NIX_BIN/lipo"
      exit 0
    fi
    ;;
  lipo)
    shift
    exec "$NIX_BIN/lipo" "\$@"
    ;;
esac
exec /usr/bin/xcrun "\$@"
XCRUN_EOF
              chmod +x "$NIX_BIN/xcrun"

              if [ -x "$NIX_BIN/lipo" ] && [ -x "$NIX_BIN/xcrun" ]; then
                case ":$PATH:" in
                  *":$NIX_BIN:"*) ;;
                  *) export PATH="$NIX_BIN:$PATH" ;;
                esac
              else
                echo "[WARN] Apple tool wrappers are incomplete; using the Nix tools." >&2
              fi
            ''}

          '';
        };
      }
    );
}
