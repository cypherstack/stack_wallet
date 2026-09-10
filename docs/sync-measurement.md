# Measuring wallet sync

The wallet has been called slow. That impression came from one wallet with 442
transactions and 437 UTXOs, on an old handset, running a **debug** build. Each of
those three on its own is enough to mislead, and a debug Flutter build is several
times slower than a release one for reasons unrelated to our code.

Nothing should be rewritten on that evidence. This is how to replace it.

## What is being tested

Whether the cost is **Electrum round trips**, **local processing**, or **the
build mode**. Those have completely different fixes, and only the first two are
worth spending engineering on.

The earlier investigation concluded the bottleneck is Electrum I/O and
large-wallet processing rather than UI or crypto. This measurement is here to
confirm or refute that, not to assume it.

## Build

```bash
BFX_APP_ID=org.bitfinitechain.wallet.profile \
  scripts/build-android-docker.sh profile
```

**Use `profile`, never `debug`.** Profile compiles like release but leaves the
observatory attachable. Before this was added, anything that was not `release`
fell through to a debug build, so asking for a profile build produced a debug
APK and the timings were wrong in the direction that mattered.

The distinct app id lets it sit beside the real wallet rather than overwriting
it.

## Run

Each refresh logs one line:

```
SYNCTRACE bitfinite/<walletId> total=4820ms chainHeight=210ms
  receivingAddrScan=1180ms changeAddrScan=890ms transactions=3400ms
  utxos=1100ms balance=140ms txs=42 utxos=37
```

Read it with two things in mind:

- `transactions` and `utxos` run concurrently, so their numbers overlap and must
  not be added. Each is the wall clock cost of that phase alone.
- `txs` and `utxos` at the end are the wallet's size. A duration without the size
  of the thing it processed cannot be compared against another run.

Pull the log off the handset, or watch it over `adb logcat`.

## The runs that matter

Take each three times and use the median. First runs include cold caches and
connection setup, which is worth knowing but is not the steady state.

| Wallet | Device | Build | Why |
|---|---|---|---|
| Normal, tens of txs | Mid range | profile | The number that decides anything |
| Normal, tens of txs | Old handset | profile | Separates the device from the code |
| Founder, 442 tx / 437 UTXO | Mid range | profile | The known pathological case |
| Normal, tens of txs | Mid range | debug | Quantifies how much the build mode alone was worth |

That last row is the control. If debug against profile explains most of the gap,
the original complaint was about the build, and there is nothing to fix.

## Reading the result

- **`transactions` and `utxos` dominate** — the cost is Electrum I/O and
  processing. That is the case where moving that path to a compiled core is
  worth costing out. The UI framework is not implicated.
- **`receivingAddrScan` and `changeAddrScan` dominate** — gap-limit scanning is
  making too many round trips. Fixable in our own code, no rewrite.
- **Everything is fast but the app still feels slow** — then it is rendering,
  and only then does the UI framework enter the argument.
- **Debug is much slower than profile and profile is fine** — close it.

## A note on what this cannot tell you

These timings are wall clock around whole phases. They locate the cost; they do
not explain it. Once a phase is identified, attach DevTools to the profile build
and look at the CPU profile and the timeline for that phase specifically. Doing
that first, before knowing which phase to look at, wastes the session.
