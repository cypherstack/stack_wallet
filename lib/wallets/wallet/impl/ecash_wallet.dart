import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:isar/isar.dart';

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../services/coins/bitcoincash/bch_utils.dart';
import '../../../services/coins/bitcoincash/cashtokens.dart' as cash_tokens;
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../intermediate/bip39_hd_wallet.dart';
import '../wallet_mixin_interfaces/bcash_interface.dart';
import '../wallet_mixin_interfaces/cash_fusion_interface.dart';
import '../wallet_mixin_interfaces/coin_control_interface.dart';
import '../wallet_mixin_interfaces/electrumx_interface.dart';
import '../wallet_mixin_interfaces/extended_keys_interface.dart';

class EcashWallet<T extends ElectrumXCurrencyInterface> extends Bip39HDWallet<T>
    with
        ElectrumXInterface<T>,
        ExtendedKeysInterface<T>,
        BCashInterface<T>,
        CoinControlInterface<T>,
        CashFusionInterface<T> {
  @override
  int get isarTransactionVersion => 2;

  EcashWallet(CryptoCurrencyNetwork network) : super(Ecash(network) as T);

  @override
  FilterOperation? get changeAddressFilterOperation => FilterGroup.and(
        [
          ...standardChangeAddressFilters,
          const ObjectFilter(
            property: "derivationPath",
            filter: FilterCondition.startsWith(
              property: "value",
              value: "m/44'/899",
            ),
          ),
        ],
      );

  @override
  FilterOperation? get receivingAddressFilterOperation => FilterGroup.and(
        [
          ...standardReceivingAddressFilters,
          const ObjectFilter(
            property: "derivationPath",
            filter: FilterCondition.startsWith(
              property: "value",
              value: "m/44'/899",
            ),
          ),
        ],
      );

  // ===========================================================================

  @override
  Future<List<Address>> fetchAddressesForElectrumXScan() async {
    final allAddresses = await mainDB
        .getAddresses(walletId)
        .filter()
        .not()
        .typeEqualTo(AddressType.nonWallet)
        .and()
        .not()
        .subTypeEqualTo(AddressSubType.nonWallet)
        .findAll();
    return allAddresses;
  }

  @override
  String convertAddressString(String address) {
    if (bitbox.Address.detectFormat(address) == bitbox.Address.formatLegacy &&
        (cryptoCurrency.addressType(address: address) == DerivePathType.bip44 ||
            cryptoCurrency.addressType(address: address) ==
                DerivePathType.eCash44)) {
      return bitbox.Address.toECashAddress(address);
    } else {
      return address;
    }
  }

  // ===========================================================================

  @override
  Future<void> updateTransactions() async {
    final List<Address> allAddressesOld =
        await fetchAddressesForElectrumXScan();

    final Set<String> receivingAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.receiving)
        .map((e) => convertAddressString(e.value))
        .toSet();

    final Set<String> changeAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.change)
        .map((e) => convertAddressString(e.value))
        .toSet();

    final allAddressesSet = {...receivingAddresses, ...changeAddresses};

    final List<Map<String, dynamic>> allTxHashes =
        await fetchHistory(allAddressesSet);

    final List<Map<String, dynamic>> allTransactions = [];

    for (final txHash in allTxHashes) {
      final storedTx = await mainDB.isar.transactionV2s
          .where()
          .txidWalletIdEqualTo(txHash["tx_hash"] as String, walletId)
          .findFirst();

      if (storedTx == null ||
          storedTx.height == null ||
          (storedTx.height != null && storedTx.height! <= 0)) {
        final tx = await electrumXCachedClient.getTransaction(
          txHash: txHash["tx_hash"] as String,
          verbose: true,
          cryptoCurrency: cryptoCurrency,
        );

        // check for duplicates before adding to list
        if (allTransactions
                .indexWhere((e) => e["txid"] == tx["txid"] as String) ==
            -1) {
          tx["height"] = txHash["height"];
          allTransactions.add(tx);
        }
      }
    }

    final List<TransactionV2> txns = [];

    for (final txData in allTransactions) {
      // set to true if any inputs were detected as owned by this wallet
      bool wasSentFromThisWallet = false;

      // set to true if any outputs were detected as owned by this wallet
      bool wasReceivedInThisWallet = false;
      BigInt amountReceivedInThisWallet = BigInt.zero;
      BigInt changeAmountReceivedInThisWallet = BigInt.zero;

      // parse inputs
      final List<InputV2> inputs = [];
      for (final jsonInput in txData["vin"] as List) {
        final map = Map<String, dynamic>.from(jsonInput as Map);

        final List<String> addresses = [];
        String valueStringSats = "0";
        OutpointV2? outpoint;

        final coinbase = map["coinbase"] as String?;

        if (coinbase == null) {
          final txid = map["txid"] as String;
          final vout = map["vout"] as int;

          final inputTx = await electrumXCachedClient.getTransaction(
            txHash: txid,
            cryptoCurrency: cryptoCurrency,
          );

          final prevOutJson = Map<String, dynamic>.from(
            (inputTx["vout"] as List).firstWhere((e) => e["n"] == vout) as Map,
          );

          final prevOut = OutputV2.fromElectrumXJson(
            prevOutJson,
            decimalPlaces: cryptoCurrency.fractionDigits,
            isFullAmountNotSats: true,
            walletOwns: false, // doesn't matter here as this is not saved
          );

          outpoint = OutpointV2.isarCantDoRequiredInDefaultConstructor(
            txid: txid,
            vout: vout,
          );
          valueStringSats = prevOut.valueStringSats;
          addresses.addAll(prevOut.addresses);
        }

        InputV2 input = InputV2.isarCantDoRequiredInDefaultConstructor(
          scriptSigHex: map["scriptSig"]?["hex"] as String?,
          scriptSigAsm: map["scriptSig"]?["asm"] as String?,
          sequence: map["sequence"] as int?,
          outpoint: outpoint,
          valueStringSats: valueStringSats,
          addresses: addresses,
          witness: map["witness"] as String?,
          coinbase: coinbase,
          innerRedeemScriptAsm: map["innerRedeemscriptAsm"] as String?,
          // don't know yet if wallet owns. Need addresses first
          walletOwns: false,
        );

        if (allAddressesSet.intersection(input.addresses.toSet()).isNotEmpty) {
          wasSentFromThisWallet = true;
          input = input.copyWith(walletOwns: true);
        }

        inputs.add(input);
      }

      // parse outputs
      final List<OutputV2> outputs = [];
      for (final outputJson in txData["vout"] as List) {
        OutputV2 output = OutputV2.fromElectrumXJson(
          Map<String, dynamic>.from(outputJson as Map),
          decimalPlaces: cryptoCurrency.fractionDigits,
          isFullAmountNotSats: true,
          // don't know yet if wallet owns. Need addresses first
          walletOwns: false,
        );

        // if output was to my wallet, add value to amount received
        if (receivingAddresses
            .intersection(output.addresses.toSet())
            .isNotEmpty) {
          wasReceivedInThisWallet = true;
          amountReceivedInThisWallet += output.value;
          output = output.copyWith(walletOwns: true);
        } else if (changeAddresses
            .intersection(output.addresses.toSet())
            .isNotEmpty) {
          wasReceivedInThisWallet = true;
          changeAmountReceivedInThisWallet += output.value;
          output = output.copyWith(walletOwns: true);
        }

        outputs.add(output);
      }

      final totalOut = outputs
          .map((e) => e.value)
          .fold(BigInt.zero, (value, element) => value + element);

      TransactionType type;
      TransactionSubType subType = TransactionSubType.none;

      // at least one input was owned by this wallet
      if (wasSentFromThisWallet) {
        type = TransactionType.outgoing;

        if (wasReceivedInThisWallet) {
          if (changeAmountReceivedInThisWallet + amountReceivedInThisWallet ==
              totalOut) {
            // definitely sent all to self
            type = TransactionType.sentToSelf;
          } else if (amountReceivedInThisWallet == BigInt.zero) {
            // most likely just a typical send
            // do nothing here yet
          }

          // check vout 0 for special scripts
          if (outputs.isNotEmpty) {
            final output = outputs.first;

            // check for fusion
            if (BchUtils.isFUZE(output.scriptPubKeyHex.toUint8ListFromHex)) {
              subType = TransactionSubType.cashFusion;
            } else {
              // check other cases here such as SLP or cash tokens etc
            }
          }
        }
      } else if (wasReceivedInThisWallet) {
        // only found outputs owned by this wallet
        type = TransactionType.incoming;
      } else {
        Logging.instance.e("Unexpected tx found (ignoring it)");
        Logging.instance.d("Unexpected tx found (ignoring it): $txData");
        continue;
      }

      final tx = TransactionV2(
        walletId: walletId,
        blockHash: txData["blockhash"] as String?,
        hash: txData["hash"] as String,
        txid: txData["txid"] as String,
        height: txData["height"] as int?,
        version: txData["version"] as int,
        timestamp: txData["blocktime"] as int? ??
            DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
        inputs: List.unmodifiable(inputs),
        outputs: List.unmodifiable(outputs),
        type: type,
        subType: subType,
        otherData: null,
      );

      txns.add(tx);
    }

    await mainDB.updateOrPutTransactionV2s(txns);
  }

  @override
  Future<
      ({
        String? blockedReason,
        bool blocked,
        String? utxoLabel,
      })> checkBlockUTXO(
    Map<String, dynamic> jsonUTXO,
    String? scriptPubKeyHex,
    Map<String, dynamic> jsonTX,
    String? utxoOwnerAddress,
  ) async {
    bool blocked = false;
    String? blockedReason;

    if (scriptPubKeyHex != null) {
      // check for cash tokens
      try {
        final ctOutput =
            cash_tokens.unwrap_spk(scriptPubKeyHex.toUint8ListFromHex);
        if (ctOutput.token_data != null) {
          // found a token!
          blocked = true;
          blockedReason = "Cash token output detected";
        }
      } catch (e, s) {
        // Probably doesn't contain a cash token so just log failure
        Logging.instance.w(
          "Script pub key \"$scriptPubKeyHex\" cash token"
          " parsing check failed: $e\n$s",
          error: e,
          stackTrace: s,
        );
      }

      // check for SLP tokens if not already blocked
      if (!blocked && BchUtils.isSLP(scriptPubKeyHex.toUint8ListFromHex)) {
        blocked = true;
        blockedReason = "SLP token output detected";
      }
    }

    return (blockedReason: blockedReason, blocked: blocked, utxoLabel: null);
  }

  // TODO: correct formula for ecash?
  @override
  Amount roughFeeEstimate(int inputCount, int outputCount, int feeRatePerKB) {
    return Amount(
      rawValue: BigInt.from(
        ((181 * inputCount) + (34 * outputCount) + 10) *
            (feeRatePerKB / 1000).ceil(),
      ),
      fractionDigits: info.coin.fractionDigits,
    );
  }

  @override
  int estimateTxFee({required int vSize, required int feeRatePerKB}) {
    return vSize * (feeRatePerKB / 1000).ceil();
  }

  @override
  String normalizeAddress(String address) {
    try {
      if (bitbox.Address.detectFormat(address) ==
          bitbox.Address.formatCashAddr) {
        return bitbox.Address.toLegacyAddress(address);
      } else {
        return address;
      }
    } catch (_) {
      return address;
    }
  }
}
