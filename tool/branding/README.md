# Stack Wallet branding

Configures a checkout for one brand with the `whitelabel` engine. Brand
manifests live in `brands/`. The engine is pinned by commit in `pubspec.yaml`.

```sh
dart tool/branding/configure.dart --brand campfire --platforms linux \
  --version 2.4.0 --build-number 123 --apply
flutter build linux --release --flavor campfire
```

Without `--apply` the command prints the plan. `--diff` and `--json` change the
plan format. `--prebuilts` enables the prebuilt native-asset block in
`pubspec.yaml`. Existing outputs the engine does not own require `--overwrite`.
Build with the flavor that matches the brand; `--flavor` rejects a mismatch
before writing.

Assets are copied, not linked. A checkout with asset symlinks from the legacy
scripts must be cleaned first. For Windows MWEB, prepare
`assets/windows/mwebd.exe` and pass its trusted digest with `--mwebd-sha256`.

`dart tool/branding/configure.dart --recover` restores an interrupted apply from
`.whitelabel/`.

## Verification

```sh
dart analyze --fatal-infos
dart test
python3 tool/verify_parity.py --repo ../.. --base HEAD
```

`verify_parity.py` configures each brand in disposable clones with both the
legacy scripts and this tool, then compares the generated Android and Linux
files, interfaces, and asset contents. `verify_pair.py --engine <path>` runs the
same checks against a local engine checkout through the committed pin.
