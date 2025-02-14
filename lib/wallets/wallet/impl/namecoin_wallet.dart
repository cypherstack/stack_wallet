import 'dart:convert';
import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:isar/isar.dart';
import 'package:namecoin/namecoin.dart';

import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../models/signing_data.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../../../utilities/enums/fee_rate_type_enum.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../../models/name_op_state.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_hd_wallet.dart';
import '../wallet_mixin_interfaces/coin_control_interface.dart';
import '../wallet_mixin_interfaces/cpfp_interface.dart';
import '../wallet_mixin_interfaces/electrumx_interface.dart';
import '../wallet_mixin_interfaces/rbf_interface.dart';

const kNameWaitBlocks = blocksMinToRenewName;
const kNameTxVersion = 0x7100;
const kNameTxDefaultFeeRate = FeeRateType.slow;

const kNameNewAmountSats = 150_0000;
const kNameAmountSats = 100_0000;

const _kNameSaltSplitter = r"$$$$";

String nameSaltKeyBuilder(String txid, String walletId, int txPos) {
  if (txPos.isNegative) {
    throw Exception("Invalid vout index");
  }

  return "${walletId}_${txid}_${txPos}nameSaltData";
}

String encodeNameSaltData(String name, String salt, String value) =>
    "$name$_kNameSaltSplitter$salt$_kNameSaltSplitter$value";
({String salt, String name, String value}) decodeNameSaltData(String value) {
  try {
    final split = value.split(_kNameSaltSplitter);
    return (salt: split[1], name: split[0], value: split[2]);
  } catch (_) {
    throw Exception("Bad name salt data");
  }
}

class NamecoinWallet<T extends ElectrumXCurrencyInterface>
    extends Bip39HDWallet<T>
    with ElectrumXInterface<T>, CoinControlInterface<T> {
  @override
  int get isarTransactionVersion => 2;

  NamecoinWallet(CryptoCurrencyNetwork network) : super(Namecoin(network) as T);

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
  Future<({String? blockedReason, bool blocked, String? utxoLabel})>
      checkBlockUTXO(
    Map<String, dynamic> jsonUTXO,
    String? scriptPubKeyHex,
    Map<String, dynamic> jsonTX,
    String? utxoOwnerAddress,
  ) {
    throw UnsupportedError(
      "Namecoin does not used the checkBlockUTXO() function. "
      "Due to tight integration with names, output freezing is handled directly"
      " in the overridden parseUTXO() function.",
    );
  }

  @override
  Future<UTXO> parseUTXO({
    required Map<String, dynamic> jsonUTXO,
  }) async {
    final txn = await electrumXCachedClient.getTransaction(
      txHash: jsonUTXO["tx_hash"] as String,
      verbose: true,
      cryptoCurrency: cryptoCurrency,
    );

    final inputs = txn["vin"] as List? ?? [];
    final isCoinbase = inputs.any((e) => (e as Map?)?["coinbase"] != null);

    final vout = jsonUTXO["tx_pos"] as int;

    final outputs = txn["vout"] as List;

    String? utxoOwnerAddress;

    bool shouldBlock = false;
    String? blockReason;
    String? label;
    String? otherDataString;

    for (final output in outputs) {
      // find matching output
      if (output["n"] == vout) {
        utxoOwnerAddress =
            output["scriptPubKey"]?["addresses"]?[0] as String? ??
                output["scriptPubKey"]?["address"] as String?;

        // check for nameOp
        if (output["scriptPubKey"]?["nameOp"] != null) {
          // block/freeze regardless of whether parsing the raw data succeeds
          shouldBlock = true;
          blockReason = "Contains name";

          try {
            final rawNameOP = (output["scriptPubKey"]["nameOp"] as Map)
                .cast<String, dynamic>();

            otherDataString = jsonEncode({
              UTXOOtherDataKeys.nameOpData: jsonEncode(rawNameOP),
            });
            final nameOp = OpNameData(
              rawNameOP,
              jsonUTXO["height"] as int,
            );
            Logging.instance.i(
              "nameOp:\n$nameOp",
            );

            switch (nameOp.op) {
              case OpName.nameNew:
                label = "Name New";
                break;
              case OpName.nameFirstUpdate:
                label = "Name First Update: ${nameOp.fullname}";
                break;
              case OpName.nameUpdate:
                label = "Name Update: ${nameOp.fullname}";
                break;
            }
          } catch (e, s) {
            Logging.instance.w(
              "Namecoin OpNameData failed to parse"
              " \"${output["scriptPubKey"]?["nameOp"]}\"",
              error: e,
              stackTrace: s,
            );
            label = "Failed to parse raw nameOp data";
          }
        }

        break;
      }
    }

    final utxo = UTXO(
      walletId: walletId,
      txid: txn["txid"] as String,
      vout: vout,
      value: jsonUTXO["value"] as int,
      name: label ?? "",
      isBlocked: shouldBlock,
      blockedReason: blockReason,
      isCoinbase: txn["is_coinbase"] as bool? ??
          txn["is-coinbase"] as bool? ??
          txn["iscoinbase"] as bool? ??
          isCoinbase,
      blockHash: txn["blockhash"] as String?,
      blockHeight: jsonUTXO["height"] as int?,
      blockTime: txn["blocktime"] as int?,
      address: utxoOwnerAddress,
      otherData: otherDataString,
    );

    return utxo;
  }

  @override
  int estimateTxFee({required int vSize, required int feeRatePerKB}) {
    return vSize * (feeRatePerKB / 1000).ceil();
  }

  // TODO: Check if this is the correct formula for namecoin.
  @override
  Amount roughFeeEstimate(int inputCount, int outputCount, int feeRatePerKB) {
    return Amount(
      rawValue: BigInt.from(
        ((42 + (272 * inputCount) + (128 * outputCount)) / 4).ceil() *
            (feeRatePerKB / 1000).ceil(),
      ),
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }

  @override
  Future<void> updateTransactions() async {
    // Get all addresses.
    final List<Address> allAddressesOld =
        await fetchAddressesForElectrumXScan();

    // Separate receiving and change addresses.
    final Set<String> receivingAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.receiving)
        .map((e) => e.value)
        .toSet();
    final Set<String> changeAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.change)
        .map((e) => e.value)
        .toSet();

    // Remove duplicates.
    final allAddressesSet = {...receivingAddresses, ...changeAddresses};

    // Fetch history from ElectrumX.
    final List<Map<String, dynamic>> allTxHashes =
        await fetchHistory(allAddressesSet);

    // Only parse new txs (not in db yet).
    final List<Map<String, dynamic>> allTransactions = [];
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

        if (coinbase == null) {
          // Not a coinbase (ie a typical input).
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
        OutputV2 output = OutputV2.fromElectrumXJson(
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
      const TransactionSubType subType = TransactionSubType.none;

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

          // Namecoin doesn't have special outputs like tokens, ordinals, etc.
          // But this is where you'd check for special outputs.
        }
      } else if (wasReceivedInThisWallet) {
        // Only found outputs owned by this wallet.
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

  // namecoin names ============================================================

  Future<({OpNameData? data, NameState nameState})> lookupName(
    String name,
  ) async {
    // first check own utxos. Should only need to check NAME NEW here.
    // NAME UPDATE and NAME FIRST UPDATE will appear readable from electrumx
    final utxos =
        await mainDB.getUTXOs(walletId).filter().otherDataIsNotNull().findAll();
    for (final utxo in utxos) {
      final nameOp = getOpNameDataFrom(utxo);
      if (nameOp?.op == OpName.nameNew) {
        Logging.instance.f(utxo);
        final sKey = nameSaltKeyBuilder(utxo.txid, walletId, utxo.vout);

        final encoded = await secureStorageInterface.read(key: sKey);
        if (encoded == null) {
          // seems this NAME NEW was created elsewhere
          continue;
        }

        final data = decodeNameSaltData(encoded);
        Logging.instance.e(
          data,
        );
        if (data.name == name) {
          return (
            data: null,
            nameState: NameState.unavailable,
          );
        }
      }
    }

    bool available = false;

    final nameScriptHash = nameIdentifierToScriptHash(name);

    final historyWithName = await electrumXClient.getHistory(
      scripthash: nameScriptHash,
    );
    OpNameData? opNameData;
    if (historyWithName.isNotEmpty) {
      final txHeight = historyWithName.last["height"] as int;
      final txHash = historyWithName.last["tx_hash"] as String;

      final txMap = await electrumXCachedClient.getTransaction(
        txHash: txHash,
        cryptoCurrency: cryptoCurrency,
      );

      try {
        opNameData = OpNameData.fromTx(txMap, txHeight);
        final isExpired = opNameData.expired(await chainHeight);

        Logging.instance.i(
          "Name $opNameData \nis expired = $isExpired",
        );
        available = isExpired;
      } catch (_) {
        available = false; // probably
      }
    } else {
      Logging.instance.i("Name \"$name\" not found.");
      available = true;
    }

    return (
      data: opNameData,
      nameState: available ? NameState.available : NameState.unavailable,
    );
  }

  // TODO: handle this differently?
  final Set<(int, String)> _unknownNameNewOutputs = {};

  /// Must be called in refresh() AFTER the wallet's UTXOs have been updated!
  Future<void> checkAutoRegisterNameNewOutputs() async {
    Logging.instance.t(
      "$walletId checkAutoRegisterNameNewOutputs()",
    );
    try {
      final currentHeight = await chainHeight;
      // not ideal filtering
      final utxos = await mainDB
          .getUTXOs(walletId)
          .filter()
          .otherDataIsNotNull()
          .and()
          .blockHeightIsNotNull()
          .and()
          .blockHeightGreaterThan(0)
          .and()
          .blockHeightLessThan(currentHeight - kNameWaitBlocks)
          .findAll();

      Logging.instance.t(
        "_unknownNameNewOutputs(count=${_unknownNameNewOutputs.length})"
        ":\n$_unknownNameNewOutputs",
      );

      // check cache and remove known auto unspendable name new outputs
      utxos.removeWhere(
        (e) => _unknownNameNewOutputs.contains((e.vout, e.txid)),
      );

      for (final utxo in utxos) {
        final nameOp = getOpNameDataFrom(utxo);
        if (nameOp != null) {
          Logging.instance.t(
            "Found OpName: $nameOp\n\nIN UTXO: $utxo",
          );

          if (nameOp.op == OpName.nameNew) {
            // at this point we should have an unspent UTXO that is at least
            // 12 blocks old which we can now do nameFirstUpdate on

            //TODO: Should check if name was registered by someone else here

            final sKey = nameSaltKeyBuilder(utxo.txid, walletId, utxo.vout);

            final encoded = await secureStorageInterface.read(key: sKey);
            if (encoded == null) {
              Logging.instance.d(
                "Found OpName NAME NEW utxo without local matching data."
                "\nUTXO: $utxo"
                "\nUnable to auto register.",
              );
              _unknownNameNewOutputs.add((utxo.vout, utxo.txid));
              continue;
            }

            final data = decodeNameSaltData(encoded);

            // verify cached matches
            final myAddress = await mainDB.getAddress(walletId, utxo.address!);
            final pk = await getPrivateKey(myAddress!);
            final generatedSalt = scriptNameNew(data.name, pk.data).$2;

            // TODO replace assert with proper error
            assert(generatedSalt == data.salt);

            final nameScriptHex = scriptNameFirstUpdate(
              data.name,
              data.value,
              data.salt,
            );

            TxData txData = TxData(
              utxos: {utxo},
              opNameState: NameOpState(
                name: data.name,
                saltHex: data.salt,
                commitment: "n/a",
                value: data.value,
                nameScriptHex: nameScriptHex,
                type: OpName.nameFirstUpdate,
                outputPosition: -1, //currently unknown, updated later
              ),
              feeRateType: kNameTxDefaultFeeRate, // TODO: make configurable?
              recipients: [
                (
                  address: (await getCurrentReceivingAddress())!.value,
                  isChange: false,
                  amount: Amount(
                    rawValue: BigInt.from(kNameAmountSats),
                    fractionDigits: cryptoCurrency.fractionDigits,
                  ),
                ),
              ],
            );

            // generate tx
            txData = await prepareNameSend(txData: txData);

            // broadcast tx
            txData = await confirmSend(txData: txData);

            // clear out value from local secure storage on successful registration
            await secureStorageInterface.delete(key: sKey);
          }
        }
      }
    } catch (e, s) {
      Logging.instance.e(
        "checkAutoRegisterNameNewOutputs() failed",
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Builds and signs a transaction
  Future<TxData> _createNameTx({
    required TxData txData,
    required List<SigningData> utxoSigningData,
    required bool isForFeeCalcPurposesOnly,
  }) async {
    Logging.instance.d("Starting _createNameTx ----------");

    assert(txData.recipients!.where((e) => !e.isChange).length == 1);

    if (!isForFeeCalcPurposesOnly) {
      final nameAmount =
          txData.recipients!.where((e) => !e.isChange).first.amount;

      switch (txData.opNameState!.type) {
        case OpName.nameNew:
          assert(
            nameAmount.raw == BigInt.from(kNameNewAmountSats),
          );
          break;
        case OpName.nameFirstUpdate || OpName.nameUpdate:
          assert(
            nameAmount.raw == BigInt.from(kNameAmountSats),
          );
          break;
      }
    }

    // temp tx data to show in gui while waiting for real data from server
    final List<InputV2> tempInputs = [];
    final List<OutputV2> tempOutputs = [];

    final List<coinlib.Output> prevOuts = [];

    coinlib.Transaction clTx = coinlib.Transaction(
      version: kNameTxVersion,
      inputs: [],
      outputs: [],
    );

    // TODO: [prio=high]: check this opt in rbf
    final sequence = this is RbfInterface && (this as RbfInterface).flagOptInRBF
        ? 0xffffffff - 10
        : 0xffffffff - 1;

    // Add transaction inputs
    for (int i = 0; i < utxoSigningData.length; i++) {
      final txid = utxoSigningData[i].utxo.txid;

      final hash = Uint8List.fromList(
        txid.toUint8ListFromHex.reversed.toList(),
      );

      final prevOutpoint = coinlib.OutPoint(
        hash,
        utxoSigningData[i].utxo.vout,
      );

      final prevOutput = coinlib.Output.fromAddress(
        BigInt.from(utxoSigningData[i].utxo.value),
        coinlib.Address.fromString(
          utxoSigningData[i].utxo.address!,
          cryptoCurrency.networkParams,
        ),
      );

      prevOuts.add(prevOutput);

      final coinlib.Input input;

      switch (utxoSigningData[i].derivePathType) {
        case DerivePathType.bip44:
          input = coinlib.P2PKHInput(
            prevOut: prevOutpoint,
            publicKey: utxoSigningData[i].keyPair!.publicKey,
            sequence: sequence,
          );

        // TODO: fix this as it is (probably) wrong!
        case DerivePathType.bip49:
          throw Exception("TODO p2sh");
        // input = coinlib.P2SHMultisigInput(
        //   prevOut: prevOutpoint,
        //   program: coinlib.MultisigProgram.decompile(
        //     utxoSigningData[i].redeemScript!,
        //   ),
        //   sequence: sequence,
        // );

        case DerivePathType.bip84:
          input = coinlib.P2WPKHInput(
            prevOut: prevOutpoint,
            publicKey: utxoSigningData[i].keyPair!.publicKey,
            sequence: sequence,
          );

        case DerivePathType.bip86:
          input = coinlib.TaprootKeyInput(prevOut: prevOutpoint);

        default:
          throw UnsupportedError(
            "Unknown derivation path type found: ${utxoSigningData[i].derivePathType}",
          );
      }

      clTx = clTx.addInput(input);

      tempInputs.add(
        InputV2.isarCantDoRequiredInDefaultConstructor(
          scriptSigHex: input.scriptSig.toHex,
          scriptSigAsm: null,
          sequence: sequence,
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

    int? nameOpVoutIndex;

    int nonChangeCount = 0; // sanity check counter. Should only hit 1.
    // Add transaction outputs
    for (int i = 0; i < txData.recipients!.length; i++) {
      final address = coinlib.Address.fromString(
        normalizeAddress(txData.recipients![i].address),
        cryptoCurrency.networkParams,
      );

      final coinlib.Output output;

      // there should only be 1 name output
      if (!txData.recipients![i].isChange) {
        nonChangeCount++;
        if (nonChangeCount > 1) {
          Logging.instance.d("Oddly formatted Name txData: $txData");
          throw Exception("Oddly formatted Name tx");
        }
        final scriptPubKey = address.program.script.compiled;
        output = coinlib.Output.fromScriptBytes(
          txData.recipients![i].amount.raw, // should be 0.015 or 0.01
          Uint8List.fromList(
            txData.opNameState!.nameScriptHex.toUint8ListFromHex + scriptPubKey,
          ),
        );
        // redundant sanity check
        if (nameOpVoutIndex != null) {
          throw Exception("More than one NAME OP output detected!");
        }
        nameOpVoutIndex = i;
      } else {
        // change output
        output = coinlib.Output.fromAddress(
          txData.recipients![i].amount.raw,
          address,
        );
      }

      clTx = clTx.addOutput(output);

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

    try {
      // Sign the transaction accordingly
      for (int i = 0; i < utxoSigningData.length; i++) {
        final value = BigInt.from(utxoSigningData[i].utxo.value);
        coinlib.ECPrivateKey key = utxoSigningData[i].keyPair!.privateKey;

        if (clTx.inputs[i] is coinlib.TaprootKeyInput) {
          final taproot = coinlib.Taproot(
            internalKey: utxoSigningData[i].keyPair!.publicKey,
          );

          key = taproot.tweakPrivateKey(key);
        }

        clTx = clTx.sign(
          inputN: i,
          value: value,
          key: key,
          prevOuts: prevOuts,
        );
      }
    } catch (e, s) {
      Logging.instance.e(
        "Caught exception while signing transaction: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }

    if (nameOpVoutIndex == null) {
      throw Exception("No NAME OP output detected!");
    }

    return txData.copyWith(
      raw: clTx.toHex(),
      vSize: clTx.vSize(),
      opNameState: txData.opNameState!.copyWith(
        outputPosition: nameOpVoutIndex,
      ),
      tempTx: TransactionV2(
        walletId: walletId,
        blockHash: null,
        hash: clTx.hashHex,
        txid: clTx.txid,
        height: null,
        timestamp: DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
        inputs: List.unmodifiable(tempInputs),
        outputs: List.unmodifiable(tempOutputs),
        version: clTx.version,
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

  Future<TxData> prepareNameSend({
    required TxData txData,
  }) async {
    try {
      if (txData.amount == null) {
        throw Exception("No recipients in attempted transaction!");
      }

      Logging.instance.t(
        "prepareNameSend called with TxData:\n\n$txData",
      );

      final feeRateType = txData.feeRateType;
      final customSatsPerVByte = txData.satsPerVByte;
      final feeRateAmount = txData.feeRateAmount;
      final utxos = txData.utxos;

      final bool coinControl = utxos != null;

      if (customSatsPerVByte != null) {
        final result = await coinSelectionName(
          txData: txData.copyWith(feeRateAmount: -1),
          utxos: utxos?.toList(),
          coinControl: coinControl,
        );

        Logging.instance.d("PREPARE NAME SEND RESULT: $result");

        if (result.fee!.raw.toInt() < result.vSize!) {
          throw Exception(
            "Error in fee calculation: Transaction fee cannot be less than vSize",
          );
        }

        return result;
      } else if (feeRateType is FeeRateType || feeRateAmount is int) {
        late final int rate;
        if (feeRateType is FeeRateType) {
          int fee = 0;
          final feeObject = await fees;
          switch (feeRateType) {
            case FeeRateType.fast:
              fee = feeObject.fast;
              break;
            case FeeRateType.average:
              fee = feeObject.medium;
              break;
            case FeeRateType.slow:
              fee = feeObject.slow;
              break;
            default:
              throw ArgumentError("Invalid use of custom fee");
          }
          rate = fee;
        } else {
          rate = feeRateAmount as int;
        }

        final result = await coinSelectionName(
          txData: txData.copyWith(
            feeRateAmount: rate,
          ),
          utxos: utxos?.toList(),
          coinControl: coinControl,
        );

        Logging.instance.d(
          "prepare send: $result",
        );
        if (result.fee!.raw.toInt() < result.vSize!) {
          throw Exception(
              "Error in fee calculation: Transaction fee (${result.fee!.raw.toInt()}) cannot "
              "be less than vSize (${result.vSize})");
        }

        return result;
      } else {
        throw ArgumentError("Invalid fee rate argument provided!");
      }
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from prepareNameSend(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<TxData> coinSelectionName({
    required TxData txData,
    required bool coinControl,
    int additionalOutputs = 0,
    List<UTXO>? utxos,
  }) async {
    Logging.instance.d("Starting coinSelectionName ----------");

    assert(txData.recipients!.length == 1);

    if (coinControl && utxos == null) {
      throw Exception("Coin control used where utxos is null!");
    }

    final recipientAddress = txData.recipients!.first.address;
    final satoshiAmountToSend = txData.amount!.raw;
    final int? satsPerVByte = txData.satsPerVByte;
    final selectedTxFeeRate = txData.feeRateAmount!;

    final int expectedSatsValue;
    switch (txData.opNameState!.type) {
      case OpName.nameNew:
        expectedSatsValue = kNameNewAmountSats;
        break;
      case OpName.nameFirstUpdate || OpName.nameUpdate:
        expectedSatsValue = kNameAmountSats;
        break;
    }

    if (satoshiAmountToSend != BigInt.from(expectedSatsValue)) {
      throw Exception(
        "Invalid Name amount for ${txData.opNameState!.type}: ${txData.amount}",
      );
    }

    final List<UTXO> availableOutputs =
        utxos ?? await mainDB.getUTXOs(walletId).findAll();
    final currentChainHeight = await chainHeight;

    final canCPFP = this is CpfpInterface && coinControl;

    int nameOutputCount = 0; // for sanity check. Should only be max 1;
    void nameOutputCountCheck() {
      nameOutputCount++;
      if (nameOutputCount > 1) {
        throw Exception("nameOutputCount greater than one");
      }
    }

    final List<UTXO> spendableOutputs;
    switch (txData.opNameState!.type) {
      case OpName.nameNew:
        spendableOutputs = availableOutputs
            .where(
              (e) =>
                  !e.isBlocked &&
                  (e.used != true) &&
                  (canCPFP ||
                      e.isConfirmed(
                        currentChainHeight,
                        cryptoCurrency.minConfirms,
                        cryptoCurrency.minCoinbaseConfirms,
                      )),
            )
            .toList();
        break;

      case OpName.nameFirstUpdate:
        spendableOutputs = availableOutputs.where(
          (e) {
            if (e.used == true) return false;

            final nameOp = getOpNameDataFrom(e);
            if (nameOp != null) {
              if (nameOp.op == OpName.nameFirstUpdate ||
                  nameOp.op == OpName.nameUpdate) {
                return false;
              } else {
                final confirmed = e.isConfirmed(
                  currentChainHeight,
                  cryptoCurrency.minConfirms,
                  cryptoCurrency.minCoinbaseConfirms,
                  overrideMinConfirms: kNameWaitBlocks,
                );

                if (confirmed) {
                  nameOutputCountCheck();
                }
                return confirmed;
              }
            } else {
              return canCPFP ||
                  e.isConfirmed(
                    currentChainHeight,
                    cryptoCurrency.minConfirms,
                    cryptoCurrency.minCoinbaseConfirms,
                  );
            }
          },
        ).toList();
        break;

      case OpName.nameUpdate:
        spendableOutputs = availableOutputs.where(
          (e) {
            if (e.used == true) return false;

            final nameOp = getOpNameDataFrom(e);
            if (nameOp != null) {
              if (nameOp.op == OpName.nameFirstUpdate ||
                  nameOp.op == OpName.nameUpdate) {
                final confirmed = e.isConfirmed(
                  currentChainHeight,
                  cryptoCurrency.minConfirms,
                  cryptoCurrency.minCoinbaseConfirms,
                  overrideMinConfirms: kNameWaitBlocks,
                );

                if (confirmed) {
                  nameOutputCountCheck();
                }
                return confirmed;
              } else {
                return false;
              }
            } else {
              return canCPFP ||
                  e.isConfirmed(
                    currentChainHeight,
                    cryptoCurrency.minConfirms,
                    cryptoCurrency.minCoinbaseConfirms,
                  );
            }
          },
        ).toList();
        break;
    }

    final spendableSatoshiValue =
        spendableOutputs.fold(BigInt.zero, (p, e) => p + BigInt.from(e.value));

    if (spendableSatoshiValue < satoshiAmountToSend) {
      throw Exception("Insufficient balance");
    } else if (spendableSatoshiValue == satoshiAmountToSend) {
      throw Exception("Insufficient balance to pay transaction fee");
    }

    if (coinControl) {
      if (spendableOutputs.length < availableOutputs.length) {
        throw ArgumentError("Attempted to use an unavailable utxo");
      }
      // don't care about sorting if using all utxos
    } else {
      // sort spendable by age (oldest first)
      spendableOutputs.sort(
        (a, b) => (b.blockTime ?? currentChainHeight)
            .compareTo((a.blockTime ?? currentChainHeight)),
      );
    }

    Logging.instance.d(
      "spendableOutputs.length: ${spendableOutputs.length}"
      "\navailableOutputs.length: ${availableOutputs.length}"
      "\nspendableOutputs: $spendableOutputs"
      "\nspendableSatoshiValue: $spendableSatoshiValue"
      "\nsatoshiAmountToSend: $satoshiAmountToSend",
    );

    BigInt satoshisBeingUsed = BigInt.zero;
    int inputsBeingConsumed = 0;
    final List<UTXO> utxoObjectsToUse = [];

    if (!coinControl) {
      for (int i = 0;
          satoshisBeingUsed < satoshiAmountToSend &&
              i < spendableOutputs.length;
          i++) {
        utxoObjectsToUse.add(spendableOutputs[i]);
        satoshisBeingUsed += BigInt.from(spendableOutputs[i].value);
        inputsBeingConsumed += 1;
      }
      for (int i = 0;
          i < additionalOutputs &&
              inputsBeingConsumed < spendableOutputs.length;
          i++) {
        utxoObjectsToUse.add(spendableOutputs[inputsBeingConsumed]);
        satoshisBeingUsed +=
            BigInt.from(spendableOutputs[inputsBeingConsumed].value);
        inputsBeingConsumed += 1;
      }
    } else {
      satoshisBeingUsed = spendableSatoshiValue;
      utxoObjectsToUse.addAll(spendableOutputs);
      inputsBeingConsumed = spendableOutputs.length;
    }

    Logging.instance.d(
      "satoshisBeingUsed: $satoshisBeingUsed"
      "\ninputsBeingConsumed: $inputsBeingConsumed"
      "\nutxoObjectsToUse: $utxoObjectsToUse",
    );

    // numberOfOutputs' length must always be equal to that of recipientsArray and recipientsAmtArray
    final List<String> recipientsArray = [recipientAddress];
    final List<BigInt> recipientsAmtArray = [satoshiAmountToSend];

    // gather required signing data
    final utxoSigningData = await fetchBuildTxData(utxoObjectsToUse);

    final int vSizeForOneOutput;
    try {
      vSizeForOneOutput = (await _createNameTx(
        utxoSigningData: utxoSigningData,
        isForFeeCalcPurposesOnly: true,
        txData: txData.copyWith(
          recipients: await helperRecipientsConvert(
            [recipientAddress],
            [satoshisBeingUsed],
          ),
        ),
      ))
          .vSize!;
    } catch (e, s) {
      Logging.instance.e("vSizeForOneOutput: $e", error: e, stackTrace: s);
      rethrow;
    }

    final int vSizeForTwoOutPuts;

    BigInt maxBI(BigInt a, BigInt b) => a > b ? a : b;

    try {
      vSizeForTwoOutPuts = (await _createNameTx(
        utxoSigningData: utxoSigningData,
        isForFeeCalcPurposesOnly: true,
        txData: txData.copyWith(
          recipients: await helperRecipientsConvert(
            [recipientAddress, (await getCurrentChangeAddress())!.value],
            [
              satoshiAmountToSend,
              maxBI(
                BigInt.zero,
                satoshisBeingUsed - satoshiAmountToSend,
              ),
            ],
          ),
        ),
      ))
          .vSize!;
    } catch (e, s) {
      Logging.instance.e("vSizeForTwoOutPuts: $e", error: e, stackTrace: s);
      rethrow;
    }

    // Assume 1 output, only for recipient and no change
    final feeForOneOutput = BigInt.from(
      satsPerVByte != null
          ? (satsPerVByte * vSizeForOneOutput)
          : estimateTxFee(
              vSize: vSizeForOneOutput,
              feeRatePerKB: selectedTxFeeRate,
            ),
    );
    // Assume 2 outputs, one for recipient and one for change
    final feeForTwoOutputs = BigInt.from(
      satsPerVByte != null
          ? (satsPerVByte * vSizeForTwoOutPuts)
          : estimateTxFee(
              vSize: vSizeForTwoOutPuts,
              feeRatePerKB: selectedTxFeeRate,
            ),
    );

    Logging.instance.d(
      "feeForTwoOutputs: $feeForTwoOutputs"
      "\nfeeForOneOutput: $feeForOneOutput",
    );

    final difference = satoshisBeingUsed - satoshiAmountToSend;

    Future<TxData> _singleOutputTxn() async {
      Logging.instance.d(
        'Input size: $satoshisBeingUsed'
        '\nRecipient output size: $satoshiAmountToSend'
        '\nFee being paid: $difference sats'
        '\nEstimated fee: $feeForOneOutput',
      );
      final txnData = await _createNameTx(
        isForFeeCalcPurposesOnly: false,
        utxoSigningData: utxoSigningData,
        txData: txData.copyWith(
          recipients: await helperRecipientsConvert(
            recipientsArray,
            recipientsAmtArray,
          ),
        ),
      );
      return txnData.copyWith(
        fee: Amount(
          rawValue: feeForOneOutput,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        usedUTXOs: utxoSigningData.map((e) => e.utxo).toList(),
      );
    }

    // no change output required
    if (difference == feeForOneOutput) {
      Logging.instance.d('1 output in tx');
      return await _singleOutputTxn();
    } else if (difference < feeForOneOutput) {
      Logging.instance.w(
        'Cannot pay tx fee - checking for more outputs and trying again',
      );
      // try adding more outputs
      if (spendableOutputs.length > inputsBeingConsumed) {
        return coinSelectionName(
          txData: txData,
          additionalOutputs: additionalOutputs + 1,
          utxos: utxos,
          coinControl: coinControl,
        );
      }
      throw Exception("Insufficient balance to pay transaction fee");
    } else {
      if (difference > (feeForOneOutput + cryptoCurrency.dustLimit.raw)) {
        final changeOutputSize = difference - feeForTwoOutputs;
        // check if possible to add the change output
        if (changeOutputSize > cryptoCurrency.dustLimit.raw &&
            difference - changeOutputSize == feeForTwoOutputs) {
          // generate new change address if current change address has been used
          await checkChangeAddressForTransactions();
          final String newChangeAddress =
              (await getCurrentChangeAddress())!.value;

          BigInt feeBeingPaid = difference - changeOutputSize;

          // add change output
          recipientsArray.add(newChangeAddress);
          recipientsAmtArray.add(changeOutputSize);

          Logging.instance.d('2 outputs in tx'
              '\nInput size: $satoshisBeingUsed'
              '\nRecipient output size: $satoshiAmountToSend'
              '\nChange Output Size: $changeOutputSize'
              '\nDifference (fee being paid): $feeBeingPaid sats'
              '\nEstimated fee: $feeForTwoOutputs');

          TxData txnData = await _createNameTx(
            utxoSigningData: utxoSigningData,
            isForFeeCalcPurposesOnly: false,
            txData: txData.copyWith(
              recipients: await helperRecipientsConvert(
                recipientsArray,
                recipientsAmtArray,
              ),
            ),
          );

          // make sure minimum fee is accurate if that is being used
          if (BigInt.from(txnData.vSize!) - feeBeingPaid == BigInt.one) {
            final changeOutputSize = difference - BigInt.from(txnData.vSize!);
            feeBeingPaid = difference - changeOutputSize;
            recipientsAmtArray.removeLast();
            recipientsAmtArray.add(changeOutputSize);

            Logging.instance.d(
              '\nAdjusted Input size: $satoshisBeingUsed'
              '\nAdjusted Recipient output size: $satoshiAmountToSend'
              '\nAdjusted Change Output Size: $changeOutputSize'
              '\nAdjusted Difference (fee being paid): $feeBeingPaid sats'
              '\nAdjusted Estimated fee: $feeForTwoOutputs',
            );

            txnData = await _createNameTx(
              utxoSigningData: utxoSigningData,
              isForFeeCalcPurposesOnly: false,
              txData: txData.copyWith(
                recipients: await helperRecipientsConvert(
                  recipientsArray,
                  recipientsAmtArray,
                ),
              ),
            );
          }

          return txnData.copyWith(
            fee: Amount(
              rawValue: feeBeingPaid,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            usedUTXOs: utxoSigningData.map((e) => e.utxo).toList(),
          );
        } else {
          // Something went wrong here. It either overshot or undershot the estimated fee amount or the changeOutputSize
          // is smaller than or equal to cryptoCurrency.dustLimit. Revert to single output transaction.
          Logging.instance.d(
            'Reverting to 1 output in tx',
          );

          return await _singleOutputTxn();
        }
      }
    }

    return txData;
  }

  /// return null if utxo does not contain name op
  OpNameData? getOpNameDataFrom(UTXO utxo) {
    if (utxo.otherData == null) {
      return null;
    }
    final otherData = jsonDecode(utxo.otherData!) as Map;
    if (otherData[UTXOOtherDataKeys.nameOpData] != null) {
      try {
        final nameOp = OpNameData(
          (jsonDecode(otherData[UTXOOtherDataKeys.nameOpData] as String) as Map)
              .cast(),
          utxo.blockHeight!,
        );
        return nameOp;
      } catch (e, s) {
        Logging.instance.d(
          "getOpNameDataFrom($utxo) failed",
          error: e,
          stackTrace: s,
        );
        return null;
      }
    }
    return null;
  }

  bool checkUtxoConfirmed(UTXO utxo, int currentChainHeight) {
    final isNameOpOutput = getOpNameDataFrom(utxo) != null;

    final confirmedStatus = utxo.isConfirmed(
      currentChainHeight,
      cryptoCurrency.minConfirms,
      cryptoCurrency.minCoinbaseConfirms,
      overrideMinConfirms: isNameOpOutput ? kNameWaitBlocks : null,
    );
    return confirmedStatus;
  }
}

enum NameState {
  available,
  unavailable;
}
