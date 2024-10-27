import 'dart:convert';

import 'package:isar/isar.dart';
import '../../../utilities/logger.dart';
import '../../isar/models/wallet_info.dart';

extension MimblewimblecoinWalletInfoExtension on WalletInfo {
  ExtraMimblewimblecoinWalletInfo? get mimblewimblecoinData {
    final String? data =
        otherData[WalletInfoKeys.mimblewimblecoinData] as String?;
    if (data == null) {
      return null;
    }
    try {
      return ExtraMimblewimblecoinWalletInfo.fromMap(
        Map<String, dynamic>.from(
          jsonDecode(data) as Map,
        ),
      );
    } catch (e, s) {
      Logging.instance.log(
        "ExtraMimblewimblecoinWalletInfo.fromMap failed: $e\n$s",
        level: LogLevel.Error,
      );
      return null;
    }
  }

  Future<void> updateExtraMimblewimblecoinWalletInfo({
    required ExtraMimblewimblecoinWalletInfo mimblewimblecoinData,
    required Isar isar,
  }) async {
    await updateOtherData(
      newEntries: {
        WalletInfoKeys.mimblewimblecoinData: jsonEncode(mimblewimblecoinData.toMap()),
      },
      isar: isar,
    );
  }
}

/// Holds data previously stored in hive
class ExtraMimblewimblecoinWalletInfo {
  final int receivingIndex;
  final int changeIndex;

  // TODO [prio=low] strongly type these maps at some point
  final Map<dynamic, dynamic> slatesToAddresses;
  final Map<dynamic, dynamic> slatesToCommits;

  final int lastScannedBlock;
  final int restoreHeight;
  final int creationHeight;

  ExtraMimblewimblecoinWalletInfo({
    required this.receivingIndex,
    required this.changeIndex,
    required this.slatesToAddresses,
    required this.slatesToCommits,
    required this.lastScannedBlock,
    required this.restoreHeight,
    required this.creationHeight,
  });

  // Convert the object to JSON
  Map<String, dynamic> toMap() {
    return {
      'receivingIndex': receivingIndex,
      'changeIndex': changeIndex,
      'slatesToAddresses': slatesToAddresses,
      'slatesToCommits': slatesToCommits,
      'lastScannedBlock': lastScannedBlock,
      'restoreHeight': restoreHeight,
      'creationHeight': creationHeight,
    };
  }

  ExtraMimblewimblecoinWalletInfo.fromMap(Map<String, dynamic> json)
      : receivingIndex = json['receivingIndex'] as int,
        changeIndex = json['changeIndex'] as int,
        slatesToAddresses = json['slatesToAddresses'] as Map,
        slatesToCommits = json['slatesToCommits'] as Map,
        lastScannedBlock = json['lastScannedBlock'] as int,
        restoreHeight = json['restoreHeight'] as int,
        creationHeight = json['creationHeight'] as int;

  ExtraMimblewimblecoinWalletInfo copyWith({
    int? receivingIndex,
    int? changeIndex,
    Map<dynamic, dynamic>? slatesToAddresses,
    Map<dynamic, dynamic>? slatesToCommits,
    int? lastScannedBlock,
    int? restoreHeight,
    int? creationHeight,
  }) {
    return ExtraMimblewimblecoinWalletInfo(
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
