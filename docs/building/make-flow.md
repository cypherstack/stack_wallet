# Make build flow

This page is the maintained source for the two build-flow diagrams. GitHub
renders the Mermaid blocks directly; PNGs can be generated locally from the
same blocks (they are not committed). Keep the source in sync with the
`Makefile`.

## 1. Get the tools (once per Mac)

Nix is the primary host toolchain. direnv is not a separate toolchain: the
tracked `.envrc` is `use flake`, so it activates the same shell as
`nix develop`. Homebrew and manually installed tools are supported fallbacks.

### History

`.envrc` was added on 2026-03-17 as a 98-line script that installed Rust
toolchains, set `SDKROOT`/`CC`, created a Python venv and wrote `lipo`/`xcrun`
wrappers. On 2026-03-19 the commit `macos build: split bootstrap from
host-agnostic build path` (428fd61f9) reduced it to `use flake`; the flake and
Makefile took over those steps. That is why direnv is not a fourth toolchain
today. The Homebrew helper still installs the `direnv` binary, but `.envrc`
now skips the flake when Nix is absent, so a Homebrew-only shell is not
blocked.

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
    X -- no --> XS["make bootstrap-xcode"]
    X -- no --> DL["make bootstrap-xcode-download<br/>optional; archive.org, hash + signature"]
    XS --> R
    DL --> R
```

`make bootstrap-xcode` does not install Xcode. It selects an existing full
install and finishes Apple's licence/first-launch setup if it is pending; the
archive.org download is opt-in and never runs in CI.

## 2. Build

`VERSION` and `BUILD_NUM` are required. dnix source is the default on macOS,
Linux and iOS; CI and Windows use the verified prebuilts.

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
    MP -- "0 default" --> MS["source<br/>Nix + Xcode 27.0"]
    MP -- "1" --> MB["prebuilt -d"]
    MS --> MR["build_app.sh -p macos -s<br/>pub get · prebuild.sh<br/>flutter build macos"]
    MB --> MR

    IOS --> IC["checks<br/>require-version · check-sdk-macos<br/>(macOS-only) · toolchain-check"]
    IC --> IP{"PREBUILTS"}
    IP -- "0 default" --> IS["source"]
    IP -- "1 CI" --> IB["prebuilt -d"]
    IS --> IR["prebuild.sh<br/>build_app.sh -p ios -s<br/>pub get · flutter build ios"]
    IB --> IR

    LINUX --> LC["checks<br/>require-version · check-linux<br/>toolchain-check · check-reqs"]
    LC --> LP{"PREBUILTS"}
    LP -- "0 default" --> LS["source (Nix)"]
    LP -- "1" --> LB["prebuilt -d"]
    LS --> LR["prebuild.sh<br/>build_app.sh -p linux<br/>flutter build linux · bundle"]
    LB --> LR

    WIN --> WC["checks<br/>require-version · check-windows<br/>toolchain-check · flutter · Go"]
    WC --> WR["prebuild.sh<br/>build_app.sh -p windows -d<br/>pub get · flutter build windows<br/>always prebuilt"]

    AND --> AC["checks<br/>require-version · toolchain-check<br/>dev key · SDK"]
    AC --> AH{"Host"}
    AH -- macOS --> AB["prebuilt -d"]
    AH -- Linux --> AP{"PREBUILTS"}
    AP -- "0 default" --> AS["source"]
    AP -- "1" --> AB
    AB --> AR["prebuild.sh<br/>build_app.sh -p android<br/>pub get · flutter build apk<br/>--split-per-abi"]
    AS --> AR
```

## Defaults

| Context | `PREBUILTS` | dnix mode |
|---|---|---|
| macOS developer | `0` | source, verified; needs Nix + Xcode 27.0 |
| Linux developer | `0` | source, verified; needs Nix |
| iOS developer | `0` | source, verified; needs Nix + Xcode 27.0 |
| macOS/Linux/iOS CI | `1` | verified prebuilts (`-d`) |
| Windows | `1` (fixed) | verified prebuilts (`-d`) |
| Android on macOS | `1` (fixed) | verified prebuilts (`-d`) |
| Android on Linux | follows `PREBUILTS` | source by default |

## Regenerating the PNGs

Extract the two Mermaid blocks and render them with Mermaid CLI:

```sh
npx --yes @mermaid-js/mermaid-cli -i make-flow-tools.mmd \
  -o make-flow-tools.png -t dark -b "#0d1117" --size 1800 -s 2
npx --yes @mermaid-js/mermaid-cli -i make-flow-build.mmd \
  -o make-flow-build.png -t dark -b "#0d1117" --size 1800 -s 2
```
