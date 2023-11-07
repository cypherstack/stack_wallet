import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/bitcoin.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_hd_wallet.dart';
import 'package:stackwallet/wallets/wallet/mixins/electrumx_mixin.dart';
import 'package:tuple/tuple.dart';

class BitcoinWallet extends Bip39HDWallet with ElectrumXMixin {
  @override
  int get isarTransactionVersion => 2; // TODO actually do this

  BitcoinWallet(Bitcoin cryptoCurrency) : super(cryptoCurrency);

  @override
  FilterOperation? get changeAddressFilterOperation =>
      FilterGroup.and(standardChangeAddressFilters);

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  // ===========================================================================

  @override
  Future<List<Address>> fetchAllOwnAddresses() async {
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
      addresses: await fetchAllOwnAddresses(),
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
  ({String? blockedReason, bool blocked}) checkBlockUTXO(
    Map<String, dynamic> jsonUTXO,
    String? scriptPubKeyHex,
    Map<String, dynamic>? jsonTX,
  ) {
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

    return (blockedReason: blockedReason, blocked: blocked);
  }

  @override
  Amount roughFeeEstimate(int inputCount, int outputCount, int feeRatePerKB) {
    return Amount(
      rawValue: BigInt.from(
          ((42 + (272 * inputCount) + (128 * outputCount)) / 4).ceil() *
              (feeRatePerKB / 1000).ceil()),
      fractionDigits: info.coin.decimals,
    );
  }
}
