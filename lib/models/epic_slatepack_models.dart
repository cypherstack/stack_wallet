class EpicSlatepackResult {
  final bool success;
  final String? error;
  final String? slatepack;
  final String? slateJson;
  final bool? wasEncrypted;
  final String? recipientAddress;

  EpicSlatepackResult({
    required this.success,
    this.error,
    this.slatepack,
    this.slateJson,
    this.wasEncrypted,
    this.recipientAddress,
  });

  @override
  String toString() {
    return "EpicSlatepackResult("
        "success: $success, "
        "error: $error, "
        "slatepack: $slatepack, "
        "slateJson: $slateJson, "
        "wasEncrypted: $wasEncrypted, "
        "recipientAddress: $recipientAddress"
        ")";
  }
}

class EpicSlatepackDecodeResult {
  final bool success;
  final String? error;
  final String? slateJson;
  final bool? wasEncrypted;
  final String? senderAddress;
  final String? recipientAddress;

  EpicSlatepackDecodeResult({
    required this.success,
    this.error,
    this.slateJson,
    this.wasEncrypted,
    this.senderAddress,
    this.recipientAddress,
  });

  @override
  String toString() {
    return "EpicSlatepackDecodeResult("
        "success: $success, "
        "error: $error, "
        "slateJson: $slateJson, "
        "wasEncrypted: $wasEncrypted, "
        "senderAddress: $senderAddress, "
        "recipientAddress: $recipientAddress"
        ")";
  }
}

class EpicReceiveResult {
  final bool success;
  final String? error;
  final String? slateId;
  final String? commitId;
  final String? responseSlatepack;
  final bool? wasEncrypted;
  final String? recipientAddress;

  EpicReceiveResult({
    required this.success,
    this.error,
    this.slateId,
    this.commitId,
    this.responseSlatepack,
    this.wasEncrypted,
    this.recipientAddress,
  });

  @override
  String toString() {
    return "EpicReceiveResult("
        "success: $success, "
        "error: $error, "
        "slateId: $slateId, "
        "commitId: $commitId, "
        "responseSlatepack: $responseSlatepack, "
        "wasEncrypted: $wasEncrypted, "
        "recipientAddress: $recipientAddress"
        ")";
  }
}

class EpicFinalizeResult {
  final bool success;
  final String? error;
  final String? slateId;
  final String? commitId;

  EpicFinalizeResult({
    required this.success,
    this.error,
    this.slateId,
    this.commitId,
  });

  @override
  String toString() {
    return "EpicFinalizeResult("
        "success: $success, "
        "error: $error, "
        "slateId: $slateId, "
        "commitId: $commitId"
        ")";
  }
}
