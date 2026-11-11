/// Response limits shared by individual and batched Electrum requests.
class ElectrumRequestTimeouts {
  const ElectrumRequestTimeouts({
    this.standard = const Duration(seconds: 60),
    this.history = const Duration(minutes: 5),
    this.firoSet = const Duration(minutes: 2),
    this.broadcast = const Duration(minutes: 5),
  });

  final Duration standard;
  final Duration history;
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
