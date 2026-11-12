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

/// What the confirm screen has to ask, or refuse, before a direct send.
class SlatepackHttpPolicy {
  const SlatepackHttpPolicy({
    this.blockedReason,
    this.needsClearnetAck = false,
    this.needsPlaintextAck = false,
  });

  /// Set when the send cannot go ahead now. Shown to the user.
  final String? blockedReason;

  /// The target is reached without Tor and learns the user's IP address.
  final bool needsClearnetAck;

  /// The target is a plain http:// URL, readable on the way (also by a Tor
  /// exit).
  final bool needsPlaintextAck;

  bool get isBlocked => blockedReason != null;
}

/// Slatepack details of a stored transaction, for the details screen.
class SlatepackTxInfo {
  const SlatepackTxInfo({
    this.state = SlateState.unknown,
    this.slateId,
    this.kernelExcess,
    this.counterpartyAddress,
    this.ttlCutoffHeight,
    this.finalizedAwaitingConfirmation = false,
    this.canRepost = false,
    this.canShowSlatepack = false,
    this.hasPaymentProof = false,
  });

  /// The last state the wallet saw.
  final SlateState state;
  final String? slateId;
  final String? kernelExcess;
  final String? counterpartyAddress;
  final int? ttlCutoffHeight;

  /// Finalized and stored but not seen on chain yet.
  final bool finalizedAwaitingConfirmation;

  final bool canRepost;

  /// The wallet still has the slatepack the other party needs.
  final bool canShowSlatepack;

  final bool hasPaymentProof;
}

/// The texts of the dialog that asks before a slatepack transaction is
/// cancelled.
class SlatepackCancelPrompt {
  const SlatepackCancelPrompt({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;

  /// What cancelling does depends on what the other party already holds.
  /// [info] is null for wallets that keep no slate state; [incoming] is the
  /// direction of the transaction.
  factory SlatepackCancelPrompt.of(
    SlatepackTxInfo? info, {
    required bool incoming,
  }) {
    if (info?.finalizedAwaitingConfirmation ?? false) {
      return const SlatepackCancelPrompt(
        title: "Cancel a finalized transaction?",
        message:
            "This transaction is finalized and may still reach the chain, "
            "for example if the other party or a node posts it. Cancelling "
            "unlocks the funds in this wallet only. If it confirms later "
            "the wallet shows it again. Try Repost first if it is stuck.",
        confirmLabel: "Cancel anyway",
      );
    }
    final state = info?.state ?? SlateState.unknown;
    final String message;
    if (state == SlateState.i2) {
      // An invoice this wallet paid: the payee finalizes alone.
      message =
          "Cancelling changes this wallet only: the funds it locked become "
          "spendable here again. If the payee already has your payment, "
          "they can still complete it until those funds are spent in "
          "another transaction.";
    } else if (state == SlateState.s2 ||
        (state == SlateState.unknown && incoming)) {
      // A payment this wallet answered: the sender finalizes alone.
      message =
          "Cancelling removes this transaction from this wallet only. If "
          "the sender already has your response, they can still complete "
          "the payment, and the funds may then only show after a rescan.";
    } else {
      // This wallet has to finalize, and will not after a cancel.
      message =
          "The other party can no longer complete it, and any funds it "
          "locked become spendable again.";
    }
    return SlatepackCancelPrompt(
      title: "Cancel this transaction?",
      message: message,
      confirmLabel: "Yes, cancel",
    );
  }
}

/// A checked payment proof.
class PaymentProofCheck {
  const PaymentProofCheck({
    required this.amount,
    required this.kernelExcess,
    required this.senderAddress,
    required this.recipientAddress,
    required this.isSender,
    required this.isRecipient,
  });

  final Amount amount;
  final String kernelExcess;
  final String senderAddress;
  final String recipientAddress;

  /// This wallet's address is the proof's sender.
  final bool isSender;

  /// This wallet's address is the proof's recipient.
  final bool isRecipient;
}
