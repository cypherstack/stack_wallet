import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:bitbox/src/utils/network.dart' as bitbox_utils;
import 'package:isar/isar.dart';

import '../../../models/input.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_hd_wallet.dart';
import 'electrumx_interface.dart';

mixin BCashInterface<T extends ElectrumXCurrencyInterface>
    on Bip39HDWallet<T>, ElectrumXInterface<T> {
  @override
  Future<TxData> buildTransaction({
    required TxData txData,
    required covariant List<StandardInput> inputsWithKeys,
  }) async {
    Logging.instance.d("Starting buildTransaction ----------");

    // TODO: use coinlib

    final builder = bitbox.Bitbox.transactionBuilder(
      testnet: cryptoCurrency.network.isTestNet,
    );

    builder.setVersion(cryptoCurrency.transactionVersion);

    // temp tx data to show in gui while waiting for real data from server
    final List<InputV2> tempInputs = [];
    final List<OutputV2> tempOutputs = [];

    // Add transaction inputs
    for (int i = 0; i < inputsWithKeys.length; i++) {
      builder.addInput(
        inputsWithKeys[i].utxo.txid,
        inputsWithKeys[i].utxo.vout,
      );

      tempInputs.add(
        InputV2.isarCantDoRequiredInDefaultConstructor(
          scriptSigHex: "000000",
          scriptSigAsm: null,
          sequence: 0xffffffff - 1,
          outpoint: OutpointV2.isarCantDoRequiredInDefaultConstructor(
            txid: inputsWithKeys[i].utxo.txid,
            vout: inputsWithKeys[i].utxo.vout,
          ),
          addresses:
              inputsWithKeys[i].utxo.address == null
                  ? []
                  : [inputsWithKeys[i].utxo.address!],
          valueStringSats: inputsWithKeys[i].utxo.value.toString(),
          witness: null,
          innerRedeemScriptAsm: null,
          coinbase: null,
          walletOwns: true,
        ),
      );
    }

    // Add transaction output
    for (var i = 0; i < txData.recipients!.length; i++) {
      builder.addOutput(
        normalizeAddress(txData.recipients![i].address),
        txData.recipients![i].amount.raw.toInt(),
      );

      tempOutputs.add(
        OutputV2.isarCantDoRequiredInDefaultConstructor(
          scriptPubKeyHex: "000000",
          valueStringSats: txData.recipients![i].amount.raw.toString(),
          addresses: [txData.recipients![i].address.toString()],
          walletOwns:
              (await mainDB.isar.addresses
                  .where()
                  .walletIdEqualTo(walletId)
                  .filter()
                  .valueEqualTo(txData.recipients![i].address)
                  .or()
                  .valueEqualTo(normalizeAddress(txData.recipients![i].address))
                  .valueProperty()
                  .findFirst()) !=
              null,
        ),
      );
    }

    try {
      // Sign the transaction accordingly
      for (int i = 0; i < inputsWithKeys.length; i++) {
        final bitboxEC = bitbox.ECPair.fromPrivateKey(
          inputsWithKeys[i].key!.privateKey!.data,
          network: bitbox_utils.Network(
            cryptoCurrency.networkParams.privHDPrefix,
            cryptoCurrency.networkParams.pubHDPrefix,
            cryptoCurrency.network.isTestNet,
            cryptoCurrency.networkParams.p2pkhPrefix,
            cryptoCurrency.networkParams.wifPrefix,
            cryptoCurrency.networkParams.p2pkhPrefix,
          ),
          compressed: inputsWithKeys[i].key!.privateKey!.compressed,
        );

        builder.sign(i, bitboxEC, inputsWithKeys[i].utxo.value);
      }
    } catch (e, s) {
      Logging.instance.e(
        "Caught exception while signing transaction: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }

    final builtTx = builder.build();
    final vSize = builtTx.virtualSize();

    return txData.copyWith(
      raw: builtTx.toHex(),
      vSize: vSize,
      tempTx: TransactionV2(
        walletId: walletId,
        blockHash: null,
        hash: builtTx.getId(),
        txid: builtTx.getId(),
        height: null,
        timestamp: DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
        inputs: List.unmodifiable(tempInputs),
        outputs: List.unmodifiable(tempOutputs),
        version: builtTx.version,
        type:
            tempOutputs.map((e) => e.walletOwns).fold(true, (p, e) => p &= e) &&
                    txData.paynymAccountLite == null
                ? TransactionType.sentToSelf
                : TransactionType.outgoing,
        subType: TransactionSubType.none,
        otherData: null,
      ),
    );
  }
}
