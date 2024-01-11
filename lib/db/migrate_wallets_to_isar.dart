import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/wallets/isar/models/token_wallet_info.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info_meta.dart';
import 'package:stackwallet/wallets/wallet/supporting/epiccash_wallet_info_extension.dart';

Future<void> migrateWalletsToIsar({
  required SecureStorageInterface secureStore,
}) async {
  await MainDB.instance.initMainDB();
  final allWalletsBox = await Hive.openBox<dynamic>(DB.boxNameAllWalletsData);

  final names = DB.instance
      .get<dynamic>(boxName: DB.boxNameAllWalletsData, key: 'names') as Map?;

  if (names == null) {
    // no wallets to migrate
    return;
  }

  //
  // Parse the old data from the Hive map into a nice list
  //
  final List<
      ({
        Coin coin,
        String name,
        String walletId,
      })> oldInfo = Map<String, dynamic>.from(names).values.map((e) {
    final map = e as Map;
    return (
      coin: Coin.values.byName(map["coin"] as String),
      walletId: map["id"] as String,
      name: map["name"] as String,
    );
  }).toList();

  //
  // Get current ordered list of favourite wallet Ids
  //
  final List<String> favourites =
      (await Hive.openBox<String>(DB.boxNameFavoriteWallets)).values.toList();

  final List<(WalletInfo, WalletInfoMeta)> newInfo = [];
  final List<TokenWalletInfo> tokenInfo = [];
  final List<TransactionNote> migratedNotes = [];

  //
  // Convert each old info into the new Isar WalletInfo
  //
  for (final old in oldInfo) {
    final walletBox = await Hive.openBox<dynamic>(old.walletId);

    //
    // First handle transaction notes
    //
    final newNoteCount = await MainDB.instance.isar.transactionNotes
        .where()
        .walletIdEqualTo(old.walletId)
        .count();
    if (newNoteCount == 0) {
      final map = walletBox.get('notes') as Map?;

      if (map != null) {
        final notes = Map<String, String>.from(map);

        for (final txid in notes.keys) {
          final note = notes[txid];
          if (note != null && note.isNotEmpty) {
            final newNote = TransactionNote(
              walletId: old.walletId,
              txid: txid,
              value: note,
            );
            migratedNotes.add(newNote);
          }
        }
      }
    }

    // reset stellar address type
    if (old.coin == Coin.stellar || old.coin == Coin.stellarTestnet) {
      await MainDB.instance.deleteWalletBlockchainData(old.walletId);
    }

    //
    // Set other data values
    //
    Map<String, dynamic> otherData = {};

    final List<String>? tokenContractAddresses = walletBox.get(
      "ethTokenContracts",
    ) as List<String>?;

    if (tokenContractAddresses?.isNotEmpty == true) {
      otherData[WalletInfoKeys.tokenContractAddresses] = tokenContractAddresses;

      for (final address in tokenContractAddresses!) {
        final contract = await MainDB.instance.isar.ethContracts
            .where()
            .addressEqualTo(address)
            .findFirst();
        if (contract != null) {
          tokenInfo.add(
            TokenWalletInfo(
              walletId: old.walletId,
              tokenAddress: address,
              tokenFractionDigits: contract.decimals,
            ),
          );
        }
      }
    }

    // epiccash specifics
    if (old.coin == Coin.epicCash) {
      final epicWalletInfo = ExtraEpiccashWalletInfo.fromMap({
        "receivingIndex": walletBox.get("receivingIndex") as int? ?? 0,
        "changeIndex": walletBox.get("changeIndex") as int? ?? 0,
        "slatesToAddresses": walletBox.get("slate_to_address") as Map? ?? {},
        "slatesToCommits": walletBox.get("slatesToCommits") as Map? ?? {},
        "lastScannedBlock": walletBox.get("lastScannedBlock") as int? ?? 0,
        "restoreHeight": walletBox.get("restoreHeight") as int? ?? 0,
        "creationHeight": walletBox.get("creationHeight") as int? ?? 0,
      });
      otherData[WalletInfoKeys.epiccashData] = jsonEncode(
        epicWalletInfo.toMap(),
      );
    }

    //
    // Clear out any keys with null values as they are not needed
    //
    otherData.removeWhere((key, value) => value == null);

    final infoMeta = WalletInfoMeta(
      walletId: old.walletId,
      isMnemonicVerified: allWalletsBox
              .get("${old.walletId}_mnemonicHasBeenVerified") as bool? ??
          false,
    );

    final info = WalletInfo(
      coinName: old.coin.name,
      walletId: old.walletId,
      name: old.name,
      mainAddressType: old.coin.primaryAddressType,
      favouriteOrderIndex: favourites.indexOf(old.walletId),
      cachedChainHeight: walletBox.get(
            DBKeys.storedChainHeight,
          ) as int? ??
          0,
      cachedBalanceString: walletBox.get(
        DBKeys.cachedBalance,
      ) as String?,
      cachedBalanceSecondaryString: walletBox.get(
        DBKeys.cachedBalanceSecondary,
      ) as String?,
      otherDataJsonString: jsonEncode(otherData),
    );

    newInfo.add((info, infoMeta));
  }

  if (migratedNotes.isNotEmpty) {
    await MainDB.instance.isar.writeTxn(() async {
      await MainDB.instance.isar.transactionNotes.putAll(migratedNotes);
    });
  }

  if (newInfo.isNotEmpty) {
    await MainDB.instance.isar.writeTxn(() async {
      await MainDB.instance.isar.walletInfo
          .putAll(newInfo.map((e) => e.$1).toList());
      await MainDB.instance.isar.walletInfoMeta
          .putAll(newInfo.map((e) => e.$2).toList());

      if (tokenInfo.isNotEmpty) {
        await MainDB.instance.isar.tokenWalletInfo.putAll(tokenInfo);
      }
    });
  }

  await _cleanupOnSuccess(
      walletIds: newInfo.map((e) => e.$1.walletId).toList());
}

Future<void> _cleanupOnSuccess({required List<String> walletIds}) async {
  await Hive.deleteBoxFromDisk(DB.boxNameFavoriteWallets);
  await Hive.deleteBoxFromDisk(DB.boxNameAllWalletsData);
  for (final walletId in walletIds) {
    await Hive.deleteBoxFromDisk(walletId);
  }
}
