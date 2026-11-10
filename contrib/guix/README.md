# Experimental Guix builds for Stack Wallet

**Blocked on current staging:** this prototype predates the migration from
`crypto_plugins` submodules to Dart native-assets hooks. Merging staging does not
make the old offline build recipe compatible. The fetch, verification, and build
entry points now fail before downloading dependencies or starting a container
when the required legacy workspaces are absent. This is a diagnostic guard, not
an implementation of native-assets support.

The orchestration, cache, and attestation scripts remain useful as a starting
point. They have not produced a verified reproducible build of current staging.
Do not use their presence checks or signed checksums as evidence that the native
libraries were built reproducibly from reviewed source.

## Work required before enabling builds

1. Resolve native packages from the generated app configuration and locked pub
   dependencies. Replace all `crypto_plugins` paths and legacy Cargokit setup.
2. Vendor every selected native hook's Rust dependencies (including Xelis and
   Tor), pin the toolchain each hook actually invokes, and honor locked sources.
3. Fetch and verify the Go module cache for MWEB and all CMake/source downloads.
   Make the hooks consume those caches without network access. The current
   scripts do not populate the `go-cache` mount.
4. Pin Guix channels, Flutter SDK archives, Rust archives, and native sources.
   Verify extracted cache contents as well as archive hashes. `verify-deps.sh`
   currently checks package presence; it does not authenticate those contents.
5. Build the same commit independently in two clean network-isolated containers,
   compare outputs, investigate Flutter AOT differences, and only then publish
   reproducibility claims or attestations.

The historical variant table is obsolete: current native packages and hooks
must be derived from each variant's generated pubspec, including Campfire.

## Entry points

Run commands from `contrib/guix`. `SOURCE_DIR` defaults to the checkout containing
these scripts, including Git worktrees; set it explicitly only for another source
checkout. The current staging SDK version is Flutter 3.47.2.

```bash
# These commands intentionally stop on current staging until the port is ready.
supplementary/deps/fetch-pub-deps.sh
supplementary/deps/fetch-cargo-deps.sh
supplementary/deps/verify-deps.sh
./guix-build --app stack_wallet --version 2.3.4 --build-number 234
```

The fetch/build/verification pipeline requires `FLUTTER_SDK_SHA256`, a 64-digit
SHA-256 obtained independently for the exact Flutter Linux SDK archive. It no
longer accepts an unverified download and merely prints its hash. SDK metadata
must parse and match the pinned version; empty or malformed output fails.

`guix-build` accepts `--app stack_wallet|stack_duo|campfire`, `--version`,
`--build-number`, `--jobs`, and `--hosts`. Linux x86_64 is the only intended target.
`BASE_CACHE` selects the dependency cache; `OUTDIR` selects output;
`SOURCE_DATE_EPOCH` otherwise comes from the source commit.

`guix-attest` signs build checksums with GPG, and `guix-verify` compares
attestations. Signing proves who signed particular checksums, not that the
build is reproducible. `guix-clean` removes outputs; `--all` also removes caches.

## Local validation

From the repository root:

```bash
python3 -m unittest discover -s contrib/guix/tests -v
```

The tests exercise worktree source selection, early failure on current staging,
checksum validation, and SDK metadata handling. They do not run a Guix container
or demonstrate artifact reproducibility.
