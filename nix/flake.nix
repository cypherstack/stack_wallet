{
  description = "Reproducible Flutter dev environment using Nix.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-linux.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, nixpkgs-linux }:
    let
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      linuxSystems  = [ "x86_64-linux" "aarch64-linux" ];
      forAllDarwin  = nixpkgs.lib.genAttrs darwinSystems;
      forAllLinux   = nixpkgs-linux.lib.genAttrs linuxSystems;
    in {
      devShells =
        builtins.foldl' nixpkgs.lib.recursiveUpdate {} [

        # macOS/iOS shell -- Nix provides tooling, Xcode owns the compiler.
        (forAllDarwin (system:
          let pkgs = import nixpkgs { inherit system; };
          in {
            android = pkgs.mkShell {
              buildInputs = with pkgs; [ jdk17 git curl unzip rustup go ];
              shellHook = ''
                unset SDKROOT NIX_CC NIX_BINTOOLS NIX_CFLAGS_COMPILE NIX_LDFLAGS
                unset CC CXX LD AR NM RANLIB
                CLEAN_PATH=""
                IFS=':' read -ra PARTS <<< "$PATH"
                for p in "''${PARTS[@]}"; do
                  case "$p" in
                    *clang-wrapper*|*cctools-binutils*|*xcbuild*|*apple-sdk*) continue ;;
                    *) CLEAN_PATH="''${CLEAN_PATH:+$CLEAN_PATH:}$p" ;;
                  esac
                done
                export PATH="/usr/bin:$CLEAN_PATH"
                if [ -n "''${PROJECT_ROOT:-}" ] && [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
                  export PATH="$PROJECT_ROOT/.flutter-sdk/flutter/bin:$PATH"
                  export FLUTTER_ROOT="$PROJECT_ROOT/.flutter-sdk/flutter"
                fi
              '';
            };

            default = pkgs.mkShell {
              buildInputs = with pkgs; [
                ruby cocoapods git curl unzip cmake ninja pkg-config
                rustup go
              ];
              shellHook = ''
                unset SDKROOT NIX_CC NIX_BINTOOLS NIX_CFLAGS_COMPILE NIX_LDFLAGS
                unset CC CXX LD AR NM RANLIB
                CLEAN_PATH=""
                IFS=':' read -ra PARTS <<< "$PATH"
                for p in "''${PARTS[@]}"; do
                  case "$p" in
                    *clang-wrapper*|*cctools-binutils*|*xcbuild*|*apple-sdk*) continue ;;
                    *) CLEAN_PATH="''${CLEAN_PATH:+$CLEAN_PATH:}$p" ;;
                  esac
                done
                export PATH="/usr/bin:$CLEAN_PATH"
                if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
                  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
                fi
                if [ -n "''${PROJECT_ROOT:-}" ] && [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
                  export PATH="$PROJECT_ROOT/.flutter-sdk/flutter/bin:$PATH"
                  export FLUTTER_ROOT="$PROJECT_ROOT/.flutter-sdk/flutter"
                fi
              '';
            };
          }
        ))

        # Linux shells -- Nix owns the full toolchain.
        (forAllLinux (system:
          let pkgs = import nixpkgs-linux { inherit system; };
          in {
            android = pkgs.mkShell {
              buildInputs = with pkgs; [ jdk17 git curl unzip rustup go ];
              shellHook = ''
                if [ -n "''${PROJECT_ROOT:-}" ] && [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
                  export PATH="$PROJECT_ROOT/.flutter-sdk/flutter/bin:$PATH"
                  export FLUTTER_ROOT="$PROJECT_ROOT/.flutter-sdk/flutter"
                fi
              '';
            };

            linux = pkgs.mkShell {
              buildInputs = with pkgs; [
                clang cmake ninja pkg-config meson patchelf
                stdenv.cc.cc.lib
                libsecret jsoncpp opencv4 rustup go
                gtk3 glib fontconfig libepoxy pcre2 util-linux xz
                libx11 libxcursor libxrandr libxinerama
                libxi libxext libxfixes libxrender
                mesa libGL
                git curl unzip
              ];
              shellHook = ''
                if [ -n "''${PROJECT_ROOT:-}" ] && [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
                  export PATH="$PROJECT_ROOT/.flutter-sdk/flutter/bin:$PATH"
                  export FLUTTER_ROOT="$PROJECT_ROOT/.flutter-sdk/flutter"
                fi
              '';
            };

            # Native compilation runs through PowerShell on the Windows host.
            windows = pkgs.mkShell {
              buildInputs = with pkgs; [ bash coreutils git curl unzip ];
            };
          }
        ))
        ];
    };
}
