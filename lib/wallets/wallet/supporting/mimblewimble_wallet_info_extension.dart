import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../../utilities/logger.dart';
import '../../isar/models/wallet_info.dart';

extension MimblewimbleWalletInfoExtension on WalletInfo {
  /// [key] is the [WalletInfoKeys] entry the coin keeps its data under.
  ExtraMimblewimbleWalletInfo? mimblewimbleData(String key) {
    final String? data = otherData[key] as String?;
    if (data == null) {
      return null;
    }
    try {
      return ExtraMimblewimbleWalletInfo.fromMap(
        Map<String, dynamic>.from(jsonDecode(data) as Map),
      );
    } catch (e, s) {
      Logging.instance.e(
        "ExtraMimblewimbleWalletInfo.fromMap failed: ",
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<void> updateMimblewimbleData({
    required String key,
    required ExtraMimblewimbleWalletInfo data,
    required Isar isar,
  }) async {
    await updateOtherData(
      newEntries: <String, dynamic>{key: jsonEncode(data.toMap())},
      isar: isar,
    );
  }
}

/// Holds data previously stored in hive
class ExtraMimblewimbleWalletInfo {
  final int receivingIndex;
  final int changeIndex;

  // TODO [prio=low] strongly type these maps at some point
  final Map<dynamic, dynamic> slatesToAddresses;
  final Map<dynamic, dynamic> slatesToCommits;

  final int lastScannedBlock;
  final int restoreHeight;
  final int creationHeight;

  ExtraMimblewimbleWalletInfo({
    required this.receivingIndex,
    required this.changeIndex,
    required this.slatesToAddresses,
    required this.slatesToCommits,
    required this.lastScannedBlock,
    required this.restoreHeight,
    required this.creationHeight,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'receivingIndex': receivingIndex,
      'changeIndex': changeIndex,
      'slatesToAddresses': slatesToAddresses,
      'slatesToCommits': slatesToCommits,
      'lastScannedBlock': lastScannedBlock,
      'restoreHeight': restoreHeight,
      'creationHeight': creationHeight,
    };
  }

  ExtraMimblewimbleWalletInfo.fromMap(Map<String, dynamic> json)
    : receivingIndex = json['receivingIndex'] as int,
      changeIndex = json['changeIndex'] as int,
      slatesToAddresses = json['slatesToAddresses'] as Map,
      slatesToCommits = json['slatesToCommits'] as Map,
      lastScannedBlock = json['lastScannedBlock'] as int,
      restoreHeight = json['restoreHeight'] as int,
      creationHeight = json['creationHeight'] as int;

  ExtraMimblewimbleWalletInfo copyWith({
    int? receivingIndex,
    int? changeIndex,
    Map<dynamic, dynamic>? slatesToAddresses,
    Map<dynamic, dynamic>? slatesToCommits,
    int? lastScannedBlock,
    int? restoreHeight,
    int? creationHeight,
  }) {
    return ExtraMimblewimbleWalletInfo(
      receivingIndex: receivingIndex ?? this.receivingIndex,
      changeIndex: changeIndex ?? this.changeIndex,
      slatesToAddresses: slatesToAddresses ?? this.slatesToAddresses,
      slatesToCommits: slatesToCommits ?? this.slatesToCommits,
      lastScannedBlock: lastScannedBlock ?? this.lastScannedBlock,
      restoreHeight: restoreHeight ?? this.restoreHeight,
      creationHeight: creationHeight ?? this.creationHeight,
    );
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
