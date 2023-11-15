import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/input_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/output_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/services/coins/bitcoincash/bch_utils.dart';
import 'package:stackwallet/services/coins/bitcoincash/cashtokens.dart'
    as cash_tokens;
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/bitcoincash.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_hd_wallet.dart';
import 'package:stackwallet/wallets/wallet/mixins/cash_fusion.dart';
import 'package:stackwallet/wallets/wallet/mixins/coin_control.dart';
import 'package:stackwallet/wallets/wallet/mixins/electrumx.dart';

class BitcoincashWallet extends Bip39HDWallet
    with ElectrumX, CoinControl, CashFusion {
  @override
  int get isarTransactionVersion => 2;

  BitcoincashWallet(CryptoCurrencyNetwork network)
      : super(Bitcoincash(network));

  @override
  FilterOperation? get changeAddressFilterOperation => FilterGroup.and(
        [
          ...standardChangeAddressFilters,
          FilterGroup.not(
            const ObjectFilter(
              property: "derivationPath",
              filter: FilterCondition.startsWith(
                property: "value",
                value: "m/44'/0'",
              ),
            ),
          ),
        ],
      );

  @override
  FilterOperation? get receivingAddressFilterOperation => FilterGroup.and(
        [
          ...standardReceivingAddressFilters,
          FilterGroup.not(
            const ObjectFilter(
              property: "derivationPath",
              filter: FilterCondition.startsWith(
                property: "value",
                value: "m/44'/0'",
              ),
            ),
          ),
        ],
      );

  // ===========================================================================

  @override
  Future<List<Address>> fetchAllOwnAddresses() async {
    final allAddresses = await mainDB
        .getAddresses(walletId)
        .filter()
        .not()
        .typeEqualTo(AddressType.nonWallet)
        .and()
        .group((q) => q
            .subTypeEqualTo(AddressSubType.receiving)
            .or()
            .subTypeEqualTo(AddressSubType.change))
        .findAll();
    return allAddresses;
  }

  @override
  String convertAddressString(String address) {
    if (bitbox.Address.detectFormat(address) == bitbox.Address.formatLegacy &&
        (cryptoCurrency.addressType(address: address) == DerivePathType.bip44 ||
            cryptoCurrency.addressType(address: address) ==
                DerivePathType.bch44)) {
      return bitbox.Address.toCashAddress(address);
    } else {
      return address;
    }
  }

  // ===========================================================================

  @override
  Future<void> updateTransactions() async {
    List<Address> allAddressesOld = await fetchAllOwnAddresses();

    Set<String> receivingAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.receiving)
        .map((e) => convertAddressString(e.value))
        .toSet();

    Set<String> changeAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.change)
        .map((e) => convertAddressString(e.value))
        .toSet();

    final allAddressesSet = {...receivingAddresses, ...changeAddresses};

    final List<Map<String, dynamic>> allTxHashes =
        await fetchHistory(allAddressesSet);

    List<Map<String, dynamic>> allTransactions = [];

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
          coin: cryptoCurrency.coin,
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
            coin: cryptoCurrency.coin,
          );

          final prevOutJson = Map<String, dynamic>.from(
              (inputTx["vout"] as List).firstWhere((e) => e["n"] == vout)
                  as Map);

          final prevOut = OutputV2.fromElectrumXJson(
            prevOutJson,
            decimalPlaces: cryptoCurrency.fractionDigits,
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
        Logging.instance.log(
          "Unexpected tx found (ignoring it): $txData",
          level: LogLevel.Error,
        );
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
      );

      txns.add(tx);
    }

    await mainDB.updateOrPutTransactionV2s(txns);
  }

  @override
  ({String? blockedReason, bool blocked}) checkBlockUTXO(
    Map<String, dynamic> jsonUTXO,
    String? scriptPubKeyHex,
    Map<String, dynamic> jsonTX,
  ) {
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
        Logging.instance.log(
          "Script pub key \"$scriptPubKeyHex\" cash token"
          " parsing check failed: $e\n$s",
          level: LogLevel.Warning,
        );
      }

      // check for SLP tokens if not already blocked
      if (!blocked && BchUtils.isSLP(scriptPubKeyHex.toUint8ListFromHex)) {
        blocked = true;
        blockedReason = "SLP token output detected";
      }
    }

    return (blockedReason: blockedReason, blocked: blocked);
  }

  // TODO: correct formula for bch?
  @override
  Amount roughFeeEstimate(int inputCount, int outputCount, int feeRatePerKB) {
    return Amount(
      rawValue: BigInt.from(((181 * inputCount) + (34 * outputCount) + 10) *
          (feeRatePerKB / 1000).ceil()),
      fractionDigits: info.coin.decimals,
    );
  }

  @override
  int estimateTxFee({required int vSize, required int feeRatePerKB}) {
    return vSize * (feeRatePerKB / 1000).ceil();
  }
}
