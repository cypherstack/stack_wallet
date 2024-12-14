class SparkMempoolData {
  final String txid;
  final List<String> serialContext;
  final List<String> lTags;
  final List<String> coins;

  SparkMempoolData({
    required this.txid,
    required this.serialContext,
    required this.lTags,
    required this.coins,
  });

  @override
  String toString() {
    return "SparkMempoolData{"
        "txid: $txid, "
        "serialContext: $serialContext, "
        "lTags: $lTags, "
        "coins: $coins"
        "}";
  }
}

class SparkAnonymitySetMeta {
  final int coinGroupId;
  final String blockHash;
  final String setHash;
  final int size;

  SparkAnonymitySetMeta({
    required this.coinGroupId,
    required this.blockHash,
    required this.setHash,
    required this.size,
  });

  @override
  String toString() {
    return "SparkAnonymitySetMeta{"
        "coinGroupId: $coinGroupId, "
        "blockHash: $blockHash, "
        "setHash: $setHash, "
        "size: $size"
        "}";
  }
}
