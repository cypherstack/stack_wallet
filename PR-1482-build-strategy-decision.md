# PR #1482 — Build strategy decision brief (Nix-only vs brew, benchmarks re-integration)

_Compiled 2026-11-20. Grounded in the current tree (`feat/makefile-macos-build`, 18 commits past `15d0e12d3`)._

## The situation (your story, confirmed against the code)

1. You built a working **make-based** cross-platform build (macOS/Linux/Windows) with real **caching** work — including changes to Rust crates so they build on a shared Rust version and benefit from cargo caching.
2. Julian introduced **native-assets Flutter**; the build process changed and your caching no longer applied cleanly.
3. You found **sccache** still works, and want to merge the makefile + benchmarking work.
4. Now: merge everything, clean up the existing CI + legacy build flows, make it proper.

## Settled facts (verified in-tree, 2026-11-20)

- **CI already does NOT use Nix.** Every CI build job (`build-windows` @ `windows-2022`, `build-macos` @ `macos-latest`, `build-linux`/`build-android` @ `ubuntu-24.04`) runs `build_app.sh … -d -s`, where **`-d` = verified dnix prebuilts** (Frost/Tor/Epic/MWC), hash-checked against each plugin's `dnix.lock`. No Nix, no WSL.
- **Nix is used only for local source builds** on macOS/Linux, and only when run inside a Nix/direnv shell (`build-macos`/`build-linux` derive `SOURCE_TOOLCHAIN` from `NIX_BIN` on PATH).
- **Windows has no Nix path at all.** dnix on Windows runs in WSL2; CI is `windows-2022` (native Windows), so Windows is prebuilt-only by necessity.
- The Homebrew fallback (`scripts/install_macos_build_tools.sh`) is the **only** thing that lets a local macOS/Linux source build run *without* Nix. It already reads every version pin from `stack-bom.toml` (`bom_get flutter/rust/rust_dnssec`), so it is **not** a duplication source.
- The prebuilt path's version check is **dnix's own hash verification** (`build_app.sh -d` verifies pinned SHA in prebuilt mode). That is the correct and sufficient "what to check" — the native lib versions are pinned in `dnix.lock`.

## Decision 1 — Source-build toolchain policy

### Option A: Nix-only for source builds (your preference)

**Changes (minimal):**
- Delete `scripts/install_macos_build_tools.sh`.
- Delete the `else` (brew) branch of `bootstrap-macos` (Makefile:310-318); keep only the Nix-detecting branch, which already calls `install_xcode.sh`.
- Update docs: `docs/building/make.md` (the "Homebrew packages are in `install_macos_build_tools.sh`" line), `cyperstack_matrix_info.md:40` (the "pins live in `install_macos_build_tools.sh`" line).
- `verify-bom` already warns on missing toolchains; no new check needed for source builds (Nix provides them).

**Limits / consequences:**
- **Contributors without Nix can no longer do a local source build.** They can still: (a) use prebuilt submodules via `PREBUILTS=1` + dnix prebuilts (`-d`) — this needs only the *toolchain* (Flutter/Rust/Go/Xcode), which they install however they like; (b) rely on CI.
- **CI is unchanged** — it already uses prebuilts, not Nix. No risk to the release pipeline.
- **Windows unchanged** — already prebuilt-only.
- **Cleanest merge story.** One toolchain path for source; matches Julian's stance. Kills a legacy flow instead of carrying it.

**What it takes:** ~3-4 file edits, all doc + one Makefile branch + one file delete. Low risk. The only real work is the Option B flake change (below) if you also want the flake to read the BOM — otherwise the flake keeps its bare `pkgs.flutter`/`pkgs.go`, which is fine for Nix-only (Nix pins via nixpkgs rev).

### Option B: Keep the Homebrew fallback

**Changes:** none structural — the script already tracks the BOM.

**Limits / consequences:**
- Two source-build paths to maintain and keep in sync (Nix + brew). The brew path's native libs come from Homebrew formulae whose versions **drift** from the dnix pins — this is the *real* duplication risk, because Homebrew auto-upgrades can move a lib version out from under a `dnix.lock` pin. (Mitigated by `HOMEBREW_NO_INSTALL_UPGRADE=1` in the script, but not eliminated.)
- More contributor-friendly (no Nix install to try a source build).
- Slightly muddier merge story — you're defending a path Julian is willing to drop.

**What it takes:** nothing now; ongoing cost is keeping the brew formula set honest against the dnix pins.

### Recommendation

**Option A (Nix-only for source).** It matches your stated preference and Julian's, it's the smallest diff, and it removes the one genuinely duplicated + drift-prone path. The prebuilt path (dnix `-d`) still serves everyone who can't or won't use Nix — including all CI and Windows. Keep the BOM as the single toolchain source; the native libs stay pinned in `dnix.lock`.

## Decision 2 — What to check on the prebuilt path

**dnix hash verification only** (your choice). The native libs are hash-checked against `dnix.lock` by `build_app.sh -d`; the host only needs the toolchain, which `verify-bom` checks. No extra host-side lib-version probing — that would duplicate what dnix already guarantees.

## Decision 3 — Windows

**Keep as-is** (dnix prebuilts, no Nix). It already builds. Nix is not an option on `windows-2022`.

## Decision 4 — Re-integrating your benchmarks (`bm/bench.sh`)

**What it is:** `bm/bench.sh` (124 lines, on `build/native-assets-harness`, **not** on the current PR branch). A build-time benchmark harness:
- Runs `make build-macos`/`build-linux` (cold or `--warm`), records **wall-clock seconds + disk delta** to `bm/results/<host>.csv`.
- Flags: `SCCACHE=0` (compare with/without sccache), `SKIP_NATIVE=1` (Dart-only), `--label`, `--warm`.
- Depends on `toilet` (terminal font) for pretty output — a soft dependency, easy to drop.
- Windows path explicitly refuses (needs WSL2).

**Re-integration effort — small, and it's independent of the Nix-only decision:**
- The script itself is self-contained; cherry-pick `bm/bench.sh` + the `bm/results/` dir onto the PR (or a follow-up branch). ~1 file.
- **It already calls `make build-macos`/`build-linux`**, which under Nix-only means "must be in a Nix shell." That's actually *better* for benchmarking — the harness measures the canonical source build. No change needed.
- The sccache comparison (`SCCACHE=0`) is the interesting data: it measures your caching contribution directly. `make sccache-setup` (opt-in, on `build/native-assets-harness`) writes `~/.cargo/config.toml` with the `sccache` rustc-wrapper.
- **Caveat:** `bm/bench.sh` runs the *full* native build each cold run — on a fresh Nix shell that includes the dnix source compile (the 2-hour path). For a clean sccache-vs-no-sccache comparison you want the *incremental* native layer, so document that cold benchmarks assume a warm Nix store / pre-fetched dnix sources.

**Recommendation:** land `bm/bench.sh` as a **separate small follow-up PR** (or a second commit on this branch after the build-strategy change lands), so the big merge isn't entangled with a benchmarking tool. It's orthogonal to Nix-only vs brew.

## Sequencing to close the topic

1. **Build-strategy change** (Option A): delete the brew fallback + docs, keep prebuilt/dnix path. One coherent commit.
2. **Optional Option B (flake reads BOM)** — only if you want the flake's Flutter/Go sourced from the BOM too. HIGH risk (nixpkgs-rev coupling); plan already written in `PR-1482-optionB-flake-bom-consolidation.md`. Can be its own PR.
3. **`bm/bench.sh` re-integration** — separate small PR/commit, orthogonal.

---

## Outcome — Option A executed (2026-11-20)

**Decision 1 resolved: Nix-only for source builds.** The Homebrew source-build fallback is removed; Homebrew remains a valid package manager for the **prebuilt** path (`PREBUILTS=1`).

### Changes (one commit)
- **`scripts/install_macos_build_tools.sh`** — deleted (the Homebrew tool installer).
- **`Makefile`**:
  - `bootstrap-macos` rewritten: now only runs `@bash scripts/install_xcode.sh` (Xcode is never provided by Nix/Homebrew). Dropped the `install_macos_build_tools.sh` branch and the `rustup target add` line.
  - `bootstrap-brew` alias removed; removed from `.PHONY`.
  - `bootstrap` target error wording: "Nix is not installed. Source builds require Nix; install it from https://nixos.org/download/."
  - `toolchain-check`: dropped the `ifeq ($(TOOLCHAIN_EFFECTIVE),brew)` hard-fail branch; the final filter now treats `host`/`manual` as "tools on PATH, no separate check" (correct for the prebuilt path).
  - `TOOLCHAIN` allowed values: removed `brew` (`auto nix direnv manual host`).
- **Living docs** (`README.md`, `docs/building/make.md`, `docs/building/macos.md`, `docs/building/make-flow.md`): reframed Homebrew from a source-build fallback to the prebuilt path; `bootstrap-macos` now described as Xcode check/select; `PREBUILTS=1` required for Homebrew/manual.
- **Historical drafts** (`cyperstack_matrix_*.md`, `julian_review_reply_draft.md`) — left **unchanged**: they are records of what was told to Julian when the Homebrew path existed.

### Not done (out of scope, still open)
- **`makefile-build-audit` blocker** (PREBUILTS=0 guard tests only `NIX_BIN`, not `TOOLCHAIN_EFFECTIVE`): still present. Deleting the brew bootstrap removed the *toolchain* angle, but `make -n build-macos PREBUILTS=0 TOOLCHAIN=host` on a non-Nix host still doesn't hard-fail in dry-run (the guard runs at recipe time, and `-n` skips it). Consider tightening to require `nix`/`direnv` explicitly for `PREBUILTS=0` — a follow-up.
- **Option B** (flake reads BOM) and **`bm/bench.sh` re-integration** — unchanged, still separate follow-ups.

### Verified
- `make -n help` parses cleanly.
- `toolchain-check` has no brew branch; the final filter is `ifeq ($(filter nix direnv,$(TOOLCHAIN_EFFECTIVE)),)`.
- Prebuilt path works: `make -n build-macos PREBUILTS=1 TOOLCHAIN=host` → exit 0.
- No dangling `install_macos_build_tools` / `bootstrap-brew` / `Homebrew fallback` refs in living docs.
