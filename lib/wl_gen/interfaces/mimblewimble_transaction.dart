import 'dart:math';

class MimblewimbleTransaction {
  final String parentKeyId;
  final int id;
  final String? txSlateId;
  final Enum txType;
  final String creationTs;
  final String confirmationTs;
  final bool confirmed;
  final int numInputs;
  final int numOutputs;
  final String amountCredited;
  final String amountDebited;
  final String? fee;
  final String? ttlCutoffHeight;
  final List<MimblewimbleMessage>? messages;
  final String? storedTx;
  final String? kernelExcess;
  final int? kernelLookupMinHeight;
  final String? paymentProof;

  MimblewimbleTransaction({
    required this.parentKeyId,
    required this.id,
    this.txSlateId,
    required this.txType,
    required this.creationTs,
    required this.confirmationTs,
    required this.confirmed,
    required this.numInputs,
    required this.numOutputs,
    required this.amountCredited,
    required this.amountDebited,
    this.fee,
    this.ttlCutoffHeight,
    this.messages,
    this.storedTx,
    this.kernelExcess,
    this.kernelLookupMinHeight,
    this.paymentProof,
  });

  /// The first participant message that has text. The plugins turn a
  /// missing message into the string "null", and on a send the first entry
  /// can belong to the other party.
  String? get onChainNote {
    for (final m in messages ?? const <MimblewimbleMessage>[]) {
      final String? text = m.message;
      if (text != null && text.isNotEmpty && text != "null") {
        return text;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'MimblewimbleTransaction('
        'id: $id, '
        'txSlateId: $txSlateId, '
        'type: $txType, '
        'confirmed: $confirmed, '
        'inputs: $numInputs, '
        'outputs: $numOutputs, '
        'credited: $amountCredited, '
        'debited: $amountDebited, '
        'fee: $fee, '
        'created: $creationTs, '
        'confirmed: $confirmationTs, '
        'messages: ${messages?.length ?? 0}'
        ')';
  }
}

class MimblewimbleMessage {
  final String id;
  final String publicKey;
  final String? message;
  final String? messageSig;

  MimblewimbleMessage({
    required this.id,
    required this.publicKey,
    this.message,
    this.messageSig,
  });

  @override
  String toString() {
    final preview = message == null
        ? 'null'
        : '"${message!.substring(0, min(20, message!.length))}..."';
    return 'MimblewimbleMessage('
        'id: $id, '
        'publicKey: ${publicKey.substring(0, 8)}..., '
        'message: $preview'
        ')';
  }
}
