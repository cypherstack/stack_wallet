/// Response limits shared by individual and batched Electrum requests.
class ElectrumRequestTimeouts {
  const ElectrumRequestTimeouts({
    this.standard = const Duration(seconds: 60),
    this.history = const Duration(minutes: 5),
    this.transactionBatch = const Duration(minutes: 5),
    this.firoSet = const Duration(hours: 3),
    this.broadcast = const Duration(minutes: 5),
  });

  final Duration standard;
  final Duration history;

  /// Deadline for the combined response to a verbose transaction batch.
  final Duration transactionBatch;

  /// Deadline for a Firo set download. The full Spark used-tag set alone is
  /// tens of megabytes and arrives as one response, so this is long enough
  /// for very slow connections to finish it.
  final Duration firoSet;
  final Duration broadcast;

  Duration forMethod(String method) => switch (method) {
    'blockchain.scripthash.get_history' => history,
    'blockchain.transaction.broadcast' => broadcast,
    'lelantus.getanonymityset' ||
    'lelantus.getusedcoinserials' ||
    'spark.getusedcoinstags' ||
    'spark.getusedcoinstagstxhashes' ||
    'spark.getsparkanonymityset' ||
    'spark.getsparkanonymitysetsector' => firoSet,
    _ => standard,
  };
}
