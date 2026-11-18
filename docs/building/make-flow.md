# Make build flow

This page is the maintained source for the two build-flow diagrams. GitHub
renders the Mermaid blocks directly; keep the source in sync with the
`Makefile`.

## 1. Get the tools (once per Mac)

Nix is the primary host toolchain. direnv is not a separate toolchain: the
tracked `.envrc` is `use flake`, so it activates the same shell as
`nix develop`. Homebrew and manually installed tools are supported fallbacks.

### History

`.envrc` started as a standalone environment script; it was reduced to
`use flake` when the flake and Makefile took over the host setup. That is why
direnv is the Nix activator, not a fourth toolchain. The Homebrew helper still
installs the `direnv` binary, but `.envrc` skips the flake when Nix is absent,
so a Homebrew-only shell is not blocked.

```mermaid
flowchart LR
    S["Pick a host<br/>toolchain"]
    S --> N["Nix (primary)<br/>make bootstrap"]
    S --> D["direnv<br/>direnv allow"]
    S --> B["Homebrew fallback<br/>make bootstrap-macos"]
    S --> M["Manual<br/>TOOLCHAIN=manual"]

    N --> F["Flake<br/>Flutter · Rust · Go<br/>CMake · Meson · Ninja"]
    D --> F
    B --> H["Homebrew helper<br/>Flutter · Rust · Go"]
    M --> P["Tools on PATH"]

    F --> C["make toolchain-check<br/>check-reqs-macos"]
    H --> C
    P --> C

    C --> X{"Full Xcode?"}
    X -- yes --> R["Ready to build"]
    X -- no --> INSTALL["Install full Xcode<br/>dart tool/setup_xcode.dart"]
    INSTALL --> XS["make bootstrap-xcode"]
    XS --> R
```

`make bootstrap-xcode` does not install Xcode. It selects an existing full
install; when it changes the selection it accepts the licence and runs pending
first-launch setup. An already-selected Xcode is left untouched. Use
`dart tool/setup_xcode.dart` or Apple's download page to install one.

## 2. Build

`VERSION` and `BUILD_NUM` are required. dnix source is the default on Apple
Silicon macOS and inside Nix/direnv on Linux; Intel macOS, non-Nix Linux, CI and
Windows use the verified prebuilts.

```mermaid
flowchart TD
    O["APP_NAME · VERSION · BUILD_NUM<br/>PREBUILTS=0 source · 1 prebuilt"]
    O --> MAC["make build-macos"]
    O --> IOS["make build-ios"]
    O --> LINUX["make build-linux"]
    O --> WIN["make build-windows"]
    O --> AND["make build-android"]

    MAC --> MC["checks<br/>require-version · check-sdk-macos<br/>toolchain-check · check-reqs-macos"]
    MC --> MP{"PREBUILTS"}
    MP -- "0 Apple Silicon" --> MS["source<br/>Nix + Xcode 27.0"]
    MP -- "1 Intel/CI" --> MB["prebuilt -d"]
    MS --> MR["build_app.sh -p macos<br/>pub get · prebuild.sh<br/>flutter build macos"]
    MB --> MR

    IOS --> IC["checks<br/>require-version · toolchain-check<br/>check-reqs-macos · check-sdk-macos"]
    IC --> IP{"PREBUILTS"}
    IP -- "0 Apple Silicon" --> IS["source"]
    IP -- "1 Intel/CI" --> IB["prebuilt -d"]
    IS --> IR["prebuild.sh<br/>build_app.sh -p ios<br/>pub get · flutter build ios"]
    IB --> IR

    LINUX --> LC["checks<br/>require-version · check-linux<br/>toolchain-check · check-reqs"]
    LC --> LP{"PREBUILTS"}
    LP -- "0 Nix/direnv" --> LS["source (Nix)"]
    LP -- "1 host" --> LB["prebuilt -d"]
    LS --> LR["prebuild.sh<br/>build_app.sh -p linux<br/>flutter build linux · bundle"]
    LB --> LR

    WIN --> WC["checks<br/>require-version · check-windows<br/>toolchain-check · flutter"]
    WC --> WR["prebuild.sh<br/>build_app.sh -p windows -d<br/>pub get · flutter build windows<br/>always prebuilt"]

    AND --> AC["checks<br/>require-version · toolchain-check<br/>android/key.properties · SDK"]
    AC --> AH{"Host"}
    AH -- macOS --> AB["prebuilt -d"]
    AH -- "Linux arm64" --> AB
    AH -- "Linux x86_64" --> AP{"PREBUILTS"}
    AP -- "0 Nix" --> AS["source"]
    AP -- "1 host" --> AB
    AB --> AR["prebuild.sh<br/>build_app.sh -p android<br/>pub get · flutter build apk<br/>--split-per-abi"]
    AS --> AR
```

## Defaults

| Context | `PREBUILTS` | dnix mode |
|---|---|---|
| macOS developer, Apple Silicon | `0` | source, verified; needs Nix + Xcode 27.0 |
| macOS developer, Intel | `1` | verified prebuilts (`-d`) |
| Linux developer in Nix/direnv | `0` | source, verified; needs Nix |
| Linux developer, non-Nix host | `1` | verified prebuilts (`-d`) |
| iOS developer, Apple Silicon | `0` | source, verified; needs Nix + Xcode 27.0 |
| iOS developer, Intel | `1` | verified prebuilts (`-d`) |
| macOS/Linux/iOS CI | `1` | verified prebuilts (`-d`) |
| Windows | `1` (fixed) | verified prebuilts (`-d`) |
| Android on macOS | `1` (default; source builds need an x86_64 Linux host) | verified prebuilts (`-d`) |
| Android on x86_64 Linux in Nix/direnv | follows `PREBUILTS` | source by default |
| Android on non-x86_64 Linux | `1` (default; source builds need x86_64) | verified prebuilts (`-d`) |
