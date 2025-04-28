import 'dart:convert';
import 'package:isar/isar.dart';
import '../../../../wallets/isar/isar_id_interface.dart';

part 'silent_payment_config.g.dart';

@Collection(accessor: "silentPaymentConfig", inheritance: false)
class SilentPaymentConfig implements IsarId {
  @override
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String walletId;

  final bool isEnabled;

  final int lastScannedHeight;

  // Store any computed labels for efficient lookup
  final String? labelMapJsonString;

  @ignore
  Map<String, String>? get labelMap =>
      labelMapJsonString == null
          ? null
          : Map<String, String>.from(jsonDecode(labelMapJsonString!) as Map);

  SilentPaymentConfig({
    required this.walletId,
    this.isEnabled = false,
    this.lastScannedHeight = 0,
    this.labelMapJsonString,
  });

  SilentPaymentConfig copyWith({
    bool? isEnabled,
    int? lastScannedHeight,
    String? labelMapJsonString,
  }) {
    return SilentPaymentConfig(
      walletId: walletId,
      isEnabled: isEnabled ?? this.isEnabled,
      lastScannedHeight: lastScannedHeight ?? this.lastScannedHeight,
      labelMapJsonString: labelMapJsonString ?? this.labelMapJsonString,
    )..id = id;
  }

  Future<void> updateEnabled({
    required bool enabled,
    required Isar isar,
  }) async {
    if (isEnabled != enabled) {
      await isar.writeTxn(() async {
        await isar.silentPaymentConfig.put(copyWith(isEnabled: enabled));
      });
    }
  }

  Future<void> updateLastScannedHeight({
    required int height,
    required Isar isar,
  }) async {
    if (lastScannedHeight != height) {
      await isar.writeTxn(() async {
        await isar.silentPaymentConfig.put(copyWith(lastScannedHeight: height));
      });
    }
  }

  Future<void> updateLabelMap({
    required Map<String, String> newLabelMap,
    required Isar isar,
  }) async {
    final encodedMap = jsonEncode(newLabelMap);

    if (labelMapJsonString != encodedMap) {
      await isar.writeTxn(() async {
        await isar.silentPaymentConfig.put(
          copyWith(labelMapJsonString: encodedMap),
        );
      });
    }
  }
}
