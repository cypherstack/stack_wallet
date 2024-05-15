import 'dart:typed_data';

import 'package:bitcoindart/bitcoindart.dart' as bitcoindart;
import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/input_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/output_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/signing_data.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/utilities/extensions/impl/uint8_list.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/particl.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/interfaces/electrumx_currency_interface.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_hd_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/coin_control_interface.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';

class ParticlWallet<T extends ElectrumXCurrencyInterface>
    extends Bip39HDWallet<T>
    with ElectrumXInterface<T>, CoinControlInterface<T> {
  @override
  int get isarTransactionVersion => 2;

  ParticlWallet(CryptoCurrencyNetwork network) : super(Particl(network) as T);

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
  Future<
      ({
        bool blocked,
        String? blockedReason,
        String? utxoLabel,
      })> checkBlockUTXO(
    Map<String, dynamic> jsonUTXO,
    String? scriptPubKeyHex,
    Map<String, dynamic> jsonTX,
    String? utxoOwnerAddress,
  ) async {
    bool blocked = false;
    String? blockedReason;
    String? utxoLabel;

    final outputs = jsonTX["vout"] as List? ?? [];

    for (final output in outputs) {
      if (output is Map) {
        if (output['ct_fee'] != null) {
          // Blind output, ignore for now.
          blocked = true;
          blockedReason = "Blind output.";
          utxoLabel = "Unsupported output type.";
        } else if (output['rangeproof'] != null) {
          // Private RingCT output, ignore for now.
          blocked = true;
          blockedReason = "Confidential output.";
          utxoLabel = "Unsupported output type.";
        } else if (output['data_hex'] != null) {
          // Data output, ignore for now.
          blocked = true;
          blockedReason = "Data output.";
          utxoLabel = "Unsupported output type.";
        } else if (output['scriptPubKey'] != null) {
          if (output['scriptPubKey']?['asm'] is String &&
              (output['scriptPubKey']['asm'] as String)
                  .contains("OP_ISCOINSTAKE")) {
            blocked = true;
            blockedReason = "Spending staking";
            utxoLabel = "Unsupported output type.";
          }
        }
      }
    }

    return (
      blocked: blocked,
      blockedReason: blockedReason,
      utxoLabel: utxoLabel
    );
  }

  @override
  int estimateTxFee({required int vSize, required int feeRatePerKB}) {
    return vSize * (feeRatePerKB / 1000).ceil();
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
  Future<void> updateTransactions() async {
    // Get all addresses.
    List<Address> allAddressesOld = await fetchAddressesForElectrumXScan();

    // Separate receiving and change addresses.
    Set<String> receivingAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.receiving)
        .map((e) => e.value)
        .toSet();
    Set<String> changeAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.change)
        .map((e) => e.value)
        .toSet();

    // Remove duplicates.
    final allAddressesSet = {...receivingAddresses, ...changeAddresses};

    // Fetch history from ElectrumX.
    final List<Map<String, dynamic>> allTxHashes =
        await fetchHistory(allAddressesSet);

    // Only parse new txs (not in db yet).
    List<Map<String, dynamic>> allTransactions = [];
    for (final txHash in allTxHashes) {
      // Check for duplicates by searching for tx by tx_hash in db.
      final storedTx = await mainDB.isar.transactionV2s
          .where()
          .txidWalletIdEqualTo(txHash["tx_hash"] as String, walletId)
          .findFirst();

      if (storedTx == null ||
          storedTx.height == null ||
          (storedTx.height != null && storedTx.height! <= 0)) {
        // Tx not in db yet.
        final tx = await electrumXCachedClient.getTransaction(
          txHash: txHash["tx_hash"] as String,
          verbose: true,
          cryptoCurrency: cryptoCurrency,
        );

        // Only tx to list once.
        if (allTransactions
                .indexWhere((e) => e["txid"] == tx["txid"] as String) ==
            -1) {
          tx["height"] = txHash["height"];
          allTransactions.add(tx);
        }
      }
    }

    // Parse all new txs.
    final List<TransactionV2> txns = [];
    for (final txData in allTransactions) {
      bool wasSentFromThisWallet = false;
      // Set to true if any inputs were detected as owned by this wallet.

      bool wasReceivedInThisWallet = false;
      // Set to true if any outputs were detected as owned by this wallet.

      // Parse inputs.
      BigInt amountReceivedInThisWallet = BigInt.zero;
      BigInt changeAmountReceivedInThisWallet = BigInt.zero;
      final List<InputV2> inputs = [];
      for (final jsonInput in txData["vin"] as List) {
        final map = Map<String, dynamic>.from(jsonInput as Map);

        final List<String> addresses = [];
        String valueStringSats = "0";
        OutpointV2? outpoint;

        final coinbase = map["coinbase"] as String?;
        final txType = map['type'] as String?;
        if (coinbase == null && txType == null) {
          // Not a coinbase (ie a typical input).
          final txid = map["txid"] as String;
          final vout = map["vout"] as int;

          final inputTx = await electrumXCachedClient.getTransaction(
            txHash: txid,
            cryptoCurrency: cryptoCurrency,
          );

          final prevOutJson = Map<String, dynamic>.from(
              (inputTx["vout"] as List).firstWhere((e) => e["n"] == vout)
                  as Map);

          final prevOut = _parseOutput(
            prevOutJson,
            decimalPlaces: cryptoCurrency.fractionDigits,
            isFullAmountNotSats: true,
            walletOwns: false, // Doesn't matter here as this is not saved.
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
          // Need addresses before we can know if the wallet owns this input.
          walletOwns: false,
        );

        // Check if input was from this wallet.
        if (allAddressesSet.intersection(input.addresses.toSet()).isNotEmpty) {
          wasSentFromThisWallet = true;
          input = input.copyWith(walletOwns: true);
        }

        inputs.add(input);
      }

      // Parse outputs.
      final List<OutputV2> outputs = [];
      for (final outputJson in txData["vout"] as List) {
        OutputV2 output = _parseOutput(
          Map<String, dynamic>.from(outputJson as Map),
          decimalPlaces: cryptoCurrency.fractionDigits,
          isFullAmountNotSats: true,
          // Need addresses before we can know if the wallet owns this input.
          walletOwns: false,
        );

        // If output was to my wallet, add value to amount received.
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

      // Particl has special outputs like confidential amounts. We can check
      // for them here.  They're also checked in checkBlockUTXO.

      // At least one input was owned by this wallet.
      if (wasSentFromThisWallet) {
        type = TransactionType.outgoing;

        if (wasReceivedInThisWallet) {
          if (changeAmountReceivedInThisWallet + amountReceivedInThisWallet ==
              totalOut) {
            // Definitely sent all to self.
            type = TransactionType.sentToSelf;
          } else if (amountReceivedInThisWallet == BigInt.zero) {
            // Most likely just a typical send, do nothing here yet.
          }
        }
      } else if (wasReceivedInThisWallet) {
        // Only found outputs owned by this wallet.
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
        otherData: null,
      );

      txns.add(tx);
    }

    await mainDB.updateOrPutTransactionV2s(txns);
  }

  /// Builds and signs a transaction.
  @override
  Future<TxData> buildTransaction({
    required TxData txData,
    required List<SigningData> utxoSigningData,
  }) async {
    Logging.instance.log("Starting Particl buildTransaction ----------",
        level: LogLevel.Info);

    // TODO: use coinlib (For this we need coinlib to support particl)

    final convertedNetwork = bitcoindart.NetworkType(
      messagePrefix: cryptoCurrency.networkParams.messagePrefix,
      bech32: cryptoCurrency.networkParams.bech32Hrp,
      bip32: bitcoindart.Bip32Type(
        public: cryptoCurrency.networkParams.pubHDPrefix,
        private: cryptoCurrency.networkParams.privHDPrefix,
      ),
      pubKeyHash: cryptoCurrency.networkParams.p2pkhPrefix,
      scriptHash: cryptoCurrency.networkParams.p2shPrefix,
      wif: cryptoCurrency.networkParams.wifPrefix,
    );

    final List<({Uint8List? output, Uint8List? redeem})> extraData = [];
    for (int i = 0; i < utxoSigningData.length; i++) {
      final sd = utxoSigningData[i];

      final pubKey = sd.keyPair!.publicKey.data;
      final bitcoindart.PaymentData? data;
      Uint8List? redeem, output;

      switch (sd.derivePathType) {
        case DerivePathType.bip44:
          data = bitcoindart
              .P2PKH(
                data: bitcoindart.PaymentData(
                  pubkey: pubKey,
                ),
                network: convertedNetwork,
              )
              .data;
          break;

        case DerivePathType.bip49:
          final p2wpkh = bitcoindart
              .P2WPKH(
                data: bitcoindart.PaymentData(
                  pubkey: pubKey,
                ),
                network: convertedNetwork,
              )
              .data;
          redeem = p2wpkh.output;
          data = bitcoindart
              .P2SH(
                data: bitcoindart.PaymentData(redeem: p2wpkh),
                network: convertedNetwork,
              )
              .data;
          break;

        case DerivePathType.bip84:
          // input = coinlib.P2WPKHInput(
          //   prevOut: coinlib.OutPoint.fromHex(sd.utxo.txid, sd.utxo.vout),
          //   publicKey: keys.publicKey,
          // );
          data = bitcoindart
              .P2WPKH(
                data: bitcoindart.PaymentData(
                  pubkey: pubKey,
                ),
                network: convertedNetwork,
              )
              .data;
          break;

        case DerivePathType.bip86:
          data = null;
          break;

        default:
          throw Exception("DerivePathType unsupported");
      }

      // sd.output = input.script!.compiled;

      if (sd.derivePathType != DerivePathType.bip86) {
        output = data!.output!;
      }

      extraData.add((output: output, redeem: redeem));
    }

    final txb = bitcoindart.TransactionBuilder(
      network: convertedNetwork,
    );
    const version = 160; // buildTransaction overridden for Particl to set this.
    // TODO: [prio=low] refactor overridden buildTransaction to use eg. cryptocurrency.networkParams.txVersion.
    txb.setVersion(version);

    // Temp tx data for GUI while waiting for real tx from server.
    final List<InputV2> tempInputs = [];
    final List<OutputV2> tempOutputs = [];

    // Add inputs.
    for (var i = 0; i < utxoSigningData.length; i++) {
      final txid = utxoSigningData[i].utxo.txid;
      txb.addInput(
        txid,
        utxoSigningData[i].utxo.vout,
        null,
        extraData[i].output!,
        cryptoCurrency.networkParams.bech32Hrp,
      );

      tempInputs.add(
        InputV2.isarCantDoRequiredInDefaultConstructor(
          scriptSigHex: txb.inputs.first.script?.toHex,
          scriptSigAsm: null,
          sequence: 0xffffffff - 1,
          outpoint: OutpointV2.isarCantDoRequiredInDefaultConstructor(
            txid: utxoSigningData[i].utxo.txid,
            vout: utxoSigningData[i].utxo.vout,
          ),
          addresses: utxoSigningData[i].utxo.address == null
              ? []
              : [utxoSigningData[i].utxo.address!],
          valueStringSats: utxoSigningData[i].utxo.value.toString(),
          witness: null,
          innerRedeemScriptAsm: null,
          coinbase: null,
          walletOwns: true,
        ),
      );
    }

    // Add outputs.
    for (var i = 0; i < txData.recipients!.length; i++) {
      txb.addOutput(
        txData.recipients![i].address,
        txData.recipients![i].amount.raw.toInt(),
        cryptoCurrency.networkParams.bech32Hrp,
      );

      tempOutputs.add(
        OutputV2.isarCantDoRequiredInDefaultConstructor(
          scriptPubKeyHex: "000000",
          valueStringSats: txData.recipients![i].amount.raw.toString(),
          addresses: [
            txData.recipients![i].address.toString(),
          ],
          walletOwns: (await mainDB.isar.addresses
                  .where()
                  .walletIdEqualTo(walletId)
                  .filter()
                  .valueEqualTo(txData.recipients![i].address)
                  .valueProperty()
                  .findFirst()) !=
              null,
        ),
      );
    }

    // Sign.
    try {
      for (var i = 0; i < utxoSigningData.length; i++) {
        txb.sign(
          vin: i,
          keyPair: bitcoindart.ECPair.fromPrivateKey(
            utxoSigningData[i].keyPair!.privateKey.data,
            network: convertedNetwork,
            compressed: utxoSigningData[i].keyPair!.privateKey.compressed,
          ),
          witnessValue: utxoSigningData[i].utxo.value,
          redeemScript: extraData[i].redeem,
          overridePrefix: cryptoCurrency.networkParams.bech32Hrp,
        );
      }
    } catch (e, s) {
      Logging.instance.log("Caught exception while signing transaction: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }

    final builtTx = txb.build(cryptoCurrency.networkParams.bech32Hrp);
    final vSize = builtTx.virtualSize();

    // Strip trailing 0x00 bytes from hex.
    //
    // This is done to match the previous particl_wallet implementation.
    // TODO: [prio=low] Rework Particl tx construction so as to obviate this.
    String hexString = builtTx.toHex(isParticl: true).toString();
    if (hexString.length % 2 != 0) {
      // Ensure the string has an even length.
      Logging.instance.log("Hex string has odd length, which is unexpected.",
          level: LogLevel.Error);
      throw Exception("Invalid hex string length.");
    }
    // int maxStrips = 3; // Strip up to 3 0x00s (match previous particl_wallet).
    while (hexString.endsWith('00') && hexString.length > 2) {
      hexString = hexString.substring(0, hexString.length - 2);
      // maxStrips--;
      // if (maxStrips <= 0) {
      //   break;
      // }
    }

    return txData.copyWith(
      raw: hexString,
      vSize: vSize,
      tempTx: null,
      //  builtTx.getId() requires an isParticl flag as well but the lib does not support that yet
      // tempTx: TransactionV2(
      //   walletId: walletId,
      //   blockHash: null,
      //   hash: builtTx.getId(),
      //   txid: builtTx.getId(),
      //   height: null,
      //   timestamp: DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
      //   inputs: List.unmodifiable(tempInputs),
      //   outputs: List.unmodifiable(tempOutputs),
      //   version: version,
      //   type: tempOutputs.map((e) => e.walletOwns).fold(true, (p, e) => p &= e)
      //       ? TransactionType.sentToSelf
      //       : TransactionType.outgoing,
      //   subType: TransactionSubType.none,
      //   otherData: null,
      // ),
    );
  }

  /// OutputV2.fromElectrumXJson wrapper for Particl-specific outputs.
  OutputV2 _parseOutput(
    Map<String, dynamic> json, {
    // Other params just passed thru to fromElectrumXJson for transparent outs.
    required bool walletOwns,
    required bool isFullAmountNotSats,
    required int decimalPlaces,
  }) {
    // TODO: [prio=med] Confirm that all the tx types below are handled well.
    // Right now we essentially ignore txs with ct_fee, rangeproof, or data_hex
    // keys.  We may also want to set walletOwns to true (if we know the owner).
    if (json.containsKey('ct_fee')) {
      // Blind output, ignore for now.
      return OutputV2.isarCantDoRequiredInDefaultConstructor(
        scriptPubKeyHex: '',
        valueStringSats: '0',
        addresses: [],
        walletOwns: false,
      );
    } else if (json.containsKey('rangeproof')) {
      // Private RingCT output, ignore for now.
      return OutputV2.isarCantDoRequiredInDefaultConstructor(
        scriptPubKeyHex: '',
        valueStringSats: '0',
        addresses: [],
        walletOwns: false,
      );
    } else if (json.containsKey('data_hex')) {
      // Data output, ignore for now.
      return OutputV2.isarCantDoRequiredInDefaultConstructor(
        scriptPubKeyHex: '',
        valueStringSats: '0',
        addresses: [],
        walletOwns: false,
      );
    } else if (json.containsKey('scriptPubKey')) {
      // Transparent output.
      return OutputV2.fromElectrumXJson(
        json,
        walletOwns: walletOwns,
        isFullAmountNotSats: isFullAmountNotSats,
        decimalPlaces: decimalPlaces,
      );
    } else {
      throw Exception("Unknown output type: $json");
    }
  }
}
