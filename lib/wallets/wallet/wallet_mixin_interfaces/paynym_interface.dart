import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip47/bip47.dart';
import 'package:bitcoindart/bitcoindart.dart' as btc_dart;
import 'package:bitcoindart/src/utils/constants/op.dart' as op;
import 'package:bitcoindart/src/utils/script.dart' as bscript;
import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:isar/isar.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:tuple/tuple.dart';

import '../../../exceptions/wallet/insufficient_balance_exception.dart';
import '../../../exceptions/wallet/paynym_send_exception.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../models/signing_data.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/bip32_utils.dart';
import '../../../utilities/bip47_utils.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/format.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../crypto_currency/interfaces/paynym_currency_interface.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_hd_wallet.dart';
import 'electrumx_interface.dart';

const String kPCodeKeyPrefix = "pCode_key_";

String _basePaynymDerivePath({required bool testnet}) =>
    "m/47'/${testnet ? "1" : "0"}'/0'";
String _notificationDerivationPath({required bool testnet}) =>
    "${_basePaynymDerivePath(testnet: testnet)}/0";

String _receivingPaynymAddressDerivationPath(
  int index, {
  required bool testnet,
}) => "${_basePaynymDerivePath(testnet: testnet)}/$index/0";
String _sendPaynymAddressDerivationPath(int index, {required bool testnet}) =>
    "${_basePaynymDerivePath(testnet: testnet)}/0/$index";

mixin PaynymInterface<T extends PaynymCurrencyInterface>
    on Bip39HDWallet<T>, ElectrumXInterface<T> {
  btc_dart.NetworkType get networkType => btc_dart.NetworkType(
    messagePrefix: cryptoCurrency.networkParams.messagePrefix,
    bech32: cryptoCurrency.networkParams.bech32Hrp,
    bip32: btc_dart.Bip32Type(
      public: cryptoCurrency.networkParams.pubHDPrefix,
      private: cryptoCurrency.networkParams.privHDPrefix,
    ),
    pubKeyHash: cryptoCurrency.networkParams.p2pkhPrefix,
    scriptHash: cryptoCurrency.networkParams.p2shPrefix,
    wif: cryptoCurrency.networkParams.wifPrefix,
  );

  Future<bip32.BIP32> getBip47BaseNode() async {
    final root = await _getRootNode();
    final node = root.derivePath(
      _basePaynymDerivePath(testnet: info.coin.network.isTestNet),
    );
    return node;
  }

  Future<Uint8List> getPrivateKeyForPaynymReceivingAddress({
    required String paymentCodeString,
    required int index,
  }) async {
    final bip47base = await getBip47BaseNode();

    final paymentAddress = PaymentAddress(
      bip32Node: bip47base.derive(index),
      paymentCode: PaymentCode.fromPaymentCode(
        paymentCodeString,
        networkType: networkType,
      ),
      networkType: networkType,
      index: 0,
    );

    final pair = paymentAddress.getReceiveAddressKeyPair();

    return pair.privateKey!;
  }

  Future<Address> currentReceivingPaynymAddress({
    required PaymentCode sender,
    required bool isSegwit,
  }) async {
    final keys = await lookupKey(sender.toString());

    final address =
        await mainDB
            .getAddresses(walletId)
            .filter()
            .subTypeEqualTo(AddressSubType.paynymReceive)
            .and()
            .group((q) {
              if (isSegwit) {
                return q
                    .typeEqualTo(AddressType.p2sh)
                    .or()
                    .typeEqualTo(AddressType.p2wpkh);
              } else {
                return q.typeEqualTo(AddressType.p2pkh);
              }
            })
            .and()
            .anyOf<String, Address>(
              keys,
              (q, String e) => q.otherDataEqualTo(e),
            )
            .sortByDerivationIndexDesc()
            .findFirst();

    if (address == null) {
      final generatedAddress = await _generatePaynymReceivingAddress(
        sender: sender,
        index: 0,
        generateSegwitAddress: isSegwit,
      );

      final existing =
          await mainDB
              .getAddresses(walletId)
              .filter()
              .valueEqualTo(generatedAddress.value)
              .findFirst();

      if (existing == null) {
        // Add that new address
        await mainDB.putAddress(generatedAddress);
      } else {
        // we need to update the address
        await mainDB.updateAddress(existing, generatedAddress);
      }

      return currentReceivingPaynymAddress(isSegwit: isSegwit, sender: sender);
    } else {
      return address;
    }
  }

  Future<Address> _generatePaynymReceivingAddress({
    required PaymentCode sender,
    required int index,
    required bool generateSegwitAddress,
  }) async {
    final root = await _getRootNode();
    final node = root.derivePath(
      _basePaynymDerivePath(testnet: info.coin.network.isTestNet),
    );

    final paymentAddress = PaymentAddress(
      bip32Node: node.derive(index),
      paymentCode: sender,
      networkType: networkType,
      index: 0,
    );

    final addressString =
        generateSegwitAddress
            ? paymentAddress.getReceiveAddressP2WPKH()
            : paymentAddress.getReceiveAddressP2PKH();

    final address = Address(
      walletId: walletId,
      value: addressString,
      publicKey: [],
      derivationIndex: index,
      derivationPath:
          DerivationPath()
            ..value = _receivingPaynymAddressDerivationPath(
              index,
              testnet: info.coin.network.isTestNet,
            ),
      type: generateSegwitAddress ? AddressType.p2wpkh : AddressType.p2pkh,
      subType: AddressSubType.paynymReceive,
      otherData: await storeCode(sender.toString()),
    );

    return address;
  }

  Future<Address> _generatePaynymSendAddress({
    required PaymentCode other,
    required int index,
    required bool generateSegwitAddress,
    bip32.BIP32? mySendBip32Node,
  }) async {
    final node = mySendBip32Node ?? await deriveNotificationBip32Node();

    final paymentAddress = PaymentAddress(
      bip32Node: node,
      paymentCode: other,
      networkType: networkType,
      index: index,
    );

    final addressString =
        generateSegwitAddress
            ? paymentAddress.getSendAddressP2WPKH()
            : paymentAddress.getSendAddressP2PKH();

    final address = Address(
      walletId: walletId,
      value: addressString,
      publicKey: [],
      derivationIndex: index,
      derivationPath:
          DerivationPath()
            ..value = _sendPaynymAddressDerivationPath(
              index,
              testnet: info.coin.network.isTestNet,
            ),
      type: AddressType.nonWallet,
      subType: AddressSubType.paynymSend,
      otherData: await storeCode(other.toString()),
    );

    return address;
  }

  Future<void> checkCurrentPaynymReceivingAddressForTransactions({
    required PaymentCode sender,
    required bool isSegwit,
  }) async {
    final address = await currentReceivingPaynymAddress(
      sender: sender,
      isSegwit: isSegwit,
    );

    final txCount = await fetchTxCount(
      addressScriptHash: cryptoCurrency.addressToScriptHash(
        address: address.value,
      ),
    );
    if (txCount > 0) {
      // generate next address and add to db
      final nextAddress = await _generatePaynymReceivingAddress(
        sender: sender,
        index: address.derivationIndex + 1,
        generateSegwitAddress: isSegwit,
      );

      final existing =
          await mainDB
              .getAddresses(walletId)
              .filter()
              .valueEqualTo(nextAddress.value)
              .findFirst();

      if (existing == null) {
        // Add that new address
        await mainDB.putAddress(nextAddress);
      } else {
        // we need to update the address
        await mainDB.updateAddress(existing, nextAddress);
      }
      // keep checking until address with no tx history is set as current
      await checkCurrentPaynymReceivingAddressForTransactions(
        sender: sender,
        isSegwit: isSegwit,
      );
    }
  }

  Future<void> checkAllCurrentReceivingPaynymAddressesForTransactions() async {
    final codes = await getAllPaymentCodesFromNotificationTransactions();
    final List<Future<void>> futures = [];
    for (final code in codes) {
      futures.add(
        checkCurrentPaynymReceivingAddressForTransactions(
          sender: code,
          isSegwit: true,
        ),
      );
      futures.add(
        checkCurrentPaynymReceivingAddressForTransactions(
          sender: code,
          isSegwit: false,
        ),
      );
    }
    await Future.wait(futures);
  }

  // generate bip32 payment code root
  Future<bip32.BIP32> _getRootNode() async {
    return _cachedRootNode ??= await Bip32Utils.getBip32Root(
      (await getMnemonic()),
      (await getMnemonicPassphrase()),
      bip32.NetworkType(
        wif: networkType.wif,
        bip32: bip32.Bip32Type(
          public: networkType.bip32.public,
          private: networkType.bip32.private,
        ),
      ),
    );
  }

  bip32.BIP32? _cachedRootNode;

  Future<bip32.BIP32> deriveNotificationBip32Node() async {
    final root = await _getRootNode();
    final node = root
        .derivePath(_basePaynymDerivePath(testnet: info.coin.network.isTestNet))
        .derive(0);
    return node;
  }

  /// fetch or generate this wallet's bip47 payment code
  Future<PaymentCode> getPaymentCode({required bool isSegwit}) async {
    final node = await _getRootNode();

    final paymentCode = PaymentCode.fromBip32Node(
      node.derivePath(
        _basePaynymDerivePath(testnet: info.coin.network.isTestNet),
      ),
      networkType: networkType,
      shouldSetSegwitBit: isSegwit,
    );

    return paymentCode;
  }

  Future<Uint8List> signWithNotificationKey(Uint8List data) async {
    final myPrivateKeyNode = await deriveNotificationBip32Node();
    final pair = btc_dart.ECPair.fromPrivateKey(
      myPrivateKeyNode.privateKey!,
      network: networkType,
    );
    final signed = pair.sign(SHA256Digest().process(data));
    return signed;
  }

  Future<String> signStringWithNotificationKey(String data) async {
    final bytes = await signWithNotificationKey(
      Uint8List.fromList(utf8.encode(data)),
    );
    return Format.uint8listToString(bytes);
  }

  Future<TxData> preparePaymentCodeSend({
    required TxData txData,
    // required PaymentCode paymentCode,
    // required bool isSegwit,
    // required Amount amount,
    // Map<String, dynamic>? args,
  }) async {
    // TODO: handle asserts in a better manner
    assert(txData.recipients != null && txData.recipients!.length == 1);
    assert(txData.paynymAccountLite!.code == txData.recipients!.first.address);

    final paymentCode = PaymentCode.fromPaymentCode(
      txData.paynymAccountLite!.code,
      networkType: networkType,
    );

    if (!(await hasConnected(txData.paynymAccountLite!.code.toString()))) {
      throw PaynymSendException(
        "No notification transaction sent to $paymentCode,",
      );
    } else {
      final myPrivateKeyNode = await deriveNotificationBip32Node();
      final sendToAddress = await nextUnusedSendAddressFrom(
        pCode: paymentCode,
        privateKeyNode: myPrivateKeyNode,
        isSegwit: txData.paynymAccountLite!.segwit,
      );

      return prepareSend(
        txData: txData.copyWith(
          recipients: [
            (
              address: sendToAddress.value,
              amount: txData.recipients!.first.amount,
              isChange: false,
            ),
          ],
        ),
      );
    }
  }

  /// get the next unused address to send to given the receiver's payment code
  /// and your own private key
  Future<Address> nextUnusedSendAddressFrom({
    required PaymentCode pCode,
    required bool isSegwit,
    required bip32.BIP32 privateKeyNode,
    int startIndex = 0,
  }) async {
    // https://en.bitcoin.it/wiki/BIP_0047#Path_levels
    const maxCount = 2147483647;

    for (int i = startIndex; i < maxCount; i++) {
      final keys = await lookupKey(pCode.toString());
      final address =
          await mainDB
              .getAddresses(walletId)
              .filter()
              .subTypeEqualTo(AddressSubType.paynymSend)
              .and()
              .anyOf<String, Address>(
                keys,
                (q, String e) => q.otherDataEqualTo(e),
              )
              .and()
              .derivationIndexEqualTo(i)
              .findFirst();

      if (address != null) {
        final count = await fetchTxCount(
          addressScriptHash: cryptoCurrency.addressToScriptHash(
            address: address.value,
          ),
        );
        // return address if unused, otherwise continue to next index
        if (count == 0) {
          return address;
        }
      } else {
        final address = await _generatePaynymSendAddress(
          other: pCode,
          index: i,
          generateSegwitAddress: isSegwit,
          mySendBip32Node: privateKeyNode,
        );

        final storedAddress = await mainDB.getAddress(walletId, address.value);
        if (storedAddress == null) {
          await mainDB.putAddress(address);
        } else {
          await mainDB.updateAddress(storedAddress, address);
        }
        final count = await fetchTxCount(
          addressScriptHash: cryptoCurrency.addressToScriptHash(
            address: address.value,
          ),
        );
        // return address if unused, otherwise continue to next index
        if (count == 0) {
          return address;
        }
      }
    }

    throw PaynymSendException("Exhausted unused send addresses!");
  }

  Future<TxData> prepareNotificationTx({
    required BigInt selectedTxFeeRate,
    required String targetPaymentCodeString,
    int additionalOutputs = 0,
    List<UTXO>? utxos,
  }) async {
    try {
      final amountToSend = cryptoCurrency.dustLimitP2PKH;
      final List<UTXO> availableOutputs =
          utxos ?? await mainDB.getUTXOs(walletId).findAll();
      final List<UTXO> spendableOutputs = [];
      BigInt spendableSatoshiValue = BigInt.zero;

      // Build list of spendable outputs and totaling their satoshi amount
      for (var i = 0; i < availableOutputs.length; i++) {
        if (availableOutputs[i].isBlocked == false &&
            availableOutputs[i].isConfirmed(
                  await fetchChainHeight(),
                  cryptoCurrency.minConfirms,
                  cryptoCurrency.minCoinbaseConfirms,
                ) ==
                true) {
          spendableOutputs.add(availableOutputs[i]);
          spendableSatoshiValue += BigInt.from(availableOutputs[i].value);
        }
      }

      if (spendableSatoshiValue < amountToSend.raw) {
        // insufficient balance
        throw InsufficientBalanceException(
          "Spendable balance is less than the minimum required for a notification transaction.",
        );
      } else if (spendableSatoshiValue == amountToSend.raw) {
        // insufficient balance due to missing amount to cover fee
        throw InsufficientBalanceException(
          "Remaining balance does not cover the network fee.",
        );
      }

      // sort spendable by age (oldest first)
      spendableOutputs.sort((a, b) => b.blockTime!.compareTo(a.blockTime!));

      BigInt satoshisBeingUsed = BigInt.zero;
      int outputsBeingUsed = 0;
      final List<UTXO> utxoObjectsToUse = [];

      for (
        int i = 0;
        satoshisBeingUsed < amountToSend.raw && i < spendableOutputs.length;
        i++
      ) {
        utxoObjectsToUse.add(spendableOutputs[i]);
        satoshisBeingUsed += BigInt.from(spendableOutputs[i].value);
        outputsBeingUsed += 1;
      }

      // add additional outputs if required
      for (
        int i = 0;
        i < additionalOutputs && outputsBeingUsed < spendableOutputs.length;
        i++
      ) {
        utxoObjectsToUse.add(spendableOutputs[outputsBeingUsed]);
        satoshisBeingUsed += BigInt.from(
          spendableOutputs[outputsBeingUsed].value,
        );
        outputsBeingUsed += 1;
      }

      // gather required signing data
      final utxoSigningData =
          (await fetchBuildTxData(
            utxoObjectsToUse,
          )).whereType<StandardInput>().toList();

      final vSizeForNoChange = BigInt.from(
        (await _createNotificationTx(
          targetPaymentCodeString: targetPaymentCodeString,
          utxoSigningData: utxoSigningData,
          change: BigInt.zero,
          // override amount to get around absurd fees error
          overrideAmountForTesting: satoshisBeingUsed,
        )).item2,
      );

      final vSizeForWithChange = BigInt.from(
        (await _createNotificationTx(
          targetPaymentCodeString: targetPaymentCodeString,
          utxoSigningData: utxoSigningData,
          change: satoshisBeingUsed - amountToSend.raw,
        )).item2,
      );

      // Assume 2 outputs, for recipient and payment code script
      BigInt feeForNoChange = BigInt.from(
        estimateTxFee(
          vSize: vSizeForNoChange.toInt(),
          feeRatePerKB: selectedTxFeeRate,
        ),
      );

      // Assume 3 outputs, for recipient, payment code script, and change
      BigInt feeForWithChange = BigInt.from(
        estimateTxFee(
          vSize: vSizeForWithChange.toInt(),
          feeRatePerKB: selectedTxFeeRate,
        ),
      );

      if (info.coin is Dogecoin) {
        if (feeForNoChange < vSizeForNoChange * BigInt.from(1000)) {
          feeForNoChange = vSizeForNoChange * BigInt.from(1000);
        }
        if (feeForWithChange < vSizeForWithChange * BigInt.from(1000)) {
          feeForWithChange = vSizeForWithChange * BigInt.from(1000);
        }
      }

      if (satoshisBeingUsed - amountToSend.raw >
          feeForNoChange + cryptoCurrency.dustLimitP2PKH.raw) {
        // try to add change output due to "left over" amount being greater than
        // the estimated fee + the dust limit
        BigInt changeAmount =
            satoshisBeingUsed - amountToSend.raw - feeForWithChange;

        // check estimates are correct and build notification tx
        if (changeAmount >= cryptoCurrency.dustLimitP2PKH.raw &&
            satoshisBeingUsed - amountToSend.raw - changeAmount ==
                feeForWithChange) {
          var txn = await _createNotificationTx(
            targetPaymentCodeString: targetPaymentCodeString,
            utxoSigningData: utxoSigningData,
            change: changeAmount,
          );

          BigInt feeBeingPaid =
              satoshisBeingUsed - amountToSend.raw - changeAmount;

          // make sure minimum fee is accurate if that is being used
          if (txn.item2 - feeBeingPaid.toInt() == 1) {
            changeAmount -= BigInt.one;
            feeBeingPaid += BigInt.one;
            txn = await _createNotificationTx(
              targetPaymentCodeString: targetPaymentCodeString,
              utxoSigningData: utxoSigningData,
              change: changeAmount,
            );
          }

          final txData = TxData(
            raw: txn.item1,
            recipients: [
              (
                address: targetPaymentCodeString,
                amount: amountToSend,
                isChange: false,
              ),
            ],
            fee: Amount(
              rawValue: feeBeingPaid,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            vSize: txn.item2,
            utxos: utxoSigningData.map((e) => e.utxo).toSet(),
            note: "PayNym connect",
          );

          return txData;
        } else {
          // something broke during fee estimation or the change amount is smaller
          // than the dust limit. Try without change
          final txn = await _createNotificationTx(
            targetPaymentCodeString: targetPaymentCodeString,
            utxoSigningData: utxoSigningData,
            change: BigInt.zero,
          );

          final BigInt feeBeingPaid = satoshisBeingUsed - amountToSend.raw;

          final txData = TxData(
            raw: txn.item1,
            recipients: [
              (
                address: targetPaymentCodeString,
                amount: amountToSend,
                isChange: false,
              ),
            ],
            fee: Amount(
              rawValue: feeBeingPaid,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            vSize: txn.item2,
            utxos: utxoSigningData.map((e) => e.utxo).toSet(),
            note: "PayNym connect",
          );

          return txData;
        }
      } else if (satoshisBeingUsed - amountToSend.raw >= feeForNoChange) {
        // since we already checked if we need to add a change output we can just
        // build without change here
        final txn = await _createNotificationTx(
          targetPaymentCodeString: targetPaymentCodeString,
          utxoSigningData: utxoSigningData,
          change: BigInt.zero,
        );

        final BigInt feeBeingPaid = satoshisBeingUsed - amountToSend.raw;

        final txData = TxData(
          raw: txn.item1,
          recipients: [
            (
              address: targetPaymentCodeString,
              amount: amountToSend,
              isChange: false,
            ),
          ],
          fee: Amount(
            rawValue: feeBeingPaid,
            fractionDigits: cryptoCurrency.fractionDigits,
          ),
          vSize: txn.item2,
          utxos: utxoSigningData.map((e) => e.utxo).toSet(),
          note: "PayNym connect",
        );

        return txData;
      } else {
        // if we get here we do not have enough funds to cover the tx total so we
        // check if we have any more available outputs and try again
        if (spendableOutputs.length > outputsBeingUsed) {
          return prepareNotificationTx(
            selectedTxFeeRate: selectedTxFeeRate,
            targetPaymentCodeString: targetPaymentCodeString,
            additionalOutputs: additionalOutputs + 1,
          );
        } else {
          throw InsufficientBalanceException(
            "Remaining balance does not cover the network fee.",
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // return tuple with string value equal to the raw tx hex and the int value
  // equal to its vSize
  Future<Tuple2<String, int>> _createNotificationTx({
    required String targetPaymentCodeString,
    required List<StandardInput> utxoSigningData,
    required BigInt change,
    BigInt? overrideAmountForTesting,
  }) async {
    try {
      final targetPaymentCode = PaymentCode.fromPaymentCode(
        targetPaymentCodeString,
        networkType: networkType,
      );
      final myCode = await getPaymentCode(isSegwit: false);

      final utxo = utxoSigningData.first.utxo;
      final txPoint = utxo.txid.toUint8ListFromHex.reversed.toList();
      final txPointIndex = utxo.vout;

      final rev = Uint8List(txPoint.length + 4);
      _copyBytes(Uint8List.fromList(txPoint), 0, rev, 0, txPoint.length);
      final buffer = rev.buffer.asByteData();
      buffer.setUint32(txPoint.length, txPointIndex, Endian.little);

      final myKeyPair = utxoSigningData.first.key!;

      final S = SecretPoint(
        myKeyPair.privateKey!.data,
        targetPaymentCode.notificationPublicKey(),
      );

      final blindingMask = PaymentCode.getMask(S.ecdhSecret(), rev);

      final blindedPaymentCode = PaymentCode.blind(
        payload: myCode.getPayload(),
        mask: blindingMask,
        unBlind: false,
      );

      final opReturnScript = bscript.compile([
        (op.OPS["OP_RETURN"] as int),
        blindedPaymentCode,
      ]);

      // build a notification tx

      final List<coinlib.Output> prevOuts = [];

      coinlib.Transaction clTx = coinlib.Transaction(
        version: cryptoCurrency.transactionVersion,
        inputs: [],
        outputs: [],
      );

      for (var i = 0; i < utxoSigningData.length; i++) {
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
          case DerivePathType.bch44:
            input = coinlib.P2PKHInput(
              prevOut: prevOutpoint,
              publicKey: utxoSigningData[i].key!.publicKey,
              sequence: 0xffffffff - 1,
            );

          // TODO: fix this as it is (probably) wrong! (unlikely used in paynyms)
          case DerivePathType.bip49:
            throw Exception("TODO p2sh");
          // input = coinlib.P2SHMultisigInput(
          //   prevOut: prevOutpoint,
          //   program: coinlib.MultisigProgram.decompile(
          //     utxoSigningData[i].redeemScript!,
          //   ),
          //   sequence: 0xffffffff - 1,
          // );

          case DerivePathType.bip84:
            input = coinlib.P2WPKHInput(
              prevOut: prevOutpoint,
              publicKey: utxoSigningData[i].key!.publicKey,
              sequence: 0xffffffff - 1,
            );

          case DerivePathType.bip86:
            input = coinlib.TaprootKeyInput(prevOut: prevOutpoint);

          default:
            throw UnsupportedError(
              "Unknown derivation path type found: ${utxoSigningData[i].derivePathType}",
            );
        }

        clTx = clTx.addInput(input);
      }

      final String notificationAddress =
          targetPaymentCode.notificationAddressP2PKH();

      final address = coinlib.Address.fromString(
        normalizeAddress(notificationAddress),
        cryptoCurrency.networkParams,
      );

      final output = coinlib.Output.fromAddress(
        overrideAmountForTesting ?? cryptoCurrency.dustLimitP2PKH.raw,
        address,
      );

      clTx = clTx.addOutput(output);

      clTx = clTx.addOutput(
        coinlib.Output.fromScriptBytes(BigInt.zero, opReturnScript),
      );

      // TODO: add possible change output and mark output as dangerous
      if (change > BigInt.zero) {
        // generate new change address if current change address has been used
        await checkChangeAddressForTransactions();
        final String changeAddress = (await getCurrentChangeAddress())!.value;

        final output = coinlib.Output.fromAddress(
          change,
          coinlib.Address.fromString(
            normalizeAddress(changeAddress),
            cryptoCurrency.networkParams,
          ),
        );

        clTx = clTx.addOutput(output);
      }

      if (clTx.inputs[0] is coinlib.TaprootKeyInput) {
        final taproot = coinlib.Taproot(internalKey: myKeyPair.publicKey);

        clTx = clTx.signTaproot(
          inputN: 0,
          key: taproot.tweakPrivateKey(myKeyPair.privateKey!),
          prevOuts: prevOuts,
        );
      } else if (clTx.inputs[0] is coinlib.LegacyWitnessInput) {
        clTx = clTx.signLegacyWitness(
          inputN: 0,
          key: myKeyPair.privateKey!,
          value: BigInt.from(utxo.value),
        );
      } else if (clTx.inputs[0] is coinlib.LegacyInput) {
        clTx = clTx.signLegacy(inputN: 0, key: myKeyPair.privateKey!);
      } else if (clTx.inputs[0] is coinlib.TaprootSingleScriptSigInput) {
        clTx = clTx.signTaprootSingleScriptSig(
          inputN: 0,
          key: myKeyPair.privateKey!,
          prevOuts: prevOuts,
        );
      } else {
        throw Exception(
          "Unable to sign input of type ${clTx.inputs[0].runtimeType}",
        );
      }

      // sign rest of possible inputs
      for (int i = 1; i < utxoSigningData.length; i++) {
        final value = BigInt.from(utxoSigningData[i].utxo.value);
        final key = utxoSigningData[i].key!.privateKey!;

        if (clTx.inputs[i] is coinlib.TaprootKeyInput) {
          final taproot = coinlib.Taproot(
            internalKey: utxoSigningData[i].key!.publicKey,
          );

          clTx = clTx.signTaproot(
            inputN: i,
            key: taproot.tweakPrivateKey(key),
            prevOuts: prevOuts,
          );
        } else if (clTx.inputs[i] is coinlib.LegacyWitnessInput) {
          clTx = clTx.signLegacyWitness(inputN: i, key: key, value: value);
        } else if (clTx.inputs[i] is coinlib.LegacyInput) {
          clTx = clTx.signLegacy(inputN: i, key: key);
        } else if (clTx.inputs[i] is coinlib.TaprootSingleScriptSigInput) {
          clTx = clTx.signTaprootSingleScriptSig(
            inputN: i,
            key: key,
            prevOuts: prevOuts,
          );
        } else {
          throw Exception(
            "Unable to sign input of type ${clTx.inputs[i].runtimeType}",
          );
        }
      }

      return Tuple2(clTx.toHex(), clTx.vSize());
    } catch (e, s) {
      Logging.instance.e("_createNotificationTx(): ", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<TxData> broadcastNotificationTx({required TxData txData}) async {
    try {
      Logging.instance.d("confirmNotificationTx txData: $txData");
      final txHash = await electrumXClient.broadcastTransaction(
        rawTx: txData.raw!,
      );
      Logging.instance.d("Sent txHash: $txHash");

      try {
        await updateTransactions();
      } catch (e, s) {
        Logging.instance.e(
          "refresh() failed in confirmNotificationTx (${info.name}::$walletId): $e",
          error: e,
          stackTrace: s,
        );
      }

      return txData.copyWith(txid: txHash, txHash: txHash);
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from confirmSend(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // Future<bool?> _checkHasConnectedCache(String paymentCodeString) async {
  //   final value = await secureStorageInterface.read(
  //       key: "$_connectedKeyPrefix$paymentCodeString");
  //   if (value == null) {
  //     return null;
  //   } else {
  //     final int rawBool = int.parse(value);
  //     return rawBool > 0;
  //   }
  // }
  //
  // Future<void> _setConnectedCache(
  //     String paymentCodeString, bool hasConnected) async {
  //   await secureStorageInterface.write(
  //       key: "$_connectedKeyPrefix$paymentCodeString",
  //       value: hasConnected ? "1" : "0");
  // }

  // TODO optimize
  Future<bool> hasConnected(String paymentCodeString) async {
    // final didConnect = await _checkHasConnectedCache(paymentCodeString);
    // if (didConnect == true) {
    //   return true;
    // }
    //
    // final keys = await lookupKey(paymentCodeString);
    //
    // final tx = await mainDB
    //     .getTransactions(walletId)
    //     .filter()
    //     .subTypeEqualTo(TransactionSubType.bip47Notification).and()
    //     .address((q) =>
    //         q.anyOf<String, Transaction>(keys, (q, e) => q.otherDataEqualTo(e)))
    //     .findAll();

    final myNotificationAddress = await getMyNotificationAddress();

    final txns =
        await mainDB.isar.transactionV2s
            .where()
            .walletIdEqualTo(walletId)
            .filter()
            .subTypeEqualTo(TransactionSubType.bip47Notification)
            .findAll();

    for (final tx in txns) {
      switch (tx.type) {
        case TransactionType.incoming:
          for (final output in tx.outputs) {
            for (final outputAddress in output.addresses) {
              if (outputAddress == myNotificationAddress.value) {
                final unBlindedPaymentCode =
                    await unBlindedPaymentCodeFromTransaction(transaction: tx);

                if (unBlindedPaymentCode != null &&
                    paymentCodeString == unBlindedPaymentCode.toString()) {
                  // await _setConnectedCache(paymentCodeString, true);
                  return true;
                }

                final unBlindedPaymentCodeBad =
                    await unBlindedPaymentCodeFromTransactionBad(
                      transaction: tx,
                    );

                if (unBlindedPaymentCodeBad != null &&
                    paymentCodeString == unBlindedPaymentCodeBad.toString()) {
                  // await _setConnectedCache(paymentCodeString, true);
                  return true;
                }
              }
            }
          }

        case TransactionType.outgoing:
          for (final output in tx.outputs) {
            for (final outputAddress in output.addresses) {
              final address =
                  await mainDB.isar.addresses
                      .where()
                      .walletIdEqualTo(walletId)
                      .filter()
                      .subTypeEqualTo(AddressSubType.paynymNotification)
                      .and()
                      .valueEqualTo(outputAddress)
                      .findFirst();

              if (address?.otherData != null) {
                final code = await paymentCodeStringByKey(address!.otherData!);
                if (code == paymentCodeString) {
                  // await _setConnectedCache(paymentCodeString, true);
                  return true;
                }
              }
            }
          }
        default:
          break;
      }
    }

    // otherwise return no
    // await _setConnectedCache(paymentCodeString, false);
    return false;
  }

  Uint8List? _pubKeyFromInput(InputV2 input) {
    final scriptSigComponents = input.scriptSigAsm?.split(" ") ?? [];
    if (scriptSigComponents.length > 1) {
      return scriptSigComponents[1].toUint8ListFromHex;
    }
    if (input.witness != null) {
      try {
        final witnessComponents = jsonDecode(input.witness!) as List;
        if (witnessComponents.length == 2) {
          return (witnessComponents[1] as String).toUint8ListFromHex;
        }
      } catch (e, s) {
        Logging.instance.e("_pubKeyFromInput()", error: e, stackTrace: s);
      }
    }
    return null;
  }

  Future<PaymentCode?> unBlindedPaymentCodeFromTransaction({
    required TransactionV2 transaction,
  }) async {
    try {
      final blindedCodeBytes = Bip47Utils.getBlindedPaymentCodeBytesFrom(
        transaction,
      );

      // transaction does not contain a payment code
      if (blindedCodeBytes == null) {
        return null;
      }

      final designatedInput = transaction.inputs.first;

      final txPoint =
          designatedInput.outpoint!.txid.toUint8ListFromHex.reversed.toList();
      final txPointIndex = designatedInput.outpoint!.vout;

      final rev = Uint8List(txPoint.length + 4);
      _copyBytes(Uint8List.fromList(txPoint), 0, rev, 0, txPoint.length);
      final buffer = rev.buffer.asByteData();
      buffer.setUint32(txPoint.length, txPointIndex, Endian.little);

      final pubKey = _pubKeyFromInput(designatedInput)!;

      final myPrivateKey = (await deriveNotificationBip32Node()).privateKey!;

      final S = SecretPoint(myPrivateKey, pubKey);

      final mask = PaymentCode.getMask(S.ecdhSecret(), rev);

      final unBlindedPayload = PaymentCode.blind(
        payload: blindedCodeBytes,
        mask: mask,
        unBlind: true,
      );

      final unBlindedPaymentCode = PaymentCode.fromPayload(
        unBlindedPayload,
        networkType: networkType,
      );

      return unBlindedPaymentCode;
    } catch (e, s) {
      Logging.instance.e(
        "unBlindedPaymentCodeFromTransaction()",
        error: e,
        stackTrace: s,
      );
      Logging.instance.d(
        "unBlindedPaymentCodeFromTransaction() failed for tx: $transaction",
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<PaymentCode?> unBlindedPaymentCodeFromTransactionBad({
    required TransactionV2 transaction,
  }) async {
    try {
      final blindedCodeBytes = Bip47Utils.getBlindedPaymentCodeBytesFrom(
        transaction,
      );

      // transaction does not contain a payment code
      if (blindedCodeBytes == null) {
        return null;
      }

      final designatedInput = transaction.inputs.first;

      final txPoint =
          designatedInput.outpoint!.txid.toUint8ListFromHex.toList();
      final txPointIndex = designatedInput.outpoint!.vout;

      final rev = Uint8List(txPoint.length + 4);
      _copyBytes(Uint8List.fromList(txPoint), 0, rev, 0, txPoint.length);
      final buffer = rev.buffer.asByteData();
      buffer.setUint32(txPoint.length, txPointIndex, Endian.little);

      final pubKey = _pubKeyFromInput(designatedInput)!;

      final myPrivateKey = (await deriveNotificationBip32Node()).privateKey!;

      final S = SecretPoint(myPrivateKey, pubKey);

      final mask = PaymentCode.getMask(S.ecdhSecret(), rev);

      final unBlindedPayload = PaymentCode.blind(
        payload: blindedCodeBytes,
        mask: mask,
        unBlind: true,
      );

      final unBlindedPaymentCode = PaymentCode.fromPayload(
        unBlindedPayload,
        networkType: networkType,
      );

      return unBlindedPaymentCode;
    } catch (e, s) {
      Logging.instance.e(
        "unBlindedPaymentCodeFromTransactionBad()n",
        error: e,
        stackTrace: s,
      );
      Logging.instance.d(
        "unBlindedPaymentCodeFromTransactionBad() failed: $e\nFor tx: $transaction",
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<List<PaymentCode>>
  getAllPaymentCodesFromNotificationTransactions() async {
    final txns =
        await mainDB.isar.transactionV2s
            .where()
            .walletIdEqualTo(walletId)
            .filter()
            .subTypeEqualTo(TransactionSubType.bip47Notification)
            .findAll();

    final List<PaymentCode> codes = [];

    for (final tx in txns) {
      // tx is sent so we can check the address's otherData for the code String
      if (tx.type == TransactionType.outgoing) {
        for (final output in tx.outputs) {
          for (final outputAddress in output.addresses.where(
            (e) => e.isNotEmpty,
          )) {
            final address =
                await mainDB.isar.addresses
                    .where()
                    .walletIdEqualTo(walletId)
                    .filter()
                    .subTypeEqualTo(AddressSubType.paynymNotification)
                    .and()
                    .valueEqualTo(outputAddress)
                    .findFirst();

            if (address?.otherData != null) {
              final codeString = await paymentCodeStringByKey(
                address!.otherData!,
              );
              if (codeString != null &&
                  codes.where((e) => e.toString() == codeString).isEmpty) {
                codes.add(
                  PaymentCode.fromPaymentCode(
                    codeString,
                    networkType: networkType,
                  ),
                );
              }
            }
          }
        }
      } else {
        // otherwise we need to un blind the code
        final unBlinded = await unBlindedPaymentCodeFromTransaction(
          transaction: tx,
        );
        if (unBlinded != null &&
            codes.where((e) => e.toString() == unBlinded.toString()).isEmpty) {
          codes.add(unBlinded);
        }

        final unBlindedBad = await unBlindedPaymentCodeFromTransactionBad(
          transaction: tx,
        );
        if (unBlindedBad != null &&
            codes
                .where((e) => e.toString() == unBlindedBad.toString())
                .isEmpty) {
          codes.add(unBlindedBad);
        }
      }
    }

    return codes;
  }

  Future<void> checkForNotificationTransactionsTo(
    Set<String> otherCodeStrings,
  ) async {
    final sentNotificationTransactions =
        await mainDB.isar.transactionV2s
            .where()
            .walletIdEqualTo(walletId)
            .filter()
            .subTypeEqualTo(TransactionSubType.bip47Notification)
            .and()
            .typeEqualTo(TransactionType.outgoing)
            .findAll();

    final List<PaymentCode> codes = [];
    for (final codeString in otherCodeStrings) {
      codes.add(
        PaymentCode.fromPaymentCode(codeString, networkType: networkType),
      );
    }

    for (final tx in sentNotificationTransactions) {
      for (final output in tx.outputs) {
        for (final outputAddress in output.addresses) {
          if (outputAddress.isNotEmpty) {
            for (final code in codes) {
              final notificationAddress = code.notificationAddressP2PKH();

              if (outputAddress == notificationAddress) {
                Address? storedAddress = await mainDB.getAddress(
                  walletId,
                  outputAddress,
                );
                if (storedAddress == null) {
                  // most likely not mine
                  storedAddress = Address(
                    walletId: walletId,
                    value: notificationAddress,
                    publicKey: [],
                    derivationIndex: 0,
                    derivationPath: null,
                    type: AddressType.nonWallet,
                    subType: AddressSubType.paynymNotification,
                    otherData: await storeCode(code.toString()),
                  );
                } else {
                  storedAddress = storedAddress.copyWith(
                    subType: AddressSubType.paynymNotification,
                    otherData: await storeCode(code.toString()),
                  );
                }

                await mainDB.updateOrPutAddresses([storedAddress]);
              }
            }
          }
        }
      }
    }
  }

  Future<void> restoreAllHistory({
    required int maxUnusedAddressGap,
    required int maxNumberOfIndexesToCheck,
    required Set<String> paymentCodeStrings,
  }) async {
    final codes = await getAllPaymentCodesFromNotificationTransactions();
    final List<PaymentCode> extraCodes = [];
    for (final codeString in paymentCodeStrings) {
      if (codes.where((e) => e.toString() == codeString).isEmpty) {
        final extraCode = PaymentCode.fromPaymentCode(
          codeString,
          networkType: networkType,
        );
        if (extraCode.isValid()) {
          extraCodes.add(extraCode);
        }
      }
    }

    codes.addAll(extraCodes);

    final List<Future<void>> futures = [];
    for (final code in codes) {
      futures.add(
        _restoreHistoryWith(
          other: code,
          maxUnusedAddressGap: maxUnusedAddressGap,
          maxNumberOfIndexesToCheck: maxNumberOfIndexesToCheck,
          checkSegwitAsWell: code.isSegWitEnabled(),
        ),
      );
    }

    await Future.wait(futures);
  }

  Future<void> _restoreHistoryWith({
    required PaymentCode other,
    required bool checkSegwitAsWell,
    required int maxUnusedAddressGap,
    required int maxNumberOfIndexesToCheck,
  }) async {
    // https://en.bitcoin.it/wiki/BIP_0047#Path_levels
    const maxCount = 2147483647;
    assert(maxNumberOfIndexesToCheck < maxCount);

    final mySendBip32Node = await deriveNotificationBip32Node();

    final List<Address> addresses = [];
    int receivingGapCounter = 0;
    int outgoingGapCounter = 0;

    // non segwit receiving
    for (
      int i = 0;
      i < maxNumberOfIndexesToCheck &&
          receivingGapCounter < maxUnusedAddressGap;
      i++
    ) {
      if (receivingGapCounter < maxUnusedAddressGap) {
        final address = await _generatePaynymReceivingAddress(
          sender: other,
          index: i,
          generateSegwitAddress: false,
        );

        addresses.add(address);

        final count = await fetchTxCount(
          addressScriptHash: cryptoCurrency.addressToScriptHash(
            address: address.value,
          ),
        );

        if (count > 0) {
          receivingGapCounter = 0;
        } else {
          receivingGapCounter++;
        }
      }
    }

    // non segwit sends
    for (
      int i = 0;
      i < maxNumberOfIndexesToCheck && outgoingGapCounter < maxUnusedAddressGap;
      i++
    ) {
      if (outgoingGapCounter < maxUnusedAddressGap) {
        final address = await _generatePaynymSendAddress(
          other: other,
          index: i,
          generateSegwitAddress: false,
          mySendBip32Node: mySendBip32Node,
        );

        addresses.add(address);

        final count = await fetchTxCount(
          addressScriptHash: cryptoCurrency.addressToScriptHash(
            address: address.value,
          ),
        );

        if (count > 0) {
          outgoingGapCounter = 0;
        } else {
          outgoingGapCounter++;
        }
      }
    }

    if (checkSegwitAsWell) {
      int receivingGapCounterSegwit = 0;
      int outgoingGapCounterSegwit = 0;
      // segwit receiving
      for (
        int i = 0;
        i < maxNumberOfIndexesToCheck &&
            receivingGapCounterSegwit < maxUnusedAddressGap;
        i++
      ) {
        if (receivingGapCounterSegwit < maxUnusedAddressGap) {
          final address = await _generatePaynymReceivingAddress(
            sender: other,
            index: i,
            generateSegwitAddress: true,
          );

          addresses.add(address);

          final count = await fetchTxCount(
            addressScriptHash: cryptoCurrency.addressToScriptHash(
              address: address.value,
            ),
          );

          if (count > 0) {
            receivingGapCounterSegwit = 0;
          } else {
            receivingGapCounterSegwit++;
          }
        }
      }

      // segwit sends
      for (
        int i = 0;
        i < maxNumberOfIndexesToCheck &&
            outgoingGapCounterSegwit < maxUnusedAddressGap;
        i++
      ) {
        if (outgoingGapCounterSegwit < maxUnusedAddressGap) {
          final address = await _generatePaynymSendAddress(
            other: other,
            index: i,
            generateSegwitAddress: true,
            mySendBip32Node: mySendBip32Node,
          );

          addresses.add(address);

          final count = await fetchTxCount(
            addressScriptHash: cryptoCurrency.addressToScriptHash(
              address: address.value,
            ),
          );

          if (count > 0) {
            outgoingGapCounterSegwit = 0;
          } else {
            outgoingGapCounterSegwit++;
          }
        }
      }
    }
    await mainDB.updateOrPutAddresses(addresses);
  }

  Future<Address> getMyNotificationAddress() async {
    final storedAddress =
        await mainDB
            .getAddresses(walletId)
            .filter()
            .subTypeEqualTo(AddressSubType.paynymNotification)
            .and()
            .typeEqualTo(AddressType.p2pkh)
            .and()
            .not()
            .typeEqualTo(AddressType.nonWallet)
            .findFirst();

    if (storedAddress != null) {
      return storedAddress;
    } else {
      final root = await _getRootNode();
      final node = root.derivePath(
        _basePaynymDerivePath(testnet: info.coin.network.isTestNet),
      );
      final paymentCode = PaymentCode.fromBip32Node(
        node,
        networkType: networkType,
        shouldSetSegwitBit: false,
      );

      final data = btc_dart.PaymentData(
        pubkey: paymentCode.notificationPublicKey(),
      );

      final addressString =
          btc_dart.P2PKH(data: data, network: networkType).data.address!;

      Address address = Address(
        walletId: walletId,
        value: addressString,
        publicKey: paymentCode.getPubKey(),
        derivationIndex: 0,
        derivationPath:
            DerivationPath()
              ..value = _notificationDerivationPath(
                testnet: info.coin.network.isTestNet,
              ),
        type: AddressType.p2pkh,
        subType: AddressSubType.paynymNotification,
        otherData: await storeCode(paymentCode.toString()),
      );

      // check against possible race condition. Ff this function was called
      // multiple times an address could've been saved after the check at the
      // beginning to see if there already was notification address. This would
      // lead to a Unique Index violation  error
      await mainDB.isar.writeTxn(() async {
        final storedAddress =
            await mainDB
                .getAddresses(walletId)
                .filter()
                .subTypeEqualTo(AddressSubType.paynymNotification)
                .and()
                .typeEqualTo(AddressType.p2pkh)
                .and()
                .not()
                .typeEqualTo(AddressType.nonWallet)
                .findFirst();

        if (storedAddress == null) {
          await mainDB.isar.addresses.put(address);
        } else {
          address = storedAddress;
        }
      });

      return address;
    }
  }

  /// look up a key that corresponds to a payment code string
  Future<List<String>> lookupKey(String paymentCodeString) async {
    final keys = (await secureStorageInterface.keys).where(
      (e) => e.startsWith(kPCodeKeyPrefix),
    );
    final List<String> result = [];
    for (final key in keys) {
      final value = await secureStorageInterface.read(key: key);
      if (value == paymentCodeString) {
        result.add(key);
      }
    }
    return result;
  }

  /// fetch a payment code string
  Future<String?> paymentCodeStringByKey(String key) async {
    final value = await secureStorageInterface.read(key: key);
    return value;
  }

  /// store payment code string and return the generated key used
  Future<String> storeCode(String paymentCodeString) async {
    final key = _generateKey();
    await secureStorageInterface.write(key: key, value: paymentCodeString);
    return key;
  }

  void _copyBytes(
    Uint8List source,
    int sourceStartingIndex,
    Uint8List destination,
    int destinationStartingIndex,
    int numberOfBytes,
  ) {
    for (int i = 0; i < numberOfBytes; i++) {
      destination[i + destinationStartingIndex] =
          source[i + sourceStartingIndex];
    }
  }

  /// generate a new payment code string storage key
  String _generateKey() {
    final bytes = _randomBytes(24);
    return "$kPCodeKeyPrefix${bytes.toHex}";
  }

  // https://github.com/AaronFeickert/stack_wallet_backup/blob/master/lib/secure_storage.dart#L307-L311
  /// Generate cryptographically-secure random bytes
  Uint8List _randomBytes(int n) {
    final Random rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(n, (_) => rng.nextInt(0xFF + 1)),
    );
  }

  // ================== Overrides ==============================================

  @override
  Future<void> updateTransactions({List<Address>? overrideAddresses}) async {
    // Get all addresses.
    final List<Address> allAddressesOld =
        overrideAddresses ?? await fetchAddressesForElectrumXScan();

    // Separate receiving and change addresses.
    final Set<String> receivingAddresses =
        allAddressesOld
            .where(
              (e) =>
                  e.subType == AddressSubType.receiving ||
                  e.subType == AddressSubType.paynymNotification ||
                  e.subType == AddressSubType.paynymReceive,
            )
            .map((e) => e.value)
            .toSet();
    final Set<String> changeAddresses =
        allAddressesOld
            .where((e) => e.subType == AddressSubType.change)
            .map((e) => e.value)
            .toSet();

    // Remove duplicates.
    final allAddressesSet = {...receivingAddresses, ...changeAddresses};

    // Fetch history from ElectrumX.
    final List<Map<String, dynamic>> allTxHashes = await fetchHistory(
      allAddressesSet,
    );

    final unconfirmedTxs =
        await mainDB.isar.transactionV2s
            .where()
            .walletIdEqualTo(walletId)
            .filter()
            .heightIsNull()
            .or()
            .heightEqualTo(0)
            .txidProperty()
            .findAll();

    allTxHashes.addAll(unconfirmedTxs.map((e) => {"tx_hash": e}));

    // Only parse new txs (not in db yet).
    final List<Map<String, dynamic>> allTransactions = [];
    for (final txHash in allTxHashes) {
      // Check for duplicates by searching for tx by tx_hash in db.
      // final storedTx = await mainDB.isar.transactionV2s
      //     .where()
      //     .txidWalletIdEqualTo(txHash["tx_hash"] as String, walletId)
      //     .findFirst();
      //
      // if (storedTx == null ||
      //     storedTx.height == null ||
      //     (storedTx.height != null && storedTx.height! <= 0)) {
      // Tx not in db yet.
      final txid = txHash["tx_hash"] as String;
      final Map<String, dynamic> tx;
      try {
        tx = await electrumXCachedClient.getTransaction(
          txHash: txid,
          verbose: true,
          cryptoCurrency: cryptoCurrency,
        );
      } catch (e) {
        // tx no longer exists then delete from local db
        if (e.toString().contains(
          "JSON-RPC error 2: daemon error: DaemonError({'code': -5, "
          "'message': 'No such mempool or blockchain transaction",
        )) {
          await mainDB.isar.writeTxn(
            () async =>
                await mainDB.isar.transactionV2s
                    .where()
                    .walletIdEqualTo(walletId)
                    .filter()
                    .txidEqualTo(txid)
                    .deleteFirst(),
          );
          continue;
        } else {
          rethrow;
        }
      }

      // Only tx to list once.
      if (allTransactions.indexWhere((e) => e["txid"] == txid) == -1) {
        tx["height"] = txHash["height"];
        allTransactions.add(tx);
      }
      // }
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

        InputV2 input = InputV2.fromElectrumxJson(
          json: map,
          outpoint: outpoint,
          valueStringSats: valueStringSats,
          addresses: addresses,
          coinbase: coinbase,
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
      TransactionSubType subType = TransactionSubType.none;
      if (outputs.length > 1 && inputs.isNotEmpty) {
        for (int i = 0; i < outputs.length; i++) {
          final List<String>? scriptChunks = outputs[i].scriptPubKeyAsm?.split(
            " ",
          );
          if (scriptChunks?.length == 2 && scriptChunks?[0] == "OP_RETURN") {
            final blindedPaymentCode = scriptChunks![1];
            final bytes = blindedPaymentCode.toUint8ListFromHex;

            // https://en.bitcoin.it/wiki/BIP_0047#Sending
            if (bytes.length == 80 && bytes.first == 1) {
              subType = TransactionSubType.bip47Notification;
              break;
            }
          }
        }
      }

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

        // TODO: [prio=none] Check for special Bitcoin outputs like ordinals.
      } else {
        Logging.instance.w("Unexpected tx found (ignoring it)");
        Logging.instance.d("Unexpected tx found (ignoring it): $txData");
        continue;
      }

      String? otherData;
      if (txData["size"] is int || txData["vsize"] is int) {
        otherData = jsonEncode({
          TxV2OdKeys.size: txData["size"] as int?,
          TxV2OdKeys.vSize: txData["vsize"] as int?,
        });
      }

      final tx = TransactionV2(
        walletId: walletId,
        blockHash: txData["blockhash"] as String?,
        hash: txData["hash"] as String,
        txid: txData["txid"] as String,
        height: txData["height"] as int?,
        version: txData["version"] as int,
        timestamp:
            txData["blocktime"] as int? ??
            DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
        inputs: List.unmodifiable(inputs),
        outputs: List.unmodifiable(outputs),
        type: type,
        subType: subType,
        otherData: otherData,
      );

      txns.add(tx);
    }

    await mainDB.updateOrPutTransactionV2s(txns);
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
    String? utxoLabel;

    // check for bip47 notification
    if (jsonTX != null) {
      final outputs = jsonTX["vout"] as List;
      for (int i = 0; i < outputs.length; i++) {
        final output = outputs[i];
        final List<String>? scriptChunks =
            (output['scriptPubKey']?['asm'] as String?)?.split(" ");
        if (scriptChunks?.length == 2 && scriptChunks?[0] == "OP_RETURN") {
          final blindedPaymentCode = scriptChunks![1];
          final bytes = blindedPaymentCode.toUint8ListFromHex;

          // https://en.bitcoin.it/wiki/BIP_0047#Sending
          if (bytes.length == 80 && bytes.first == 1) {
            final myNotificationAddress = await getMyNotificationAddress();
            if (utxoOwnerAddress == myNotificationAddress.value) {
              blocked = true;
              blockedReason = "Incoming paynym notification transaction.";
            } else {
              blockedReason =
                  "Paynym notification change output. Incautious "
                  "handling of change outputs from notification transactions "
                  "may cause unintended loss of privacy.";
              utxoLabel = blockedReason;
            }

            break;
          }
        }
      }
    }

    return (
      blockedReason: blockedReason,
      blocked: blocked,
      utxoLabel: utxoLabel,
    );
  }

  @override
  FilterOperation? get transactionFilterOperation => FilterGroup.not(
    const FilterGroup.and([
      FilterCondition.equalTo(
        property: r"subType",
        value: TransactionSubType.bip47Notification,
      ),
      FilterCondition.equalTo(
        property: r"type",
        value: TransactionType.incoming,
      ),
    ]),
  );
}
