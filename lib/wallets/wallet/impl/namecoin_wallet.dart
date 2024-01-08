import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/namecoin.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_hd_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/coin_control_interface.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';

class NamecoinWallet extends Bip39HDWallet
    with ElectrumXInterface, CoinControlInterface {
  @override
  int get isarTransactionVersion => 2;

  NamecoinWallet(CryptoCurrencyNetwork network) : super(Namecoin(network));

  // TODO: double check these filter operations are correct and do not require additional parameters
  @override
  FilterOperation? get changeAddressFilterOperation =>
      FilterGroup.and(standardChangeAddressFilters);

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  // ===========================================================================

  @override
  Future<List<Address>> fetchAddressesForElectrumXScan() async {
    final allAddresses = await mainDB
        .getAddresses(walletId)
        .filter()
        .not()
        .group(
          (q) => q
              .typeEqualTo(AddressType.nonWallet)
              .or()
              .subTypeEqualTo(AddressSubType.nonWallet),
        )
        .findAll();
    return allAddresses;
  }

// ===========================================================================

  @override
  Future<({bool blocked, String? blockedReason, String? utxoLabel})>
      checkBlockUTXO(Map<String, dynamic> jsonUTXO, String? scriptPubKeyHex,
          Map<String, dynamic> jsonTX, String? utxoOwnerAddress) {
    // TODO: implement checkBlockUTXO
    throw UnimplementedError();
  }

  @override
  int estimateTxFee({required int vSize, required int feeRatePerKB}) {
    // TODO: implement estimateTxFee
    throw UnimplementedError();
  }

  @override
  Amount roughFeeEstimate(int inputCount, int outputCount, int feeRatePerKB) {
    // TODO: implement roughFeeEstimate
    throw UnimplementedError();
  }

  @override
  Future<void> updateTransactions() {
    // TODO: implement updateTransactions
    throw UnimplementedError();
  }
}
