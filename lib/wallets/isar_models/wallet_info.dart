import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

part 'wallet_info.g.dart';

@Collection(accessor: "walletInfo", inheritance: false)
class WalletInfo {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  final String walletId;

  final String name;

  @enumerated
  final WalletType walletType;

  @enumerated
  final AddressType mainAddressType;

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

  List<String> get tokenContractAddresses =>
      otherData[WalletInfoKeys.tokenContractAddresses] as List<String>? ?? [];

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

  //============================================================================

  WalletInfo({
    required this.coinName,
    required this.walletId,
    required this.name,
    required this.walletType,
    required this.mainAddressType,
    this.favouriteOrderIndex = 0,
    this.cachedChainHeight = 0,
    this.isMnemonicVerified = false,
    this.cachedBalanceString,
    this.otherDataJsonString,
  }) : assert(
          Coin.values.map((e) => e.name).contains(coinName),
        );

  WalletInfo copyWith({
    String? coinName,
    String? name,
    int? favouriteOrderIndex,
    int? cachedChainHeight,
    bool? isMnemonicVerified,
    String? cachedBalanceString,
    Map<String, dynamic>? otherData,
  }) {
    return WalletInfo(
      coinName: coinName ?? this.coinName,
      walletId: walletId,
      name: name ?? this.name,
      walletType: walletType,
      mainAddressType: mainAddressType,
      favouriteOrderIndex: favouriteOrderIndex ?? this.favouriteOrderIndex,
      cachedChainHeight: cachedChainHeight ?? this.cachedChainHeight,
      isMnemonicVerified: isMnemonicVerified ?? this.isMnemonicVerified,
      cachedBalanceString: cachedBalanceString ?? this.cachedBalanceString,
      otherDataJsonString:
          otherData == null ? otherDataJsonString : jsonEncode(otherData),
    )..id = id;
  }

  @Deprecated("Legacy support")
  factory WalletInfo.fromJson(Map<String, dynamic> jsonObject,
      WalletType walletType, AddressType mainAddressType) {
    final coin = Coin.values.byName(jsonObject["coin"] as String);
    return WalletInfo(
      coinName: coin.name,
      walletId: jsonObject["id"] as String,
      name: jsonObject["name"] as String,
      walletType: walletType,
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

// Used in Isar db and stored there as int indexes so adding/removing values
// in this definition should be done extremely carefully in production
enum WalletType {
  bip39,
  bip39HD,
  cryptonote,
  privateKeyBased;
}
