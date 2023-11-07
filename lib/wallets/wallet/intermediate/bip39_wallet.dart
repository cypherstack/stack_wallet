import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_currency.dart';
import 'package:stackwallet/wallets/wallet/mixins/mnemonic_based_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

abstract class Bip39Wallet<T extends Bip39Currency> extends Wallet<T>
    with MnemonicBasedWallet {
  Bip39Wallet(T currency) : super(currency);

  List<FilterOperation> get standardReceivingAddressFilters => [
        FilterCondition.equalTo(
          property: "type",
          value: [info.mainAddressType],
        ),
        const FilterCondition.equalTo(
          property: "subType",
          value: [AddressSubType.receiving],
        ),
      ];

  List<FilterOperation> get standardChangeAddressFilters => [
        FilterCondition.equalTo(
          property: "type",
          value: [info.mainAddressType],
        ),
        const FilterCondition.equalTo(
          property: "subType",
          value: [AddressSubType.change],
        ),
      ];

  // ========== Private ========================================================

  // ========== Overrides ======================================================
}
