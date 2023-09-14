import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

part 'wallet_info.g.dart';

@Collection(accessor: "walletInfo")
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

  final bool isFavourite;

  /// User set favourites ordering. No restrictions are placed on uniqueness.
  /// Reordering logic in the ui code should ensure this is unique.
  final int favouriteOrderIndex;

  /// Wallets without this flag set to true should be deleted on next app run
  /// and should not be displayed in the ui.
  final bool isMnemonicVerified;

  /// The highest block height the wallet has scanned.
  final int cachedChainHeight;

  /// Wallet creation chain height. Applies to select coin only.
  final int creationHeight;

  /// Wallet restore chain height. Applies to select coin only.
  final int restoreHeight;

  //============================================================================

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

  WalletInfo({
    required this.coinName,
    required this.walletId,
    required this.name,
    required this.walletType,
    required this.mainAddressType,
    this.isFavourite = false,
    this.favouriteOrderIndex = 0,
    this.cachedChainHeight = 0,
    this.creationHeight = 0,
    this.restoreHeight = 0,
    this.isMnemonicVerified = false,
    this.cachedBalanceString,
  }) : assert(
          Coin.values.map((e) => e.name).contains(coinName),
        );

  WalletInfo copyWith({
    String? coinName,
    String? name,
    bool? isFavourite,
    int? favouriteOrderIndex,
    int? cachedChainHeight,
    int? creationHeight,
    int? restoreHeight,
    bool? isMnemonicVerified,
    String? cachedBalanceString,
  }) {
    return WalletInfo(
      coinName: coinName ?? this.coinName,
      walletId: walletId,
      name: name ?? this.name,
      walletType: walletType,
      mainAddressType: mainAddressType,
      isFavourite: isFavourite ?? this.isFavourite,
      favouriteOrderIndex: favouriteOrderIndex ?? this.favouriteOrderIndex,
      cachedChainHeight: cachedChainHeight ?? this.cachedChainHeight,
      creationHeight: creationHeight ?? this.creationHeight,
      restoreHeight: restoreHeight ?? this.restoreHeight,
      isMnemonicVerified: isMnemonicVerified ?? this.isMnemonicVerified,
      cachedBalanceString: cachedBalanceString ?? this.cachedBalanceString,
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

// Used in Isar db and stored there as int indexes so adding/removing values
// in this definition should be done extremely carefully in production
enum WalletType {
  bip39,
  cryptonote,
  privateKeyBased;
}
