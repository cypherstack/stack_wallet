;; Guix manifest for Stack Wallet reproducible builds.
;;
;; Declares all packages that must be present inside the guix shell container.
;; Flutter SDK and Rust toolchains are NOT Guix packages — they are hash-pinned
;; tarballs fetched by supplementary/deps/ scripts and mounted into the container.

(specifications->manifest
 (list
  ;; C/C++ toolchain
  "gcc-toolchain"
  "cmake"
  "pkg-config"
  "meson"
  "ninja"

  ;; System libraries required by Flutter Linux builds and plugins
  "gtk+"              ; GTK 3
  "glib"
  "glib:bin"          ; gdbus-codegen (needed by libsecret build)
  "openssl"
  "pango"
  "cairo"
  "gdk-pixbuf"
  "at-spi2-core"      ; successor to atk

  ;; Build tools
  "git-minimal"
  "python"
  "perl"               ; needed by openssl-sys Rust crate
  "coreutils"
  "findutils"
  "tar"
  "xz"
  "gzip"
  "sed"
  "grep"
  "gawk"
  "diffutils"
  "patch"
  "make"
  "which"
  "bash"
  "rsync"
  "util-linux"       ; for getopt

  ;; Clang/LLVM (needed by some Rust crates' build.rs)
  "clang-toolchain"

  ;; Go (needed by flutter_mwebd plugin for Litecoin MWEB)
  "go"

  ;; CA certificates (for Rust vendored-openssl verification)
  "nss-certs"

  ;; libsecret build deps
  "gobject-introspection"
  "vala"
  "libxslt"          ; for xsltproc
  "docbook-xsl"
  "libgcrypt"        ; required by libsecret

  ;; camera_linux plugin
  "opencv"

  ;; Additional libs pulled in at link time
  "eudev"            ; libudev
  ))
