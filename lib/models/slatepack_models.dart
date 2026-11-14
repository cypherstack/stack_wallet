import '../utilities/amount/amount.dart';

/// Where a slate is in its round trip. S is a standard send, I an invoice.
enum SlateState {
  s1("S1"),
  s2("S2"),
  s3("S3"),
  i1("I1"),
  i2("I2"),
  i3("I3"),
  unknown("Unknown");

  const SlateState(this.code);

  /// "S1", "I2" and so on, as libwallet names them.
  final String code;

  bool get isInvoice => this == i1 || this == i2 || this == i3;

  static SlateState fromCode(String? code) {
    final upper = code?.trim().toUpperCase();
    return values.firstWhere((e) => e.code == upper, orElse: () => unknown);
  }
}

/// What a wallet can tell about a slatepack without acting on it.
class SlateInspection {
  const SlateInspection({
    required this.state,
    required this.slateId,
    this.amount,
    this.fee,
    this.senderAddress,
    this.recipientAddress,
    this.isEncrypted = false,
    this.ttlCutoffHeight,
  });

  final SlateState state;
  final String slateId;

  /// Null when the slate does not carry it. Grin's S2 and I2 decode with 0;
  /// look the amount up with localTxForSlate instead.
  final Amount? amount;
  final Amount? fee;
  final String? senderAddress;
  final String? recipientAddress;
  final bool isEncrypted;
  final int? ttlCutoffHeight;

  @override
  String toString() {
    return "SlateInspection("
        "state: ${state.code}, "
        "slateId: $slateId, "
        "amount: $amount, "
        "fee: $fee, "
        "senderAddress: $senderAddress, "
        "recipientAddress: $recipientAddress, "
        "isEncrypted: $isEncrypted, "
        "ttlCutoffHeight: $ttlCutoffHeight"
        ")";
  }
}

class SlatepackResult {
  final bool success;
  final String? error;
  final String? slatepack;
  final String? slateJson;
  final bool? wasEncrypted;
  final String? recipientAddress;
  final SlateState state;
  final String? slateId;
  final Amount? amount;
  final Amount? fee;

  SlatepackResult({
    required this.success,
    this.error,
    this.slatepack,
    this.slateJson,
    this.wasEncrypted,
    this.recipientAddress,
    this.state = SlateState.unknown,
    this.slateId,
    this.amount,
    this.fee,
  });

  @override
  String toString() {
    return "SlatepackResult("
        "success: $success, "
        "error: $error, "
        "slatepack: $slatepack, "
        "slateJson: $slateJson, "
        "wasEncrypted: $wasEncrypted, "
        "recipientAddress: $recipientAddress, "
        "state: ${state.code}, "
        "slateId: $slateId, "
        "amount: $amount, "
        "fee: $fee"
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

class FinalizeResult {
  final bool success;
  final String? error;
  final String? slateId;
  final String? commitId;

  /// Whether the finalized transaction reached the node. Epic Cash and MWC
  /// always post on finalize.
  final bool posted;

  /// Null for Epic Cash and MWC.
  final String? kernelExcess;

  FinalizeResult({
    required this.success,
    this.error,
    this.slateId,
    this.commitId,
    this.posted = false,
    this.kernelExcess,
  });

  @override
  String toString() {
    return "FinalizeResult("
        "success: $success, "
        "error: $error, "
        "slateId: $slateId, "
        "commitId: $commitId, "
        "posted: $posted, "
        "kernelExcess: $kernelExcess"
        ")";
  }
}
