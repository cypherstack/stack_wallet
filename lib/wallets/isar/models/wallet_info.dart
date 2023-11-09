import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/wallets/isar/isar_id_interface.dart';
import 'package:uuid/uuid.dart';

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

  /// Only exposed for Isar. Use the [coin] getter.
  // Only exposed for isar to avoid dealing with storing enums as Coin can change
  final String coinName;

  /// User set favourites ordering. No restrictions are placed on uniqueness.
  /// Reordering logic in the ui code should ensure this is unique.
  ///
  /// Also represents if the wallet is a favourite. Any number greater then -1
  /// denotes a favourite. Any number less than 0 means it is not a favourite.
  final int favouriteOrderIndex;

  /// Wallets without this flag set to true should be deleted on next app run
  /// and should not be displayed in the ui.
  final bool isMnemonicVerified;

  /// The highest block height the wallet has scanned.
  final int cachedChainHeight;

  /// The block at which this wallet was or should be restored from
  final int restoreHeight;

  // TODO: store these in other data s
  // Should contain specific things based on certain coins only

  // /// Wallet creation chain height. Applies to select coin only.
  // final int creationHeight;
  //
  // /// Wallet restore chain height. Applies to select coin only.
  // final int restoreHeight;

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

  /// Special case for coins such as firo
  @ignore
  Balance get cachedSecondaryBalance {
    try {
      return Balance.fromJson(
        otherData[WalletInfoKeys.cachedSecondaryBalance] as String? ?? "",
        coin.decimals,
      );
    } catch (_) {
      return Balance.zeroForCoin(coin: coin);
    }
  }

  @ignore
  Coin get coin => Coin.values.byName(coinName);

  @ignore
  Balance get cachedBalance {
    if (cachedBalanceString == null) {
      return Balance.zeroForCoin(coin: coin);
    } else {
      return Balance.fromJson(cachedBalanceString!, coin.decimals);
    }
  }

  @ignore
  Map<String, dynamic> get otherData => otherDataJsonString == null
      ? {}
      : Map<String, dynamic>.from(jsonDecode(otherDataJsonString!) as Map);

  //============================================================================
  //============= Updaters      ================================================

  /// copies this with a new balance and updates the db
  Future<void> updateBalance({
    required Balance newBalance,
    required Isar isar,
  }) async {
    final newEncoded = newBalance.toJsonIgnoreCoin();

    // only update if there were changes to the balance
    if (cachedBalanceString != newEncoded) {
      final updated = copyWith(
        cachedBalanceString: newEncoded,
      );
      await isar.writeTxn(() async {
        await isar.walletInfo.delete(id);
        await isar.walletInfo.put(updated);
      });
    }
  }

  /// copies this with a new chain height and updates the db
  Future<void> updateCachedChainHeight({
    required int newHeight,
    required Isar isar,
  }) async {
    // only update if there were changes to the height
    if (cachedChainHeight != newHeight) {
      final updated = copyWith(
        cachedChainHeight: newHeight,
      );
      await isar.writeTxn(() async {
        await isar.walletInfo.delete(id);
        await isar.walletInfo.put(updated);
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

    // only update if there were changes to the height
    if (favouriteOrderIndex != index) {
      final updated = copyWith(
        favouriteOrderIndex: index,
      );
      await isar.writeTxn(() async {
        await isar.walletInfo.delete(id);
        await isar.walletInfo.put(updated);
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

    // only update if there were changes to the name
    if (name != newName) {
      final updated = copyWith(
        name: newName,
      );
      await isar.writeTxn(() async {
        await isar.walletInfo.delete(id);
        await isar.walletInfo.put(updated);
      });
    }
  }

  /// copies this with a new name and updates the db
  Future<void> updateReceivingAddress({
    required String newAddress,
    required Isar isar,
  }) async {
    // only update if there were changes to the name
    if (cachedReceivingAddress != newAddress) {
      final updated = copyWith(
        cachedReceivingAddress: newAddress,
      );
      await isar.writeTxn(() async {
        await isar.walletInfo.delete(id);
        await isar.walletInfo.put(updated);
      });
    }
  }

  /// copies this with a new name and updates the db
  Future<void> setMnemonicVerified({
    required Isar isar,
  }) async {
    // only update if there were changes to the name
    if (!isMnemonicVerified) {
      final updated = copyWith(
        isMnemonicVerified: true,
      );
      await isar.writeTxn(() async {
        await isar.walletInfo.delete(id);
        await isar.walletInfo.put(updated);
      });
    } else {
      throw Exception(
        "setMnemonicVerified() called on already"
        " verified wallet: $name, $walletId",
      );
    }
  }

  //============================================================================

  WalletInfo({
    required this.coinName,
    required this.walletId,
    required this.name,
    required this.mainAddressType,

    // cachedReceivingAddress should never actually be empty in practice as
    // on wallet init it will be set
    this.cachedReceivingAddress = "",
    this.favouriteOrderIndex = 0,
    this.cachedChainHeight = 0,
    this.restoreHeight = 0,
    this.isMnemonicVerified = false,
    this.cachedBalanceString,
    this.otherDataJsonString,
  }) : assert(
          Coin.values.map((e) => e.name).contains(coinName),
        );

  static WalletInfo createNew({
    required Coin coin,
    required String name,
    int restoreHeight = 0,
    String? walletIdOverride,
  }) {
    // TODO: make Coin aware of these
    // ex.
    // walletType = coin.walletType;
    // mainAddressType = coin.mainAddressType;

    final AddressType mainAddressType;
    switch (coin) {
      case Coin.bitcoin:
      case Coin.bitcoinTestNet:
        mainAddressType = AddressType.p2wpkh;
        break;

      case Coin.bitcoincash:
      case Coin.bitcoincashTestnet:
        mainAddressType = AddressType.p2pkh;
        break;

      default:
        throw UnimplementedError();
    }

    return WalletInfo(
      coinName: coin.name,
      walletId: walletIdOverride ?? const Uuid().v1(),
      name: name,
      mainAddressType: mainAddressType,
      restoreHeight: restoreHeight,
    );
  }

  WalletInfo copyWith({
    String? coinName,
    String? name,
    int? favouriteOrderIndex,
    int? cachedChainHeight,
    bool? isMnemonicVerified,
    String? cachedBalanceString,
    String? cachedReceivingAddress,
    int? restoreHeight,
    Map<String, dynamic>? otherData,
  }) {
    return WalletInfo(
      coinName: coinName ?? this.coinName,
      walletId: walletId,
      name: name ?? this.name,
      mainAddressType: mainAddressType,
      favouriteOrderIndex: favouriteOrderIndex ?? this.favouriteOrderIndex,
      cachedChainHeight: cachedChainHeight ?? this.cachedChainHeight,
      isMnemonicVerified: isMnemonicVerified ?? this.isMnemonicVerified,
      cachedBalanceString: cachedBalanceString ?? this.cachedBalanceString,
      restoreHeight: restoreHeight ?? this.restoreHeight,
      cachedReceivingAddress:
          cachedReceivingAddress ?? this.cachedReceivingAddress,
      otherDataJsonString:
          otherData == null ? otherDataJsonString : jsonEncode(otherData),
    )..id = id;
  }

  @Deprecated("Legacy support")
  factory WalletInfo.fromJson(
    Map<String, dynamic> jsonObject,
    AddressType mainAddressType,
  ) {
    final coin = Coin.values.byName(jsonObject["coin"] as String);
    return WalletInfo(
      coinName: coin.name,
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
      "coin": coin.name,
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
  static const String cachedSecondaryBalance = "cachedSecondaryBalanceKey";
  static const String epiccashData = "epiccashDataKey";
}
