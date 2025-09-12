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
}

