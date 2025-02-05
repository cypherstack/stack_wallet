import 'dart:convert';

import 'package:isar/isar.dart';

import '../app_config.dart';
import '../models/isar/models/isar_models.dart';
import '../utilities/flutter_secure_storage_interface.dart';
import '../wallets/crypto_currency/crypto_currency.dart';
import '../wallets/isar/models/token_wallet_info.dart';
import '../wallets/isar/models/wallet_info.dart';
import '../wallets/isar/models/wallet_info_meta.dart';
import '../wallets/wallet/supporting/epiccash_wallet_info_extension.dart';
import 'hive/db.dart';
import 'isar/main_db.dart';

Future<void> migrateWalletsToIsar({
  required SecureStorageInterface secureStore,
}) async {
  await MainDB.instance.initMainDB();

  // ensure fresh
  await MainDB.instance.isar
      .writeTxn(() async => await MainDB.instance.isar.transactionV2s.clear());

  final allWalletsBox =
      await DB.instance.hive.openBox<dynamic>(DB.boxNameAllWalletsData);

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
        String coinIdentifier,
        String name,
        String walletId,
      })> oldInfo = Map<String, dynamic>.from(names).values.map((e) {
    final map = e as Map;
    return (
      coinIdentifier: map["coin"] as String,
      walletId: map["id"] as String,
      name: map["name"] as String,
    );
  }).toList();

  //
  // Get current ordered list of favourite wallet Ids
  //
  final List<String> favourites =
      (await DB.instance.hive.openBox<String>(DB.boxNameFavoriteWallets))
          .values
          .toList();

  final List<(WalletInfo, WalletInfoMeta)> newInfo = [];
  final List<TokenWalletInfo> tokenInfo = [];
  final List<TransactionNote> migratedNotes = [];

  //
  // Convert each old info into the new Isar WalletInfo
  //
  for (final old in oldInfo) {
    final walletBox = await DB.instance.hive.openBox<dynamic>(old.walletId);

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

    // reset stellar + tezos address type
    if (old.coinIdentifier == Stellar(CryptoCurrencyNetwork.main).identifier ||
        old.coinIdentifier == Stellar(CryptoCurrencyNetwork.test).identifier ||
        old.coinIdentifier == Tezos(CryptoCurrencyNetwork.main).identifier) {
      await MainDB.instance.deleteWalletBlockchainData(old.walletId);
    }

    //
    // Set other data values
    //
    final Map<String, dynamic> otherData = {};

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
    if (old.coinIdentifier == Epiccash(CryptoCurrencyNetwork.main)) {
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
    } else if (old.coinIdentifier ==
            Firo(CryptoCurrencyNetwork.main).identifier ||
        old.coinIdentifier == Firo(CryptoCurrencyNetwork.test).identifier) {
      otherData[WalletInfoKeys.lelantusCoinIsarRescanRequired] = walletBox
              .get(WalletInfoKeys.lelantusCoinIsarRescanRequired) as bool? ??
          true;
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
      coinName: old.coinIdentifier,
      walletId: old.walletId,
      name: old.name,
      mainAddressType: AppConfig.getCryptoCurrencyFor(old.coinIdentifier)!
          .defaultAddressType,
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
    walletIds: newInfo.map((e) => e.$1.walletId).toList(),
  );
}

Future<void> _cleanupOnSuccess({required List<String> walletIds}) async {
  await DB.instance.hive.deleteBoxFromDisk(DB.boxNameFavoriteWallets);
  await DB.instance.hive.deleteBoxFromDisk(DB.boxNameAllWalletsData);
  for (final walletId in walletIds) {
    await DB.instance.hive.deleteBoxFromDisk(walletId);
  }
}
