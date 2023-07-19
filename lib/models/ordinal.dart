enum OrdCollection {
  punks,
  moonbirds,
}

class Ordinal {
  final String name;
  final String inscription;
  final String rank;
  final OrdCollection collection;

  // following two are used to look up the UTXO object in isar combined w/ walletId
  final String utxoTXID;
  final int utxoVOUT;

  // TODO: make a proper Isar class instead of this placeholder

  Ordinal({
    required this.name,
    required this.inscription,
    required this.rank,
    required this.collection,
    required this.utxoTXID,
    required this.utxoVOUT,
  });
}
