import 'logger.dart';

/// Times the phases of a wallet refresh and logs one line per refresh.
///
/// This exists to settle an argument with a measurement rather than an
/// impression. The wallet has been called slow, but the slowness was observed
/// on an atypical wallet, on an old handset, running a debug build, and a debug
/// Flutter build is several times slower than a release one for reasons that
/// have nothing to do with our code. Until the phases are timed on a release
/// build there is no way to tell whether the cost is Electrum round trips,
/// address discovery, local processing, or the build mode itself.
///
/// Deliberately cheap: a Stopwatch per phase and one log line at the end. It is
/// safe to leave enabled in a release build, which is the point. A measurement
/// you can only take in a special build is a measurement you will not take.
class SyncTrace {
  SyncTrace(this.label);

  /// Names the wallet or run so two traces cannot be confused in a log.
  final String label;

  final _total = Stopwatch();
  final _phases = <String, int>{};

  /// Set false to compile the timing out of a build entirely.
  static bool enabled = true;

  void start() {
    if (!enabled) return;
    _total.start();
  }

  /// Runs [body], recording how long it took under [phase].
  ///
  /// Phases that run more than once in a refresh accumulate, so the total for
  /// a phase is what that phase cost across the whole refresh rather than the
  /// last time it happened.
  Future<T> time<T>(String phase, Future<T> Function() body) async {
    if (!enabled) return body();

    final watch = Stopwatch()..start();
    try {
      return await body();
    } finally {
      watch.stop();
      _phases[phase] = (_phases[phase] ?? 0) + watch.elapsedMilliseconds;
    }
  }

  /// Emits the summary. Safe to call twice; the second call does nothing.
  void finish({int? transactions, int? utxos}) {
    if (!enabled || !_total.isRunning) return;

    _total.stop();

    final parts = _phases.entries.map((e) => "${e.key}=${e.value}ms").join(" ");

    // Counts matter as much as the timings. A refresh is expected to be slower
    // on a wallet with hundreds of outputs, and a duration without the size of
    // the thing it processed cannot be compared against another device.
    final size = [
      if (transactions != null) "txs=$transactions",
      if (utxos != null) "utxos=$utxos",
    ].join(" ");

    final line = "SYNCTRACE $label total=${_total.elapsedMilliseconds}ms "
        "$parts${size.isEmpty ? "" : " $size"}";

    // Logging already writes to the log file and the console, and the log file
    // is what gets pulled off a handset after a run.
    Logging.instance.i(line);
  }
}
