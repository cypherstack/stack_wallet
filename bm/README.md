# Build benchmarks

Measure wall-clock build time and disk delta for the native-assets build. The
suite runs `make build-macos` / `make build-linux`, so it inherits the same
toolchain rules as the build itself.

## Run inside a Nix/direnv shell

Source builds require an active Nix/direnv shell (the flake supplies Flutter,
Rust, Go and the dnix libraries). Run the harness from that shell, exactly as a
real build:

```sh
make bootstrap          # enter the Nix dev shell
bash bm/bench.sh        # one cold build (sccache on), appends to bm/results/<host>.csv
```

On macOS, `make bootstrap-macos` installs Nix (if missing) and selects Xcode
before you enter the shell.

## Scripts

| Script | Purpose |
|---|---|
| `bench.sh` | One build (cold or `--warm`), records wall seconds + disk delta to `bm/results/<hostname>.csv` |
| `collect.sh` | Snapshot disk/`build/`/toolchain sizes independent of a build |
| `compare.py` | Render/compare the CSVs (terminal table, or markdown for PDF) |
| `render.sh` | Convert a markdown report to HTML + PDF (needs `pandoc`; a PDF engine is optional) |
| `run_all.sh` | Full cold→warm suite, simplest to most optimized |

## bench.sh flags

```sh
bash bm/bench.sh                 # cold build, sccache on (default)
bash bm/bench.sh --warm          # warm rebuild (no clean)
bash bm/bench.sh --label NAME    # tag the run
bash bm/bench.sh SCCACHE=0       # cold, sccache off
bash bm/bench.sh SKIP_NATIVE=1   # Dart only (no native libs)
```

## Caveats

- **Results are per-machine and git-ignored** (`bm/results/`). Do not commit
  them; they vary by hardware and Nix store state.
- **Cold runs assume a warm Nix store.** A fresh store compiles the dnix
  libraries from source (~2h) and that time would dominate the wall clock,
  masking the sccache-vs-no-sccache comparison. Pre-fetch the dnix sources
  (e.g. `nix build` once) before measuring so a cold run only measures the
  project build, not the library compile.
- **sccache is a cargo-config toggle, not a make flag.** `SCCACHE=0/1` is
  accepted by `bench.sh` for labeling, but sccache is actually turned on/off by
  `make sccache-setup`, which writes `~/.cargo/config.toml` with the
  `rustc-wrapper = "sccache"` setting. Remove that file to benchmark without
  sccache.
- **`SKIP_NATIVE=1` is a no-op through `make`.** The Makefile does not consume
  it; it is a leftover from the harness's pre-make origin. Use `make clean-native`
  + `make build-macos` if you want to isolate the Dart layer.
