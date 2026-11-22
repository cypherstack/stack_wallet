# Build and cache benchmarks

Plain text, terminal only. Run everything from the shell you normally build in (for
example `nix develop`): Flutter reruns its native hooks whenever `PATH` or a `NIX_*`
variable changes, so runs from different shells measure different things.

| Script | What it does |
|---|---|
| `bm/bench.sh` | times one `make build-macos` / `make build-linux` run and appends a row to `bm/results/<host>.csv` (ignored by git) |
| `bm/matrix.sh` | runs six standard scenarios in a row (cold/warm × sccache off/on, `clean-app`, `clean-native`) and prints the report |
| `bm/report.sh` | prints the CSV as a table with each run compared to the first |

```sh
make sccache-setup                          # once: sccache for the hooks' Rust/C builds
bash bm/bench.sh --sccache off              # cold build without sccache
bash bm/bench.sh --clean native             # rebuild only the native libraries
bash bm/bench.sh --label prebuilts PREBUILTS=1
bash bm/matrix.sh && bash bm/report.sh
```

Each row records the clean mode, whether sccache was on, the make flags, wall seconds,
success, disk growth and sccache hits/misses. A failed build is recorded with
`success=0`.

Notes on what can and cannot be cached:
- With Flutter 3.47.x the hooks only see sccache through the `rustc-wrapper` line in
  `~/.cargo/config.toml` (what `make sccache-setup` writes). `--sccache off` removes that
  line for one run and restores it afterwards. Flutter versions with `hooks_runner` 1.6.2 or
  newer also accept `CARGO_BUILD_RUSTC_WRAPPER=sccache` from the environment.
- `make clean-app` keeps `.dart_tool/hooks_runner`, so the next build skips the native
  libraries; `make clean-native` removes exactly those. The difference between the two
  scenarios is the cost of the native builds.
- A shared `CARGO_TARGET_DIR` does not work (`native_toolchain_rust` passes `--target-dir`),
  and `RUSTC_WRAPPER` or `RUSTFLAGS` exported in the shell never reach the hooks on 3.47.x.
