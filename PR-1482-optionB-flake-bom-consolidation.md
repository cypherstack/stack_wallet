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

## What is NOT in scope

- Homebrew installer Go version: it runs `brew install go` with no version pin.
  Homebrew's `go` is "latest", so the installer's Go already drifts from the BOM
  independently of this work. Leaving it is consistent with the prebuilt/host
  path being best-effort; pinning it is a separate, smaller task.
- system_deps (jsoncpp, libsecret, etc.): not version-pinned anywhere except the
  BOM comment; they come from the OS package manager. No consolidation action
  needed — they are already single-sourced (only in the BOM).
