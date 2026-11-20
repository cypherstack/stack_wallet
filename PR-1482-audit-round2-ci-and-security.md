# PR #1482 — Audit Round 2: CI Intel + Security + Native Integrity + Dart Logic

Prepared 2026-11-20. Follows the first-round audits (A–F: Makefile, bootstrap, docs, CI, bm harness, BOM).
New angles: our own CI surface, build-pipeline security, dnix prebuilt integrity, Dart logic in the changed files.

Every BLOCKER/MAJOR claim from a subagent was re-checked against ground truth. Subagent findings are leads, not truth.

## Verdict
**No new merge blockers.** The PR's changed Dart code is correct and fail-closed (`dart analyze` clean; `verify_bom.dart` compiles standalone; logic reviewed line-by-line). The security-reviewer's two headline claims (CHANGE_NOW "BLOCKER", dnix.lock "missing") are both false positives. The one genuine, maintainer-facing item is a **coverage gap** (tests run only on PR, not on push to staging) plus the architectural note that the Makefile is not exercised by automated CI.

---

## 1. CI Intel (our own workflows)

### Trigger matrix
| Workflow | Triggers | Tests run? |
|---|---|---|
| `build.yaml` | push (tags `v*.*.*`, branch `staging`) + workflow_dispatch | No — builds only |
| `test.yaml` | **`pull_request` only** | **Yes** — 11 `dart scripts/tests/*` + `flutter test --coverage` + `make-check` dry-run matrix |
| `make-smoke.yaml` | workflow_dispatch only (manual) | No — `make build-linux` smoke |
| `build-ci-image.yaml` | push (main/staging) + workflow_dispatch | N/A — builds the CI image |
| `release-mwebd-windows.yaml` | workflow_dispatch only | No |

### Image tags are correct (not a divergence)
`build-ci-image.yaml` builds three distinct Dockerfile targets and pushes distinct tags:
- `:latest` = `full` target (used by build.yaml build jobs + make-smoke)
- `:test` = `test` target (used by test.yaml)
- `:android` = `android` target

test.yaml using `:test` while build.yaml uses `:latest` is intentional multi-target, not drift.

### Genuine findings
- **MAJOR (coverage):** `test.yaml` fires on `pull_request` only. `build.yaml` fires on `push: branches: [staging]`. So **direct commits to staging bypass the entire Dart test suite + `flutter test` + make-check.** If staging accepts direct pushes, that is a real gap. Fix options: add `push: branches: staging` to `test.yaml`, or rely on repo branch protection requiring the PR check. Maintainer decision.
- **MAJOR (architectural):** the Makefile — the PR's central deliverable — is never exercised by automated CI. All 19 build.yaml jobs call `./build_app.sh -d` then `flutter build` directly; none run `make`. `make-smoke.yaml` (the only thing that runs `make build-linux`) is manual `workflow_dispatch` only. So the make path has no automated gate.
- **MINOR:** no static analysis in CI (`flutter analyze` is commented out in test.yaml).
- No in-YAML merge-gate; relies on repo branch protection (repo-side config, not YAML-fixable).

### False positives from the CI scout (verified NOT defects)
- "Android signing secrets required, no fallback" — by design; a release APK must be signed.
- "bom job is a single point of failure" — that is how a shared config gate is meant to work; fail-fast on invalid BOM is correct.
- "verify-toolchain missing from non-linux / Windows jobs" — those are prebuilt (`build_app.sh -d`) jobs; they don't run make and don't need host Rust. (Same false positive as round-1 Audit D.)
- "CHANGE_NOW if set-but-empty overwrites with empty content" — wrong; `[ -n "" ]` is false, so an empty secret correctly uses the stub.

---

## 2. Build-pipeline security (security-reviewer)

### False positives (verified NOT blockers)
- **"CHANGE_NOW decoded to `lib/external_api_keys.dart` — BLOCKER"** — No. That file is a generated, gitignored artifact (the empty-stub fallback proves it is never committed). The decoded secret lives only in the ephemeral CI container workspace and is compiled into the release binary (embedding the ChangeNow API key in the app is the app's normal design). GitHub masks `${{ secrets.X }}` in logs. Standard pattern.
- **"dnix.lock missing from repo — MAJOR"** — No. dnix uses **distributed per-plugin lockfiles** (each plugin's `dnix.json`/`dnix.lock` lives in its own repo, fetched at build). `pubspec.lock` (committed) pins all 4 native libs — `flutter_libepiccash`, `flutter_libmwc`, `frostdart`, `tor_ffi_plugin` — by git URL + revision. The security-reviewer searched only the repo root and concluded "missing."

### Real / acceptable
- **install_nix.sh `curl https://nixos.org/nix/install | sh` without checksum — acceptable (NIT).** This is the official, documented Nix install method; a hardcoded checksum would need Nix's rotating published hash. Consistent with how every Nix user installs.
- **No app-level secondary check if dnix's upstream hash verification were compromised — by design (the locked dnix-hash-only decision).** Not a code defect. `check_native_overrides.dart` provides defense-in-depth (exit 1 if `.dnix-build` overrides present).
- BOM parser / `bom_values.sh` / install scripts are well-guarded: version-format validation, duplicate-section rejection, path quoting, fail-closed on malformed input.

---

## 3. Native-dependency / dnix integrity (scout)

- The `-d` hash check is **mandatory at the dnix level** (dnix build hooks verify each downloaded lib against its `dnix.lock` release hash); `build_app.sh -d` delegates to dnix rather than re-implementing it.
- `pubspec.lock` is committed and pins all 4 native libs by git revision.
- **MAJOR (architectural note, pre-existing, not a PR regression):** `stack-bom.toml` pins toolchains but does not pin the 4 native-lib versions/hashes, and there is no guard cross-validating that a BOM toolchain upgrade is compatible with the pinned native-lib git revisions. The PR diff does **not** touch `pubspec.lock`/`pubspec.yaml`, so this is a pre-existing property, not introduced or regressed by #1482.

---

## 4. Dart logic in the changed files (main-agent review)

All 4 changed Dart files are **new** (934 insertions, 0 deletions) — no regression risk in existing code.

- `tool/bom_parser.dart` — `readBom` fails closed (unterminated string → `FormatException`), strips trailing comments only on bare values, handles CRLF in `lockRefs`, correct PATH-list-separator handling in `resolveOnPath` (explicitly avoids the `Platform.pathSeparator` mistake). `compareVersions` compares 3 components (sufficient for x.y.z toolchains).
- `tool/verify_bom.dart` — `_finish()` exits 1 on any failure; `--toolchains` degrade-to-warning for missing flutter/rustup is intentional and documented (CI host runner has no toolchain); Flutter path-with-space check fails closed with a clear message; JSON parse fail-closed on malformed output.
- `scripts/tests/{verify_bom_parser_test,bom_values_test}.dart` — meaningful assertions (parse, comment handling, version compare, duplicate-section rejection). Passed `dart analyze`.

### Verification run on this host (no Flutter; package resolution too slow for `dart test`)
- `dart analyze tool/bom_parser.dart tool/verify_bom.dart scripts/tests/*_test.dart` → **No issues found.**
- `dart compile kernel tool/verify_bom.dart` → **exit 0** (parser API fully consistent).
- Full `dart test` / `flutter test` require the `:test` CI image (package graph resolution + native Rust deps); deferred to CI.

### Latent MINORs (benign for the actual BOM format)
- `readBom`: a single-quoted value with a trailing ` #comment` would have the comment stripped (only double-quoted values are protected). The BOM uses double quotes, so benign.
- `compareVersions`: only compares 3 numeric components; a 4th component (e.g. a build suffix) is ignored. Toolchains are all x.y.z, so benign.

---

## Summary table
| Item | Severity | Status |
|---|---|---|
| Tests run only on PR, not push to staging | MAJOR (coverage) | maintainer decision — not a code bug |
| Makefile not exercised by automated CI | MAJOR (architectural) | make-smoke is manual; release path bypasses make |
| BOM doesn't cross-validate native-lib versions | MINOR (pre-existing) | not introduced by this PR |
| No `flutter analyze` in CI | MINOR | commented out in test.yaml |
| CHANGE_NOW "BLOCKER" | — | false positive (generated gitignored file) |
| dnix.lock "missing" | — | false positive (distributed per-plugin locks) |
| install_nix.sh curl\|sh no checksum | NIT/acceptable | official Nix install method |
| Dart changed files | — | clean: analyze + compile verified |
