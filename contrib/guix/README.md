# Guix Reproducible Builds for Stack Wallet
Build infrastructure for producing reproducible (deterministic) Linux x86_64 builds of Stack Wallet inside a Guix container.

Based on Bitcoin Core's approach (`contrib/guix/`).

## Prerequisites
- [GNU Guix](https://guix.gnu.org/) installed (via the shell installer or distro package)
- GPG key (for signing attestations)
- ~20 GB disk space for dependency caches

## Quick Start
```bash
# 1. Fetch all dependencies (requires network)
supplementary/deps/fetch-pub-deps.sh
supplementary/deps/fetch-cargo-deps.sh

# 2. Verify dependency hashes
supplementary/deps/verify-deps.sh

# 3. Build (network-isolated, deterministic: reproducible)
./guix-build

# 4. Sign the build output
./guix-attest

# 5. (Other builders) Verify attestations match
./guix-verify
```

## Build Variants
Set `APP_NAME_ID` to select the variant:
| Variant        | `APP_NAME_ID`  | Rust Plugins                   |
|----------------|----------------|--------------------------------|
| Stack Wallet   | `stack_wallet` | epiccash, mwc, frostdart       |
| Stack Duo      | `stack_duo`    | frostdart                      |
| Campfire        | `campfire`     | (none)                         |

## Environment Variables
| Variable            | Default           | Description                         |
|---------------------|-------------------|-------------------------------------|
| `APP_NAME_ID`       | `stack_wallet`    | Build variant                       |
| `APP_VERSION`       | from pubspec.yaml | Version string (e.g. `2.3.4`)      |
| `APP_BUILD_NUMBER`  | from pubspec.yaml | Build number (e.g. `234`)           |
| `JOBS`              | `$(nproc)`        | Parallel job count                  |
| `HOSTS`             | `x86_64-linux-gnu`| Target triplet(s)                   |
| `SOURCE_DATE_EPOCH` | from git log      | Timestamp for determinism           |
| `BASE_CACHE`        | `depends`         | Path to pre-fetched dependency dir  |

## Known Limitations
- Flutter SDK is a hash-pinned binary input, not built from source.
- Pre-built native `.so` libs (Monero, Wownero, Salvium, Tor, etc.) ship in pub
  packages and are accepted as-is with hash verification.
  A future phase will see these dependencies also built via the same method.
- Linux x86_64 only (no cross-compilation).
- Flutter AOT reproducibility is unverified and may need investigation.
