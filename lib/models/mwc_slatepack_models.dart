class SlatepackResult {
  final bool success;
  final String? error;
  final String? slatepack;
  final String? slateJson;
  final bool? wasEncrypted;
  final String? recipientAddress;

  SlatepackResult({
    required this.success,
    this.error,
    this.slatepack,
    this.slateJson,
    this.wasEncrypted,
    this.recipientAddress,
  });

  @override
  String toString() {
    return "SlatepackResult("
        "success: $success, "
        "error: $error, "
        "slatepack: $slatepack, "
        "slateJson: $slateJson, "
        "wasEncrypted: $wasEncrypted, "
        "recipientAddress: $recipientAddress"
        ")";
  }
}

class SlatepackDecodeResult {
  final bool success;
  final String? error;
  final String? slateJson;
  final bool? wasEncrypted;
  final String? senderAddress;
  final String? recipientAddress;

  SlatepackDecodeResult({
    required this.success,
    this.error,
    this.slateJson,
    this.wasEncrypted,
    this.senderAddress,
    this.recipientAddress,
  });

  @override
  String toString() {
    return "SlatepackDecodeResult("
        "success: $success, "
        "error: $error, "
        "slateJson: $slateJson, "
        "wasEncrypted: $wasEncrypted, "
        "senderAddress: $senderAddress, "
        "recipientAddress: $recipientAddress"
        ")";
  }
}

class ReceiveResult {
  final bool success;
  final String? error;
  final String? slateId;
  final String? commitId;
  final String? responseSlatepack;
  final bool? wasEncrypted;
  final String? recipientAddress;

  ReceiveResult({
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
    return "ReceiveResult("
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

class FinalizeResult {
  final bool success;
  final String? error;
  final String? slateId;
  final String? commitId;

  FinalizeResult({
    required this.success,
    this.error,
    this.slateId,
    this.commitId,
  });

  @override
  String toString() {
    return "FinalizeResult("
        "success: $success, "
        "error: $error, "
        "slateId: $slateId, "
        "commitId: $commitId"
        ")";
  }
}
