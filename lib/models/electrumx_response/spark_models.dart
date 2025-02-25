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

class RawSparkCoin {
  final String serialized;
  final String txHash;
  final String context;
  final int groupId;

  RawSparkCoin({
    required this.serialized,
    required this.txHash,
    required this.context,
    required this.groupId,
  });

  static RawSparkCoin fromRPCResponse(List<dynamic> data, int groupId) {
    try {
      if (data.length != 3) throw Exception();
      return RawSparkCoin(
        serialized: data[0] as String,
        txHash: data[1] as String,
        context: data[2] as String,
        groupId: groupId,
      );
    } catch (_) {
      throw Exception("Invalid coin data: $data");
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RawSparkCoin) return false;
    return serialized == other.serialized &&
        txHash == other.txHash &&
        groupId == other.groupId &&
        context == other.context;
  }

  @override
  int get hashCode => Object.hash(serialized, txHash, context);

  @override
  String toString() {
    return "SparkAnonymitySetMeta{"
        "serialized: $serialized, "
        "txHash: $txHash, "
        "context: $context, "
        "groupId: $groupId"
        "}";
  }
}
