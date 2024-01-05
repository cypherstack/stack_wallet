import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/bitcoin.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_hd_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/coin_control_interface.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/paynym_interface.dart';
import 'package:tuple/tuple.dart';

class BitcoinWallet extends Bip39HDWallet
    with ElectrumXInterface, CoinControlInterface, PaynymInterface {
  @override
  int get isarTransactionVersion => 1; // TODO actually set this to 2

  BitcoinWallet(CryptoCurrencyNetwork network) : super(Bitcoin(network));

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
  Future<void> updateTransactions() async {
    final currentChainHeight = await fetchChainHeight();

    // TODO: [prio=med] switch to V2 transactions
    final data = await fetchTransactionsV1(
      addresses: await fetchAddressesForElectrumXScan(),
      currentChainHeight: currentChainHeight,
    );

    await mainDB.addNewTransactionData(
      data
          .map((e) => Tuple2(
                e.transaction,
                e.address,
              ))
          .toList(),
      walletId,
    );
  }

  @override
  Future<({String? blockedReason, bool blocked, String? utxoLabel})>
      checkBlockUTXO(
    Map<String, dynamic> jsonUTXO,
    String? scriptPubKeyHex,
    Map<String, dynamic>? jsonTX,
    String? utxoOwnerAddress,
  ) async {
    bool blocked = false;
    String? blockedReason;

    if (jsonTX != null) {
      // check for bip47 notification
      final outputs = jsonTX["vout"] as List;
      for (final output in outputs) {
        List<String>? scriptChunks =
            (output['scriptPubKey']?['asm'] as String?)?.split(" ");
        if (scriptChunks?.length == 2 && scriptChunks?[0] == "OP_RETURN") {
          final blindedPaymentCode = scriptChunks![1];
          final bytes = blindedPaymentCode.toUint8ListFromHex;

          // https://en.bitcoin.it/wiki/BIP_0047#Sending
          if (bytes.length == 80 && bytes.first == 1) {
            blocked = true;
            blockedReason = "Paynym notification output. Incautious "
                "handling of outputs from notification transactions "
                "may cause unintended loss of privacy.";
            break;
          }
        }
      }
    }

    return (blockedReason: blockedReason, blocked: blocked, utxoLabel: null);
  }

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
