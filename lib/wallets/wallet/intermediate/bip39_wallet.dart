import 'package:isar/isar.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../crypto_currency/intermediate/bip39_currency.dart';
import '../wallet.dart';
import '../wallet_mixin_interfaces/mnemonic_interface.dart';

abstract class Bip39Wallet<T extends Bip39Currency> extends Wallet<T>
    with MnemonicInterface {
  Bip39Wallet(super.currency);

  List<FilterOperation> get standardReceivingAddressFilters => [
        FilterCondition.equalTo(
          property: r"type",
          value: info.mainAddressType,
        ),
        const FilterCondition.equalTo(
          property: r"subType",
          value: AddressSubType.receiving,
        ),
      ];

  List<FilterOperation> get standardChangeAddressFilters => [
        FilterCondition.equalTo(
          property: r"type",
          value: info.mainAddressType,
        ),
        const FilterCondition.equalTo(
          property: r"subType",
          value: AddressSubType.change,
        ),
      ];

  // ========== Private ========================================================

  // ========== Overrides ======================================================
}
