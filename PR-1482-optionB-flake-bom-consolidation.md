# Option B (deferred): make flake.nix read Flutter/Go from stack-bom.toml

Status: **planned, NOT implemented.** Deferred from the Option A consolidation
(2026-11-20). Option A is committed (`27e30c324`): the Dockerfile now reads
Flutter + Go from the BOM. This document is the plan for the remaining gap.

## The remaining duplication (verified against code)

`stack-bom.toml` is the intended single source of truth. After Option A the
Dockerfile reads it. What still does **not** read the BOM for Flutter and Go:

| Version | BOM | flake.nix today | Homebrew installer | Dockerfile (after A) |
|---|---|---|---|---|
| flutter `3.47.2` | ✅ | ❌ bare `pkgs.flutter` (nixpkgs rev pins it) | ✅ `bom_get flutter` | ✅ reads BOM |
| go `1.24.13` | ✅ | ❌ bare `pkgs.go` (nixpkgs rev pins it) | ⚠️ `brew install go` (no version) | ✅ reads BOM |
| rust `1.99.1` | ✅ | ✅ `bom.toolchain.rust` | ✅ `bom_get rust` | n/a (rustup latest) |
| dnssec_rust `1.90.0` | ✅ | ✅ `bom.toolchain.dnssec_rust` | ✅ `bom_get rust_dnssec` | n/a |

So after Option A, **rust/dnssec/flutter are already single-sourced**; the only
remaining drift is **Flutter and Go in the Nix shell**, which use bare nixpkgs
packages. The flake.nix comment at line 18 ("Single source of truth for the
toolchain versions") is currently **aspirational** — it is true for rust/dnssec,
false for flutter/go.

## Why this is the risky one (do NOT do casually)

The Nix shell is the **reproducible source-build path** (`PREBUILTS=0`,
`TOOLCHAIN=nix`). The 2026-11-18 verified builds (dnix byte-for-byte
reproduction of the 4 native libs) depend on a specific Flutter version in the
shell. `pkgs.flutter` from the pinned nixpkgs rev (`b1b875982b17dabde9b4a37f3e229e74913e6db3`)
is whatever that rev ships — it may **not** equal `3.47.2`. Forcing it to `3.47.2`
changes the shell's Flutter, which can change:

- the Dart SDK bundled with Flutter (affects the `dart`/`flutter` used by dnix
  native plugins and `verify_bom.dart`),
- the iOS/macOS CocoaPods/Flutter engine hashes dnix rebuilds byte-for-byte.

That is exactly the property dnix guarantees. A version mismatch there is not a
cosmetic drift — it can break the dnix reproduction or silently change the
produced binaries. **This is why Option B needs a real verification build**,
which cannot be fully run on this host (no Flutter in the Nix shell here).

## The concrete change

flake.nix must select the exact Flutter and Go versions from the BOM instead of
bare packages. Two sub-approaches:

### B1 — nixpkgs version-selector packages (preferred, lowest blast radius)
nixpkgs exposes versioned aliases: `pkgs.go_1_24` (exists for many Go majors).
For Go this is a one-line change: `go` → `go_1_24` (or derive from the BOM's
`go` major). It locks the shell to the Go that nixpkgs rev provides for `go_1_24`,
which for `1.24.13` should match — **verify** the resolved version equals the
BOM after the change.

Flutter has **no** `pkgs.flutter_3_47` style alias in standard nixpkgs — the
bare `pkgs.flutter` is the only option, and it is rev-pinned. To pin Flutter
`3.47.2` exactly you must either:

- pin the **nixpkgs rev to the one that ships Flutter 3.47.2**, or
- add a **Flutter overlay/expression** that fetches Flutter at the exact git
  ref/commit behind tag `3.47.2` (Flutter releases are git tags; the
  `flutter` nixpkgs derivation takes a `version`/`src` you can override).

### B2 — overlay that reads the BOM (most faithful, most work)
Write a small overlay that, given `bom.toolchain.flutter`, builds Flutter from
the matching git tag (`https://github.com/flutter/flutter.git` @ tag
`<version>`), reusing the same source the Dockerfile and Homebrew installer
clone. This makes all four sources truly identical, but it is a real nix
expression (Flutter's build needs the Dart SDK, engine artifacts, and
`flutter precache`), and it changes the reproducibility story from "whatever
nixpkgs rev ships" to "pinned to the BOM tag" — a behavior change that must be
documented and build-verified.

## Recommended sequencing

1. **Do B1-Go first** (one line: `go` → versioned selector). Verify the resolved
   Go version equals `bom.toolchain.go`. Low risk.
2. **Flutter is the hard part** — treat it as its own PR:
   - Decide: pin nixpkgs rev to the Flutter-3.47.2 one (B1), or add a BOM-driven
     Flutter overlay (B2). B1 is less code but couples the whole toolchain to a
     rev chosen for Flutter; B2 is more code but keeps the current rev and pins
     only Flutter.
   - **Must run `make build-macos` and `make build-linux`** to confirm dnix
     still reproduces byte-for-byte and the app builds. This is the gate; without
     it Option B is EDITED/UNPROVEN, not CERTIFIED.
3. Keep the flake.nix comment honest: change "Single source of truth for the
   toolchain versions" to name exactly which keys it sources (rust, dnssec_rust,
   and — after B — flutter/go), or leave it aspirational with a TODO.

## Risk register

- **dnix byte-for-byte break** — the dominant risk. Flutter version change in the
  shell can change engine/Dart artifacts dnix rebuilds. Mitigation: the verification
  build is mandatory; do not merge without it.
- **nixpkgs rev coupling** — pinning the rev for Flutter 3.47.2 may regress Go or
  other packages; re-verify the whole toolchain.
- **Overlay maintenance** — a B2 Flutter overlay must track Flutter's release
  structure; it is more to maintain than a version selector.
- **Cannot self-verify here** — no Flutter in the Nix shell on this host; the
  author must run the builds on a machine with the full nix env.

## Verified finding (2026-11-20) — nixpkgs `go_1_24` selector is gone; exact-fetch is the fix (CORRECTED)

Resolved the pinned nixpkgs rev `b1b875982b17dabde9b4a37f3e229e74913e6db3`
directly with `nix eval`:

- `pkgs.go_1_24` → **MISSING** (the selector does not exist in this rev).
- `pkgs.go_1_25`, `pkgs.go_1_23` → **removed** (Go 1.23/1.25 are end-of-life in
  this rev).
- `pkgs.go_1_26` → `1.26.7` (the only `go_1_*` selector present).
- bare `pkgs.go` → **`1.26.7`** — already drifts from the BOM's `1.24.13`.

So B1-Go (`go` → `go_1_24`) **cannot** be applied without first moving the
nixpkgs rev to one that still ships `go_1_24`. And bare `pkgs.go` is already at
1.26.7, not the BOM's 1.24.13 — meaning the Nix shell's Go has been drifting
from the BOM all along, on the prebuilt-independent source path.

**CORRECTION (2026-11-20, the "nixpkgs-rev change" framing is WRONG):** the
implication above was wrong. A nixpkgs-rev change is **not** required. The
Dockerfile (Option A, committed) already reads Flutter/Go from the BOM and pins
**exact** versions with **no nixpkgs involvement** — `Dockerfile:87-103` and
`:182-198`:

```dockerfile
GO_VERSION="$(... bom_values.sh --get go)"           # 1.24.13
curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
FLUTTER_VERSION="$(... bom_values.sh --get flutter)" # 3.47.2
git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git
```

So the exact-version fetch pattern is **already proven in this repo**. The
`go_1_24` selector being gone from this rev is irrelevant — the fix does not use
nixpkgs selectors at all. The two viable approaches (both keep the current rev):

1. **Go:** replace bare `go` in `flake.nix` with a small nix derivation that
   fetches `https://go.dev/dl/go1.24.13.linux-amd64.tar.gz` / `-darwin.tar.gz`
   at the BOM's `go` value (mirrors the Dockerfile). No rev change.
2. **Flutter:** either fetch the `flutter@3.47.2` git tag directly (like the
   Dockerfile) or pin the nixpkgs `flutter` derivation's `version`/`src` to the
   BOM value. No rev change.

What is still true: the **build-gate verification** (`make build-macos` /
`make build-linux`, confirming dnix still reproduces byte-for-byte after the
Flutter change) cannot run on this host (no Flutter in the Nix shell), so the
flake edit stays **planned / EDITED-UNPROVEN** until done on a full nix-env
machine. But the blocker is *verification*, **not** a rev change. Do NOT ship a
partial flake edit here without the build gate — changing bare `pkgs.go`/
`pkgs.flutter` silently changes the toolchain dnix verifies against.

## What is NOT in scope

- Homebrew installer Go version: it runs `brew install go` with no version pin.
  Homebrew's `go` is "latest", so the installer's Go already drifts from the BOM
  independently of this work. Leaving it is consistent with the prebuilt/host
  path being best-effort; pinning it is a separate, smaller task.
- system_deps (jsoncpp, libsecret, etc.): not version-pinned anywhere except the
  BOM comment; they come from the OS package manager. No consolidation action
  needed — they are already single-sourced (only in the BOM).
