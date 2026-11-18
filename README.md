[![codecov](https://codecov.io/gh/cypherstack/stack_wallet/branch/main/graph/badge.svg?token=PM1N56UTEW)](https://codecov.io/gh/cypherstack/stack_wallet)

# Stack Wallet
Stack Wallet is a fully open source cryptocurrency wallet. With an easy to use user interface and quick and speedy transactions, this wallet is ideal for anyone no matter how much they know about the cryptocurrency space. The app is actively maintained to provide new user friendly features.

<a href="https://play.google.com/store/apps/details?id=com.cypherstack.stackwallet">
<img width="250px" src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png"></img>
</a>

## Feature List

Highlights include:
- 23 Different cryptocurrencies:
    - [Bitcoin](https://bitcoin.org/en/)
    - Bitcoin Frost
    - [Bitcoin Cash](https://bch.info/en/)
    - [Banano](https://banano.cc/)
    - [Cardano](https://cardano.org/)
    - [Dash](https://www.dash.org/)
    - [Dogecoin](https://dogecoin.com/)
    - [Epic Cash](https://linktr.ee/epiccash)
    - [MimbleWimbleCoin](https://mwc.mw)
    - [Ethereum](https://ethereum.org/en/)
    - [Ecash](https://e.cash/)
    - [Fact0rn](https://www.fact0rn.io/)
    - [Firo](https://firo.org/)
    - [Litecoin](https://litecoin.org/)
    - [Monero](https://www.getmonero.org/)
    - [Nano](https://nano.org/)
    - [Namecoin](https://www.namecoin.org/)
    - [Particl](https://particl.io/)
    - [Peercoin](https://www.peercoin.net/)
    - [Salvium](https://salvium.io/)
    - [Solana](https://solana.com/)
    - [Stellar](https://stellar.org/)
    - [Tezos](https://tezos.com/)
    - [Wownero](https://wownero.org/)
    - [Xelis](https://xelis.org/)
- All private keys and seeds stay on device and are never shared.
- Easy backup and restore feature to save all the information that's important to you.
- Trading cryptocurrencies through our partners.
- Custom address book
- Favorite wallets with fast syncing
- Custom Nodes.
- Open source software.
- No ads.

## Building

You can look at the [build instructions](docs/building.md) for more details.
On Apple Silicon macOS, the **Nix dev shell** is the primary *host* toolchain;
Homebrew and manual installs are supported fallbacks. dnix builds the four native
libraries from source under Nix/direnv and verifies the prebuilts otherwise.
`make build-macos` is the same target in every mode, and `make toolchain`
shows which host environment your shell is using.

### macOS with Nix (recommended; Apple Silicon)

1. Enter the flake environment:
   - `make bootstrap` (runs `nix develop`), or
   - `nix develop` directly, or
   - `direnv allow` once, if you use direnv with the included `.envrc`.
2. Check the Xcode requirement. Source builds are the default in Nix/direnv
   on Apple Silicon and need Xcode **27.0** (build 27A266a); if Xcode 27.0
   is not installed, pass `PREBUILTS=1`. `make bootstrap-xcode` selects an
   installed full Xcode and `make verify-bom` checks the host.
3. Run build (pass the release version and a build number; `make` refuses to
   guess):
   - `make build-macos VERSION=x.y.z BUILD_NUM=nnn`
   - Add `CONFIRM=1` for a non-interactive run.

The flake provides Flutter, Dart, rustup (which installs the BOM Rust version
on first entry), Go, CMake, Meson, Ninja, pkg-config and protoc. Xcode is never provided
by Nix; the flake uses the Xcode selected by `xcode-select`.

### macOS with Homebrew (fallback)

Use this only when you are not building through Nix/flake.

1. With Homebrew installed, install the host tools:
   - `make bootstrap-macos` (alias: `make bootstrap-brew`)
2. Run build:
   - Open a new terminal (or run `source ~/.zshrc`) so the Homebrew and
     Flutter PATH entries are active.
   - `make build-macos VERSION=x.y.z BUILD_NUM=nnn PREBUILTS=1`
   - Add `CONFIRM=1` for a non-interactive run.

`PREBUILTS=1` is required with Homebrew/manual: those toolchains cannot build
the four dnix libraries from source. It uses the verified prebuilts and needs
no Nix for them.

The Homebrew bootstrap installs the native build tools and configures the BOM
Rust version for Flutter's native-assets hooks. It replaces the former local
manual macOS native prebuild path; no submodule setup or manual native
plugin build is needed.

### macOS with a manual toolchain (advanced)

Install the prerequisites from [Building on macOS](docs/building/macos.md)
yourself, then run
`make build-macos VERSION=x.y.z BUILD_NUM=nnn PREBUILTS=1`.
Manual builds are prebuilt-only; source mode requires Nix/direnv.
`make check-reqs-macos` reports what is missing (`make check-sdk-macos` checks
full Xcode); `TOOLCHAIN=manual` makes the choice explicit. Use the
Nix/direnv toolchain for a source build; manual and Homebrew builds are
prebuilt-only.
