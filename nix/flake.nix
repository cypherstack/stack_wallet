{
  description = "Stack Wallet build shells for nix_dart.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-linux.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, nixpkgs-linux }:
    let
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllDarwin = nixpkgs.lib.genAttrs darwinSystems;
      forAllLinux = nixpkgs-linux.lib.genAttrs linuxSystems;

      # Puts the SDK fetched by `nix_dart setup` first on PATH.
      flutterSdkHook = ''
        if [ -n "''${PROJECT_ROOT:-}" ] && [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
          export PATH="$PROJECT_ROOT/.flutter-sdk/flutter/bin:$PATH"
          export FLUTTER_ROOT="$PROJECT_ROOT/.flutter-sdk/flutter"
        fi
      '';

      # Xcode owns the compiler on macOS. Drop the Nix compiler wrappers and
      # their environment so Xcode and the native-asset hooks use Apple's.
      darwinHook = ''
        unset SDKROOT NIX_CC NIX_BINTOOLS
        unset NIX_CFLAGS_COMPILE NIX_LDFLAGS
        unset NIX_ENFORCE_NO_NATIVE NIX_HARDENING_ENABLE
        unset NIX_DONT_SET_RPATH NIX_DONT_SET_RPATH_FOR_BUILD
        unset NIX_NO_SELF_RPATH NIX_IGNORE_LD_THROUGH_GCC
        unset NIX_BINTOOLS_WRAPPER_TARGET_HOST_aarch64_apple_darwin
        unset NIX_CC_WRAPPER_TARGET_HOST_aarch64_apple_darwin
        unset NIX_PKG_CONFIG_WRAPPER_TARGET_TARGET_aarch64_apple_darwin
        unset NIX_BINTOOLS_WRAPPER_TARGET_HOST_x86_64_apple_darwin
        unset NIX_CC_WRAPPER_TARGET_HOST_x86_64_apple_darwin
        unset NIX_PKG_CONFIG_WRAPPER_TARGET_TARGET_x86_64_apple_darwin
        unset MACOSX_DEPLOYMENT_TARGET NIX_APPLE_SDK_VERSION
        unset CC CXX LD AR NM RANLIB OBJCOPY OBJDUMP AS STRIP SIZE
        unset CMAKE_INCLUDE_PATH CMAKE_LIBRARY_PATH
        unset NIXPKGS_CMAKE_PREFIX_PATH CONFIG_SHELL
        unset LD_DYLD_PATH HOST_PATH
        CLEAN_PATH=""
        IFS=':' read -ra PARTS <<< "$PATH"
        for p in "''${PARTS[@]}"; do
          case "$p" in
            *clang-wrapper*|*clang-[0-9]*|*cctools-binutils*|*xcbuild*|*apple-sdk*|*compiler-rt*|*libcxx*|*pkg-config-wrapper*) continue ;;
            *) CLEAN_PATH="''${CLEAN_PATH:+$CLEAN_PATH:}$p" ;;
          esac
        done
        export PATH="$CLEAN_PATH:/usr/bin"
      '';

      # Toolchains for the native-asset hooks. Crates select their Rust
      # toolchain through rust-toolchain.toml, so rustup is provided rather
      # than a fixed rustc.
      nativeTools = pkgs: with pkgs; [ rustup go protobuf git curl unzip ];
    in {
      devShells = builtins.foldl' nixpkgs.lib.recursiveUpdate { } [

        (forAllDarwin (system:
          let pkgs = import nixpkgs { inherit system; };
          in {
            default = pkgs.mkShellNoCC {
              buildInputs = (nativeTools pkgs) ++ (with pkgs; [
                ruby cocoapods cmake ninja meson pkg-config
                autoconf automake libtool
              ]);
              PROTOC = "${pkgs.protobuf}/bin/protoc";
              shellHook = darwinHook + ''
                if [ -z "''${DEVELOPER_DIR:-}" ] && [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
                  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
                fi
              '' + flutterSdkHook;
            };

            android = pkgs.mkShellNoCC {
              buildInputs = (nativeTools pkgs) ++ [ pkgs.jdk21 ];
              PROTOC = "${pkgs.protobuf}/bin/protoc";
              shellHook = darwinHook + flutterSdkHook;
            };
          }))

        (forAllLinux (system:
          let
            pkgs = import nixpkgs-linux { inherit system; };
            # nixpkgs removes distro detection from GNUInstallDirs, so it
            # installs to lib64 on every 64-bit Linux. coinlib_flutter's
            # secp256k1 build expects lib.
            cmake = pkgs.cmake.overrideAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                substituteInPlace Modules/GNUInstallDirs.cmake \
                  --replace-fail 'set(''${out_var} "lib64")' 'set(''${out_var} "lib")'
              '';
            });
          in {
            android = pkgs.mkShell {
              buildInputs = (nativeTools pkgs) ++ [ pkgs.jdk21 ];
              PROTOC = "${pkgs.protobuf}/bin/protoc";
              shellHook = flutterSdkHook;
            };

            linux = pkgs.mkShell {
              buildInputs = (nativeTools pkgs) ++ [ cmake ] ++ (with pkgs; [
                clang ninja meson pkg-config perl python3
                gtk3 glib pcre2 util-linux xz
                # glib lists it in Requires.private.
                libsysprof-capture
                libx11 libxcursor libxrandr libxinerama
                libxi libxext libxfixes libxrender
                mesa libglvnd
                # flutter_secure_storage, linked as system libraries.
                libsecret jsoncpp
              ]);
              USE_SYSTEM_SECURE_STORAGE_DEPS = "1";
              PROTOC = "${pkgs.protobuf}/bin/protoc";
              LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
              # Keep the checkout path out of every RUNPATH.
              NIX_NO_SELF_RPATH = "1";
              # libflutter_linux_gtk.so has RUNPATH $ORIGIN, so ld would take
              # libepoxy and libfontconfig from the host and the loader would
              # not find them at run time. Linking them into the runner with
              # store RUNPATHs loads them first.
              NIX_LDFLAGS = "-rpath-link ${pkgs.lib.makeLibraryPath [ pkgs.libepoxy pkgs.fontconfig ]}"
                + " -L${pkgs.lib.getLib pkgs.libepoxy}/lib -rpath ${pkgs.lib.getLib pkgs.libepoxy}/lib"
                + " -L${pkgs.lib.getLib pkgs.fontconfig}/lib -rpath ${pkgs.lib.getLib pkgs.fontconfig}/lib"
                + " --push-state --no-as-needed -lepoxy -lfontconfig --pop-state";
              # prepare_release_bundle.py needs --clear-execstack, which the
              # stdenv patchelf (0.15) lacks.
              shellHook = ''
                export PATH="${pkgs.patchelfUnstable}/bin:$PATH"
              '' + flutterSdkHook;
            };
          }))
      ];
    };
}
