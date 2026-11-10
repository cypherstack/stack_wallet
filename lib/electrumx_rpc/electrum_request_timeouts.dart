/// Response limits shared by individual and batched Electrum requests.
class ElectrumRequestTimeouts {
  const ElectrumRequestTimeouts({
    this.standard = const Duration(seconds: 60),
    this.history = const Duration(minutes: 5),
    this.firoSet = const Duration(minutes: 2),
  });

  final Duration standard;
  final Duration history;
  final Duration firoSet;

  Duration forMethod(String method) => switch (method) {
    'blockchain.scripthash.get_history' => history,
    'lelantus.getanonymityset' ||
    'lelantus.getusedcoinserials' ||
    'spark.getusedcoinstags' ||
    'spark.getusedcoinstagstxhashes' ||
    'spark.getsparkanonymityset' ||
    'spark.getsparkanonymitysetsector' => firoSet,
    _ => standard,
  };
}
