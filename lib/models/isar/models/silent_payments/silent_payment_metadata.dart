import 'package:isar/isar.dart';
import '../../../../wallets/isar/isar_id_interface.dart';

part 'silent_payment_metadata.g.dart';

@Collection(accessor: "silentPaymentMetadata", inheritance: false)
class SilentPaymentMetadata implements IsarId {
  /// Primary key for this metadata entry.
  /// Should be generated as a sha256 hash of '$txid:$vout:$walletId'
  @override
  Id id;

  /// Private key tweak needed to spend this output
  final String tweak;

  /// This is not a user-defined label but a cryptographic tag
  /// that affects key derivation
  final String? label;

  SilentPaymentMetadata({required this.id, required this.tweak, this.label});

  SilentPaymentMetadata copyWith({int? id, String? tweak, String? label}) {
    return SilentPaymentMetadata(
      id: id ?? this.id,
      tweak: tweak ?? this.tweak,
      label: label ?? this.label,
    );
  }
}
