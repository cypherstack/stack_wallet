// NOTE: might delete later to use config instead

import 'dart:convert';

import 'package:isar/isar.dart';
import '../../../../wallets/isar/isar_id_interface.dart';

part 'silent_payment_data.g.dart';

@Collection(accessor: "silentPaymentData", inheritance: false)
class SilentPaymentData implements IsarId {
  @override
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  final String walletId;

  // Whether this wallet has silent payments scanning enabled
  final bool isEnabled;

  // The last block height scanned for silent payments
  final int lastScannedHeight;

  // Store any additional data as JSON
  final String? metadataJsonString;

  // Convenience getters
  @ignore
  Map<String, dynamic> get metadata =>
      metadataJsonString == null
          ? {}
          : Map<String, dynamic>.from(jsonDecode(metadataJsonString!) as Map);

  SilentPaymentData({
    required this.walletId,
    this.isEnabled = false,
    this.lastScannedHeight = 0,
    this.metadataJsonString,
  });

  // Modification methods
  SilentPaymentData copyWith({
    bool? isEnabled,
    int? lastScannedHeight,
    String? metadataJsonString,
  }) {
    return SilentPaymentData(
      walletId: walletId,
      isEnabled: isEnabled ?? this.isEnabled,
      lastScannedHeight: lastScannedHeight ?? this.lastScannedHeight,
      metadataJsonString: metadataJsonString ?? this.metadataJsonString,
    )..id = id;
  }

  // Database update methods
  Future<void> updateEnabled({
    required bool enabled,
    required Isar isar,
  }) async {
    final data =
        await isar.silentPaymentData
            .where()
            .walletIdEqualTo(walletId)
            .findFirst() ??
        this;

    if (data.isEnabled != enabled) {
      await isar.writeTxn(() async {
        await isar.silentPaymentData.delete(data.id);
        await isar.silentPaymentData.put(data.copyWith(isEnabled: enabled));
      });
    }
  }

  // Similar methods for updating lastScannedHeight, etc.
}
