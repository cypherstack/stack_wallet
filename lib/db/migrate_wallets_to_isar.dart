import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/supporting/epiccash_wallet_info_extension.dart';

Future<void> migrateWalletsToIsar({
  required SecureStorageInterface secureStore,
}) async {
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

  final List<WalletInfo> newInfo = [];

  //
  // Convert each old info into the new Isar WalletInfo
  //
  for (final old in oldInfo) {
    final walletBox = await Hive.openBox<dynamic>(old.walletId);

    //
    // Set other data values
    //
    Map<String, dynamic> otherData = {};

    otherData[WalletInfoKeys.cachedSecondaryBalance] = walletBox.get(
      DBKeys.cachedBalanceSecondary,
    ) as String?;

    otherData[WalletInfoKeys.tokenContractAddresses] = walletBox.get(
      DBKeys.ethTokenContracts,
    ) as List<String>?;

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

    final info = WalletInfo(
      coinName: old.coin.name,
      walletId: old.walletId,
      name: old.name,
      walletType: _walletTypeForCoin(old.coin),
      mainAddressType: _addressTypeForCoin(old.coin),
      favouriteOrderIndex: favourites.indexOf(old.walletId),
      isMnemonicVerified: allWalletsBox
              .get("${old.walletId}_mnemonicHasBeenVerified") as bool? ??
          false,
      cachedChainHeight: walletBox.get(
            DBKeys.storedChainHeight,
          ) as int? ??
          0,
      cachedBalanceString: walletBox.get(
        DBKeys.cachedBalance,
      ) as String?,
      otherDataJsonString: jsonEncode(otherData),
    );

    newInfo.add(info);
  }

  await MainDB.instance.isar.writeTxn(() async {
    await MainDB.instance.isar.walletInfo.putAll(newInfo);
  });

  await _cleanupOnSuccess(walletIds: newInfo.map((e) => e.walletId).toList());
}

Future<void> _cleanupOnSuccess({required List<String> walletIds}) async {
  await Hive.deleteBoxFromDisk(DB.boxNameFavoriteWallets);
  await Hive.deleteBoxFromDisk(DB.boxNameAllWalletsData);
  for (final walletId in walletIds) {
    await Hive.deleteBoxFromDisk(walletId);
  }
}

WalletType _walletTypeForCoin(Coin coin) {
  WalletType walletType;
  switch (coin) {
    case Coin.bitcoin:
    case Coin.bitcoinTestNet:
    case Coin.bitcoincash:
    case Coin.bitcoincashTestnet:
    case Coin.litecoin:
    case Coin.dogecoin:
    case Coin.firo:
    case Coin.namecoin:
    case Coin.particl:
    case Coin.litecoinTestNet:
    case Coin.firoTestNet:
    case Coin.dogecoinTestNet:
    case Coin.eCash:
      walletType = WalletType.bip39HD;
      break;

    case Coin.monero:
    case Coin.wownero:
      walletType = WalletType.cryptonote;
      break;

    case Coin.epicCash:
    case Coin.ethereum:
    case Coin.tezos:
    case Coin.nano:
    case Coin.banano:
    case Coin.stellar:
    case Coin.stellarTestnet:
      walletType = WalletType.bip39;
      break;
  }

  return walletType;
}

AddressType _addressTypeForCoin(Coin coin) {
  AddressType addressType;
  switch (coin) {
    case Coin.bitcoin:
    case Coin.bitcoinTestNet:
    case Coin.litecoin:
    case Coin.litecoinTestNet:
      addressType = AddressType.p2wpkh;
      break;

    case Coin.eCash:
    case Coin.bitcoincash:
    case Coin.bitcoincashTestnet:
    case Coin.dogecoin:
    case Coin.firo:
    case Coin.firoTestNet:
    case Coin.namecoin:
    case Coin.particl:
    case Coin.dogecoinTestNet:
      addressType = AddressType.p2pkh;
      break;

    case Coin.monero:
    case Coin.wownero:
      addressType = AddressType.cryptonote;
      break;

    case Coin.epicCash:
      addressType = AddressType.mimbleWimble;
      break;

    case Coin.ethereum:
      addressType = AddressType.ethereum;
      break;

    case Coin.tezos:
      // should not be unknown but since already used in prod changing
      // this requires a migrate
      addressType = AddressType.unknown;
      break;

    case Coin.nano:
      addressType = AddressType.nano;
      break;

    case Coin.banano:
      addressType = AddressType.banano;
      break;

    case Coin.stellar:
    case Coin.stellarTestnet:
      // should not be unknown but since already used in prod changing
      // this requires a migrate
      addressType = AddressType.unknown;
      break;
  }

  return addressType;
}