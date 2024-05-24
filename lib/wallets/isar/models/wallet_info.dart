import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../app_config.dart';
import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../isar_id_interface.dart';
import 'wallet_info_meta.dart';

part 'wallet_info.g.dart';

@Collection(accessor: "walletInfo", inheritance: false)
class WalletInfo implements IsarId {
  @override
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  final String walletId;

  final String name;

  @enumerated
  final AddressType mainAddressType;

  /// The highest index [mainAddressType] receiving address of the wallet
  final String cachedReceivingAddress;

  /// Only exposed for Isar. Use the [cachedBalance] getter.
  // Only exposed for isar as Amount cannot be stored in isar easily
  final String? cachedBalanceString;

  /// Only exposed for Isar. Use the [cachedBalanceSecondary] getter.
  // Only exposed for isar as Amount cannot be stored in isar easily
  final String? cachedBalanceSecondaryString;

  /// Only exposed for Isar. Use the [cachedBalanceTertiary] getter.
  // Only exposed for isar as Amount cannot be stored in isar easily
  final String? cachedBalanceTertiaryString;

  /// Only exposed for Isar. Use the [coin] getter.
  // Only exposed for isar to avoid dealing with storing enums as Coin can change
  final String coinName;

  /// User set favourites ordering. No restrictions are placed on uniqueness.
  /// Reordering logic in the ui code should ensure this is unique.
  ///
  /// Also represents if the wallet is a favourite. Any number greater then -1
  /// denotes a favourite. Any number less than 0 means it is not a favourite.
  final int favouriteOrderIndex;

  /// The highest block height the wallet has scanned.
  final int cachedChainHeight;

  /// The block at which this wallet was or should be restored from
  final int restoreHeight;

  final String? otherDataJsonString;

  //============================================================================
  //=============== Getters ====================================================

  bool get isFavourite => favouriteOrderIndex > -1;

  List<String> get tokenContractAddresses {
    if (otherData[WalletInfoKeys.tokenContractAddresses] is List) {
      return List<String>.from(
        otherData[WalletInfoKeys.tokenContractAddresses] as List,
      );
    } else {
      return [];
    }
  }

  /// Special case for coins such as firo lelantus
  @ignore
  Balance get cachedBalanceSecondary {
    if (cachedBalanceSecondaryString == null) {
      return Balance.zeroFor(currency: coin);
    } else {
      return Balance.fromJson(
          cachedBalanceSecondaryString!, coin.fractionDigits);
    }
  }

  /// Special case for coins such as firo spark
  @ignore
  Balance get cachedBalanceTertiary {
    if (cachedBalanceTertiaryString == null) {
      return Balance.zeroFor(currency: coin);
    } else {
      return Balance.fromJson(
          cachedBalanceTertiaryString!, coin.fractionDigits);
    }
  }

  @ignore
  CryptoCurrency get coin => AppConfig.getCryptoCurrencyFor(coinName)!;

  @ignore
  Balance get cachedBalance {
    if (cachedBalanceString == null) {
      return Balance.zeroFor(currency: coin);
    } else {
      return Balance.fromJson(cachedBalanceString!, coin.fractionDigits);
    }
  }

  @ignore
  Map<String, dynamic> get otherData => otherDataJsonString == null
      ? {}
      : Map<String, dynamic>.from(jsonDecode(otherDataJsonString!) as Map);

  Future<bool> isMnemonicVerified(Isar isar) async =>
      (await isar.walletInfoMeta.where().walletIdEqualTo(walletId).findFirst())
          ?.isMnemonicVerified ==
      true;

  //============================================================================
  //=============    Updaters   ================================================

  Future<void> updateBalance({
    required Balance newBalance,
    required Isar isar,
  }) async {
    // try to get latest instance of this from db
    final thisInfo = await isar.walletInfo.get(id) ?? this;

    final newEncoded = newBalance.toJsonIgnoreCoin();

    // only update if there were changes to the balance
    if (thisInfo.cachedBalanceString != newEncoded) {
      await isar.writeTxn(() async {
        await isar.walletInfo.delete(thisInfo.id);
        await isar.walletInfo.put(
          thisInfo.copyWith(
            cachedBalanceString: newEncoded,
          ),
        );
      });
    }
  }

  Future<void> updateBalanceSecondary({
    required Balance newBalance,
    required Isar isar,
  }) async {
    // try to get latest instance of this from db
    final thisInfo = await isar.walletInfo.get(id) ?? this;

    final newEncoded = newBalance.toJsonIgnoreCoin();

    // only update if there were changes to the balance
    if (thisInfo.cachedBalanceSecondaryString != newEncoded) {
      await isar.writeTxn(() async {
        await isar.walletInfo.delete(thisInfo.id);
        await isar.walletInfo.put(
          thisInfo.copyWith(
            cachedBalanceSecondaryString: newEncoded,
          ),
        );
      });
    }
  }

  Future<void> updateBalanceTertiary({
    required Balance newBalance,
    required Isar isar,
  }) async {
    // try to get latest instance of this from db
    final thisInfo = await isar.walletInfo.get(id) ?? this;

    final newEncoded = newBalance.toJsonIgnoreCoin();

    // only update if there were changes to the balance
    if (thisInfo.cachedBalanceTertiaryString != newEncoded) {
      await isar.writeTxn(() async {
        await isar.walletInfo.delete(thisInfo.id);
        await isar.walletInfo.put(
          thisInfo.copyWith(
            cachedBalanceTertiaryString: newEncoded,
          ),
        );
      });
    }
  }

  /// copies this with a new chain height and updates the db
  Future<void> updateCachedChainHeight({
    required int newHeight,
    required Isar isar,
  }) async {
    // try to get latest instance of this from db
    final thisInfo = await isar.walletInfo.get(id) ?? this;
    // only update if there were changes to the height
    if (thisInfo.cachedChainHeight != newHeight) {
      await isar.writeTxn(() async {
        await isar.walletInfo.delete(thisInfo.id);
        await isar.walletInfo.put(
          thisInfo.copyWith(
            cachedChainHeight: newHeight,
          ),
        );
      });
    }
  }

  /// update favourite wallet and its index it the ui list.
  /// When [customIndexOverride] is not null the [flag] will be ignored.
  Future<void> updateIsFavourite(
    bool flag, {
    required Isar isar,
    int? customIndexOverride,
  }) async {
    final int index;

    if (customIndexOverride != null) {
      index = customIndexOverride;
    } else if (flag) {
      final highest = await isar.walletInfo
          .where()
          .sortByFavouriteOrderIndexDesc()
          .favouriteOrderIndexProperty()
          .findFirst();
      index = (highest ?? 0) + 1;
    } else {
      index = -1;
    }

    // try to get latest instance of this from db
    final thisInfo = await isar.walletInfo.get(id) ?? this;

    // only update if there were changes to the height
    if (thisInfo.favouriteOrderIndex != index) {
      await isar.writeTxn(() async {
        await isar.walletInfo.delete(thisInfo.id);
        await isar.walletInfo.put(
          thisInfo.copyWith(
            favouriteOrderIndex: index,
          ),
        );
      });
    }
  }

  /// copies this with a new name and updates the db
  Future<void> updateName({
    required String newName,
    required Isar isar,
  }) async {
    // don't allow empty names
    if (newName.isEmpty) {
      throw Exception("Empty wallet name not allowed!");
    }

    // try to get latest instance of this from db
    final thisInfo = await isar.walletInfo.get(id) ?? this;

    // only update if there were changes to the name
    if (thisInfo.name != newName) {
      await isar.writeTxn(() async {
        await isar.walletInfo.delete(thisInfo.id);
        await isar.walletInfo.put(
          thisInfo.copyWith(
            name: newName,
          ),
        );
      });
    }
  }

  /// copies this with a new name and updates the db
  Future<void> updateReceivingAddress({
    required String newAddress,
    required Isar isar,
  }) async {
    // try to get latest instance of this from db
    final thisInfo = await isar.walletInfo.get(id) ?? this;
    // only update if there were changes to the name
    if (thisInfo.cachedReceivingAddress != newAddress) {
      await isar.writeTxn(() async {
        await isar.walletInfo.delete(thisInfo.id);
        await isar.walletInfo.put(
          thisInfo.copyWith(
            cachedReceivingAddress: newAddress,
          ),
        );
      });
    }
  }

  /// update [otherData] with the map entries in [newEntries]
  Future<void> updateOtherData({
    required Map<String, dynamic> newEntries,
    required Isar isar,
  }) async {
    // try to get latest instance of this from db
    final thisInfo = await isar.walletInfo.get(id) ?? this;

    final Map<String, dynamic> newMap = {};
    newMap.addAll(thisInfo.otherData);
    newMap.addAll(newEntries);
    final encodedNew = jsonEncode(newMap);

    // only update if there were changes
    if (thisInfo.otherDataJsonString != encodedNew) {
      await isar.writeTxn(() async {
        await isar.walletInfo.delete(thisInfo.id);
        await isar.walletInfo.put(
          thisInfo.copyWith(
            otherDataJsonString: encodedNew,
          ),
        );
      });
    }
  }

  /// Can be dangerous. Don't use unless you know the consequences
  Future<void> setMnemonicVerified({
    required Isar isar,
  }) async {
    final meta =
        await isar.walletInfoMeta.where().walletIdEqualTo(walletId).findFirst();
    if (meta == null) {
      await isar.writeTxn(() async {
        await isar.walletInfoMeta.put(
          WalletInfoMeta(
            walletId: walletId,
            isMnemonicVerified: true,
          ),
        );
      });
    } else if (meta.isMnemonicVerified == false) {
      await isar.writeTxn(() async {
        await isar.walletInfoMeta.deleteByWalletId(walletId);
        await isar.walletInfoMeta.put(
          WalletInfoMeta(
            walletId: walletId,
            isMnemonicVerified: true,
          ),
        );
      });
    } else {
      throw Exception(
        "setMnemonicVerified() called on already"
        " verified wallet: $name, $walletId",
      );
    }
  }

  /// copies this with a new name and updates the db
  Future<void> updateRestoreHeight({
    required int newRestoreHeight,
    required Isar isar,
  }) async {
    // don't allow empty names
    if (newRestoreHeight < 0) {
      throw Exception("Negative restore height not allowed!");
    }

    // try to get latest instance of this from db
    final thisInfo = await isar.walletInfo.get(id) ?? this;

    // only update if there were changes to the name
    if (thisInfo.restoreHeight != newRestoreHeight) {
      await isar.writeTxn(() async {
        await isar.walletInfo.delete(thisInfo.id);
        await isar.walletInfo.put(
          thisInfo.copyWith(
            restoreHeight: newRestoreHeight,
          ),
        );
      });
    }
  }

  /// copies this with a new name and updates the db
  Future<void> updateContractAddresses({
    required Set<String> newContractAddresses,
    required Isar isar,
  }) async {
    await updateOtherData(
      newEntries: {
        WalletInfoKeys.tokenContractAddresses: newContractAddresses.toList(),
      },
      isar: isar,
    );
  }

  //============================================================================

  WalletInfo({
    required this.walletId,
    required this.name,
    required this.mainAddressType,
    required this.coinName,

    // cachedReceivingAddress should never actually be empty in practice as
    // on wallet init it will be set
    this.cachedReceivingAddress = "",
    this.favouriteOrderIndex = -1,
    this.cachedChainHeight = 0,
    this.restoreHeight = 0,
    this.cachedBalanceString,
    this.cachedBalanceSecondaryString,
    this.cachedBalanceTertiaryString,
    this.otherDataJsonString,
  }) : assert(
          AppConfig.coins.map((e) => e.identifier).contains(coinName),
        );

  WalletInfo copyWith({
    String? name,
    AddressType? mainAddressType,
    String? cachedReceivingAddress,
    String? cachedBalanceString,
    String? cachedBalanceSecondaryString,
    String? cachedBalanceTertiaryString,
    String? coinName,
    int? favouriteOrderIndex,
    int? cachedChainHeight,
    int? restoreHeight,
    String? otherDataJsonString,
  }) {
    return WalletInfo(
      walletId: walletId,
      name: name ?? this.name,
      mainAddressType: mainAddressType ?? this.mainAddressType,
      cachedReceivingAddress:
          cachedReceivingAddress ?? this.cachedReceivingAddress,
      cachedBalanceString: cachedBalanceString ?? this.cachedBalanceString,
      cachedBalanceSecondaryString:
          cachedBalanceSecondaryString ?? this.cachedBalanceSecondaryString,
      cachedBalanceTertiaryString:
          cachedBalanceTertiaryString ?? this.cachedBalanceTertiaryString,
      coinName: coinName ?? this.coinName,
      favouriteOrderIndex: favouriteOrderIndex ?? this.favouriteOrderIndex,
      cachedChainHeight: cachedChainHeight ?? this.cachedChainHeight,
      restoreHeight: restoreHeight ?? this.restoreHeight,
      otherDataJsonString: otherDataJsonString ?? this.otherDataJsonString,
    )..id = id;
  }

  static WalletInfo createNew({
    required CryptoCurrency coin,
    required String name,
    int restoreHeight = 0,
    String? walletIdOverride,
    String? otherDataJsonString,
  }) {
    return WalletInfo(
      coinName: coin.identifier,
      walletId: walletIdOverride ?? const Uuid().v1(),
      name: name,
      mainAddressType: coin.primaryAddressType,
      restoreHeight: restoreHeight,
      otherDataJsonString: otherDataJsonString,
    );
  }

  @Deprecated("Legacy support")
  factory WalletInfo.fromJson(
    Map<String, dynamic> jsonObject,
    AddressType mainAddressType,
  ) {
    final coin = AppConfig.getCryptoCurrencyFor(
      jsonObject["coin"] as String,
    )!;
    return WalletInfo(
      coinName: coin.identifier,
      walletId: jsonObject["id"] as String,
      name: jsonObject["name"] as String,
      mainAddressType: mainAddressType,
    );
  }

  @Deprecated("Legacy support")
  Map<String, String> toMap() {
    return {
      "name": name,
      "id": walletId,
      "coin": coin.identifier,
    };
  }

  @Deprecated("Legacy support")
  String toJsonString() {
    return jsonEncode(toMap());
  }

  @override
  String toString() {
    return "WalletInfo: ${toJsonString()}";
  }
}

abstract class WalletInfoKeys {
  static const String tokenContractAddresses = "tokenContractAddressesKey";
  static const String epiccashData = "epiccashDataKey";
  static const String bananoMonkeyImageBytes = "monkeyImageBytesKey";
  static const String tezosDerivationPath = "tezosDerivationPathKey";
  static const String lelantusCoinIsarRescanRequired =
      "lelantusCoinIsarRescanRequired";
}
