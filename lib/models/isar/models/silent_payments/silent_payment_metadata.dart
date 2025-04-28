import 'package:isar/isar.dart';
import '../../../../wallets/isar/isar_id_interface.dart';

part 'silent_payment_metadata.g.dart';

@Collection(accessor: "silentPaymentMetadata", inheritance: false)
class SilentPaymentMetadata implements IsarId {
  @override
  Id id = Isar.autoIncrement;

  // Link to the UTXO this metadata is associated with
  @Index(unique: true)
  final int utxoId;

  // The wallet ID for efficient querying
  @Index()
  final String walletId;

  // Private key tweak needed to spend this output
  final String privKeyTweak;

  // Optional label for the silent payment
  final String? label;

  // Shared secret used to derive this output (optional - for reference only)
  final String? sharedSecret;

  // Output index in the set of outputs derived from the same shared secret
  final int outputIndex;

  SilentPaymentMetadata({
    required this.utxoId,
    required this.walletId,
    required this.privKeyTweak,
    required this.outputIndex,
    this.label,
    this.sharedSecret,
  });

  SilentPaymentMetadata copyWith({
    int? utxoId,
    String? walletId,
    String? privKeyTweak,
    int? outputIndex,
    String? label,
    String? sharedSecret,
  }) {
    return SilentPaymentMetadata(
      utxoId: utxoId ?? this.utxoId,
      walletId: walletId ?? this.walletId,
      privKeyTweak: privKeyTweak ?? this.privKeyTweak,
      outputIndex: outputIndex ?? this.outputIndex,
      label: label ?? this.label,
      sharedSecret: sharedSecret ?? this.sharedSecret,
    )..id = id;
  }

  Future<void> updateLabel({
    required Isar isar,
    required String? newLabel,
  }) async {
    final thisMetadata = await isar.silentPaymentMetadata.get(id) ?? this;

    if (thisMetadata.label != newLabel) {
      await isar.writeTxn(() async {
        await isar.silentPaymentMetadata.put(
          thisMetadata.copyWith(label: newLabel),
        );
      });
    }
  }
}
