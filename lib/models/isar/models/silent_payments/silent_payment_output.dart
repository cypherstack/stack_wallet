// NOTE: might delete later to use metadata instead

import 'package:isar/isar.dart';
import '../../../../wallets/isar/isar_id_interface.dart';

part 'silent_payment_output.g.dart';

@Collection(accessor: "silentPaymentOutputs", inheritance: false)
class SilentPaymentOutput implements IsarId {
  @override
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('outputScript')])
  final String walletId;

  // The actual output script
  final String outputScript;

  // Amount in satoshis
  final int amount;

  // Transaction data
  final String txid;
  final int vout;

  // Block data
  final int blockHeight;
  final int blockTime;

  // Private key tweak needed to spend this output
  final String privKeyTweak;

  // Optional label
  final String? label;

  // Is this output spent
  final bool isSpent;

  // Additional fields that might be useful
  final String? spentTxid; // Transaction ID where this output was spent
  final int? spentBlockHeight; // Block height when it was spent
  final int? spentBlockTime; // Block timestamp when it was spent

  SilentPaymentOutput({
    required this.walletId,
    required this.outputScript,
    required this.amount,
    required this.txid,
    required this.vout,
    required this.blockHeight,
    required this.blockTime,
    required this.privKeyTweak,
    this.label,
    this.isSpent = false,
    this.spentTxid,
    this.spentBlockHeight,
    this.spentBlockTime,
  });

  // Copy with method for immutability
  SilentPaymentOutput copyWith({
    String? walletId,
    String? outputScript,
    int? amount,
    String? txid,
    int? vout,
    int? blockHeight,
    int? blockTime,
    String? privKeyTweak,
    String? label,
    bool? isSpent,
    String? spentTxid,
    int? spentBlockHeight,
    int? spentBlockTime,
  }) {
    return SilentPaymentOutput(
      walletId: walletId ?? this.walletId,
      outputScript: outputScript ?? this.outputScript,
      amount: amount ?? this.amount,
      txid: txid ?? this.txid,
      vout: vout ?? this.vout,
      blockHeight: blockHeight ?? this.blockHeight,
      blockTime: blockTime ?? this.blockTime,
      privKeyTweak: privKeyTweak ?? this.privKeyTweak,
      label: label ?? this.label,
      isSpent: isSpent ?? this.isSpent,
      spentTxid: spentTxid ?? this.spentTxid,
      spentBlockHeight: spentBlockHeight ?? this.spentBlockHeight,
      spentBlockTime: spentBlockTime ?? this.spentBlockTime,
    )..id = id;
  }

  // Mark this output as spent
  Future<void> markAsSpent({
    required Isar isar,
    required String spentInTxid,
    required int spentAtHeight,
    required int spentAtTime,
  }) async {
    final thisOutput = await isar.silentPaymentOutputs.get(id) ?? this;

    // Only update if not already marked as spent
    if (!thisOutput.isSpent) {
      await isar.writeTxn(() async {
        await isar.silentPaymentOutputs.delete(thisOutput.id);
        await isar.silentPaymentOutputs.put(
          thisOutput.copyWith(
            isSpent: true,
            spentTxid: spentInTxid,
            spentBlockHeight: spentAtHeight,
            spentBlockTime: spentAtTime,
          ),
        );
      });
    }
  }

  // Update the label of this output
  Future<void> updateLabel({
    required Isar isar,
    required String? newLabel,
  }) async {
    final thisOutput = await isar.silentPaymentOutputs.get(id) ?? this;

    // Only update if label is different
    if (thisOutput.label != newLabel) {
      await isar.writeTxn(() async {
        await isar.silentPaymentOutputs.delete(thisOutput.id);
        await isar.silentPaymentOutputs.put(
          thisOutput.copyWith(label: newLabel),
        );
      });
    }
  }

  // Check if this output matches a specific UTXO/outpoint
  bool matchesOutpoint(String checkTxid, int checkVout) {
    return txid == checkTxid && vout == checkVout;
  }

  // For convenience, create an outpoint string representation
  String get outpoint => "$txid:$vout";

  // Method to help calculate the effective age of the UTXO
  int get confirmations {
    // This would typically need the current block height,
    // so you might pass that in as a parameter
    final currentHeight = 0; // Replace with actual height
    return currentHeight - blockHeight + 1;
  }

  // Convenience getter for age in days (approximation)
  double get ageInDays {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (now - blockTime) / (60 * 60 * 24);
  }

  // Helper to detect if this output has been spent for a certain time
  bool get isConfirmedSpent {
    if (!isSpent || spentBlockHeight == null) return false;

    final currentHeight = 0; // Replace with actual height
    // Consider spent outputs confirmed after 6 blocks
    return currentHeight - spentBlockHeight! >= 6;
  }

  // For debugging or display purposes
  @override
  String toString() {
    return 'SilentPaymentOutput(id: $id, txid: $txid:$vout, amount: $amount sats, spent: $isSpent)';
  }
}
