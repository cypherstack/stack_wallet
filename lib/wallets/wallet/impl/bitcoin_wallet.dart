import 'package:isar/isar.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../utilities/amount/amount.dart';
import '../../crypto_currency/coins/bitcoin.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../crypto_currency/interfaces/paynym_currency_interface.dart';
import '../intermediate/bip39_hd_wallet.dart';
import '../wallet_mixin_interfaces/coin_control_interface.dart';
import '../wallet_mixin_interfaces/electrumx_interface.dart';
import '../wallet_mixin_interfaces/paynym_interface.dart';

class BitcoinWallet<T extends PaynymCurrencyInterface> extends Bip39HDWallet<T>
    with ElectrumXInterface<T>, CoinControlInterface, PaynymInterface<T> {
  @override
  int get isarTransactionVersion => 2;

  BitcoinWallet(CryptoCurrencyNetwork network) : super(Bitcoin(network) as T);

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
  Amount roughFeeEstimate(int inputCount, int outputCount, int feeRatePerKB) {
    return Amount(
      rawValue: BigInt.from(
          ((42 + (272 * inputCount) + (128 * outputCount)) / 4).ceil() *
              (feeRatePerKB / 1000).ceil()),
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }

  @override
  int estimateTxFee({required int vSize, required int feeRatePerKB}) {
    return vSize * (feeRatePerKB / 1000).ceil();
  }
  //
  // @override
  // Future<TxData> coinSelection({required TxData txData}) async {
  //   final isCoinControl = txData.utxos != null;
  //   final isSendAll = txData.amount == info.cachedBalance.spendable;
  //
  //   final utxos =
  //       txData.utxos?.toList() ?? await mainDB.getUTXOs(walletId).findAll();
  //
  //   final currentChainHeight = await chainHeight;
  //   final List<UTXO> spendableOutputs = [];
  //   int spendableSatoshiValue = 0;
  //
  //   // Build list of spendable outputs and totaling their satoshi amount
  //   for (final utxo in utxos) {
  //     if (utxo.isBlocked == false &&
  //         utxo.isConfirmed(currentChainHeight, cryptoCurrency.minConfirms) &&
  //         utxo.used != true) {
  //       spendableOutputs.add(utxo);
  //       spendableSatoshiValue += utxo.value;
  //     }
  //   }
  //
  //   if (isCoinControl && spendableOutputs.length < utxos.length) {
  //     throw ArgumentError("Attempted to use an unavailable utxo");
  //   }
  //
  //   if (spendableSatoshiValue < txData.amount!.raw.toInt()) {
  //     throw Exception("Insufficient balance");
  //   } else if (spendableSatoshiValue == txData.amount!.raw.toInt() &&
  //       !isSendAll) {
  //     throw Exception("Insufficient balance to pay transaction fee");
  //   }
  //
  //   if (isCoinControl) {
  //   } else {
  //     final selection = cs.coinSelection(
  //       spendableOutputs
  //           .map((e) => cs.InputModel(
  //                 i: e.vout,
  //                 txid: e.txid,
  //                 value: e.value,
  //                 address: e.address,
  //               ))
  //           .toList(),
  //       txData.recipients!
  //           .map((e) => cs.OutputModel(
  //                 address: e.address,
  //                 value: e.amount.raw.toInt(),
  //               ))
  //           .toList(),
  //       txData.feeRateAmount!,
  //       10, // TODO: ???????????????????????????????
  //     );
  //
  //     // .inputs and .outputs will be null if no solution was found
  //     if (selection.inputs!.isEmpty || selection.outputs!.isEmpty) {
  //       throw Exception("coin selection failed");
  //     }
  //   }
  // }
}
