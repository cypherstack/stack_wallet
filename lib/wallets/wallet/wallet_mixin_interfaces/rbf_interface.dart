import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../../models/input.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/fee_rate_type_enum.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../../isar/models/wallet_info.dart';
import '../../models/tx_data.dart';
import 'electrumx_interface.dart';
import 'replacement_fee.dart';

mixin RbfInterface<T extends ElectrumXCurrencyInterface>
    on ElectrumXInterface<T> {
  bool get flagOptInRBF =>
      info.otherData[WalletInfoKeys.enableOptInRbf] as bool? ?? false;

  /// [transactionV2] stored with its size taken from raw bytes the current
  /// server proves this wallet signed, or null if it cannot be authenticated.
  Future<TransactionV2?> updateVSize(TransactionV2 transactionV2) async {
    final size = await verifyPendingSpend(
      txid: transactionV2.txid,
      inputs: transactionV2.inputs,
      outputs: transactionV2.outputs,
    );
    if (size == null) {
      return null;
    }
    final otherData = jsonDecode(transactionV2.otherData ?? "{}");
    otherData[TxV2OdKeys.vSize] = size.vSize;
    otherData[TxV2OdKeys.size] = size.size;
    final updatedTx = transactionV2.copyWith(otherData: jsonEncode(otherData));
    await mainDB.updateOrPutTransactionV2s([updatedTx]);
    return updatedTx;
  }

  Future<TxData> prepareRbfSend({
    required TransactionV2 oldTransaction,
    required int newRate,
  }) async {
    // Price the bump off a size taken from bytes the server proves we signed,
    // never off anything it merely claimed.
    final oldSize = await verifyPendingSpend(
      txid: oldTransaction.txid,
      inputs: oldTransaction.inputs,
      outputs: oldTransaction.outputs,
    );
    if (oldSize == null) {
      throw Exception("Could not verify this transaction's signatures");
    }

    final note = await mainDB.isar.transactionNotes
        .where()
        .walletIdEqualTo(walletId)
        .filter()
        .txidEqualTo(oldTransaction.txid)
        .findFirst();

    final Set<StandardInput> utxos = {};
    for (final input in oldTransaction.inputs) {
      final utxo = UTXO(
        walletId: walletId,
        txid: input.outpoint!.txid,
        vout: input.outpoint!.vout,
        value: input.value.toInt(),
        name: "rbf",
        isBlocked: false,
        blockedReason: null,
        isCoinbase: false,
        blockHash: "rbf",
        blockHeight: 1,
        blockTime: 1,
        used: false,
        address: input.addresses.first,
      );

      utxos.add(StandardInput(utxo));
    }

    final List<TxRecipient> recipients = [];
    for (final output in oldTransaction.outputs) {
      if (output.addresses.length != 1) {
        throw UnsupportedError(
          "Unexpected output.addresses.length: ${output.addresses.length}",
        );
      }
      final address = output.addresses.first;
      final addressModel = await mainDB.getAddress(walletId, address);
      final isChange = addressModel?.subType == AddressSubType.change;

      recipients.add(
        TxRecipient(
          address: address,
          amount: Amount(
            rawValue: output.value,
            fractionDigits: cryptoCurrency.fractionDigits,
          ),
          isChange: isChange,
          addressType: cryptoCurrency.getAddressType(address)!,
        ),
      );
    }

    final oldFee = oldTransaction
        .getFee(fractionDigits: cryptoCurrency.fractionDigits)
        .raw;
    final inSum = utxos.map((e) => e.value).fold(BigInt.zero, (p, e) => p + e);

    final noChange =
        recipients.map((e) => e.isChange).fold(false, (p, e) => p || e) ==
        false;
    final otherAvailableUtxos = await mainDB
        .getUTXOs(walletId)
        .filter()
        .isBlockedEqualTo(false)
        .and()
        .group((q) => q.usedIsNull().or().usedEqualTo(false))
        .findAll();

    final height = await chainHeight;
    otherAvailableUtxos.removeWhere(
      (e) => !e.isConfirmed(
        height,
        cryptoCurrency.minConfirms,
        cryptoCurrency.minCoinbaseConfirms,
      ),
    );

    TxData txData = TxData(
      recipients: recipients,
      feeRateType: FeeRateType.custom,
      satsPerVByte: newRate,
      utxos: utxos,
      ignoreCachedBalanceChecks: true,
      note: note?.value ?? "",
    );

    if (otherAvailableUtxos.isEmpty && noChange && recipients.length == 1) {
      // safe to assume send all?
      txData = txData.copyWith(
        recipients: [
          TxRecipient(
            address: recipients.first.address,
            amount: Amount(
              rawValue: inSum,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            isChange: false,
            addressType: recipients.first.addressType,
          ),
        ],
      );
      Logging.instance.d("RBF on assumed send all");
      final result = await prepareSend(txData: txData);
      final vSize = result.vSize;
      if (vSize != null && result.fee != null) {
        requireReplacementFee(
          result.fee!.raw,
          vSize: vSize,
          oldFee: oldFee,
          newRate: newRate,
        );
      }
      return result;
    } else if (txData.recipients!.where((e) => e.isChange).length == 1) {
      if (BigInt.from(oldSize.vSize * newRate) <= oldFee) {
        throw Exception("New fee rate must be greater than the current rate");
      }

      final indexOfChangeOutput = txData.recipients!.indexWhere(
        (e) => e.isChange,
      );
      final change = txData.recipients![indexOfChangeOutput];
      final otherRecipients = [...txData.recipients!]
        ..removeAt(indexOfChangeOutput);

      // Size the built replacement and raise the fee until it pays [newRate]
      // on that size and clears the old fee by the incremental relay fee.
      return settleReplacementFee(
        oldVSize: oldSize.vSize,
        oldFee: oldFee,
        newRate: newRate,
        build: (newFee) async {
          final built = await _buildReplacement(
            txData: txData,
            otherRecipients: otherRecipients,
            change: change,
            indexOfChangeOutput: indexOfChangeOutput,
            oldFee: oldFee,
            newFee: newFee,
            otherAvailableUtxos: otherAvailableUtxos,
          );
          return (fee: built.fee!.raw, vSize: built.vSize!, built: built);
        },
      );
    } else {
      // TODO handle building a tx here in this case
      throw Exception(
        "Unexpected number of change outputs found:"
        " ${txData.recipients!.where((e) => e.isChange).length}",
      );
    }
  }

  /// Builds the replacement paying [newFee] out of the change output, dropping
  /// it below dust or adding coins as needed. The result's fee is as paid.
  Future<TxData> _buildReplacement({
    required TxData txData,
    required List<TxRecipient> otherRecipients,
    required TxRecipient change,
    required int indexOfChangeOutput,
    required BigInt oldFee,
    required BigInt newFee,
    required List<UTXO> otherAvailableUtxos,
  }) async {
    final recipients = [...otherRecipients];
    var utxoSet = {...txData.utxos!.whereType<StandardInput>()};
    var newChangeAmount = change.amount.raw - (newFee - oldFee);

    if (newChangeAmount < BigInt.zero) {
      // we need more utxos
      final List<UTXO> extraUtxos = [];
      for (final utxo in otherAvailableUtxos) {
        newChangeAmount += BigInt.from(utxo.value);
        extraUtxos.add(utxo);
        if (newChangeAmount >= cryptoCurrency.dustLimit.raw) {
          break;
        }
      }
      if (newChangeAmount < cryptoCurrency.dustLimit.raw) {
        throw Exception("Insufficient funds to pay for increased fee");
      }
      utxoSet = {...utxoSet, ...extraUtxos.map((e) => StandardInput(e))};
      Logging.instance.d(
        "RBF with ${extraUtxos.length} extra utxo(s)"
        " added to pay for the new fee",
      );
    }

    if (newChangeAmount >= cryptoCurrency.dustLimit.raw) {
      recipients.insert(
        indexOfChangeOutput,
        change.copyWith(
          amount: Amount(
            rawValue: newChangeAmount,
            fractionDigits: cryptoCurrency.fractionDigits,
          ),
        ),
      );
      Logging.instance.d("RBF with increased fee and reduced change");
    } else {
      // change below dust goes to the fee
      Logging.instance.d("RBF with increased fee and no change");
    }

    final inSum = utxoSet
        .map((e) => e.value)
        .fold(BigInt.zero, (p, e) => p + e);
    final outSum = recipients
        .map((e) => e.amount.raw)
        .fold(BigInt.zero, (p, e) => p + e);
    final inputs = utxoSet.toList();
    return await buildTransaction(
      txData: txData.copyWith(
        recipients: recipients,
        utxos: utxoSet,
        usedUTXOs: inputs,
        fee: Amount(
          rawValue: inSum - outSum,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
      ),
      inputsWithKeys: await addSigningKeys(inputs),
    );
  }
}
