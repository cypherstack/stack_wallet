import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip47/bip47.dart';
import 'package:bip47/src/util.dart';
import 'package:bitcoindart/bitcoindart.dart' as btc_dart;
import 'package:bitcoindart/src/utils/constants/op.dart' as op;
import 'package:bitcoindart/src/utils/script.dart' as bscript;
import 'package:isar/isar.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/exceptions/wallet/insufficient_balance_exception.dart';
import 'package:stackwallet/exceptions/wallet/paynym_send_exception.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/models/signing_data.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/bip32_utils.dart';
import 'package:stackwallet/utilities/bip47_utils.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:tuple/tuple.dart';

const String kPaynymDerivePath = "m/47'/0'/0'";
const String kPaynymNotificationDerivationPath = "$kPaynymDerivePath/0";
const String kPCodeKeyPrefix = "pCode_key_";

String _receivingPaynymAddressDerivationPath(int index) =>
    "$kPaynymDerivePath/$index/0";
String _sendPaynymAddressDerivationPath(int index) =>
    "$kPaynymDerivePath/0/$index";

mixin PaynymWalletInterface {
  // passed in wallet data
  late final String _walletId;
  late final String _walletName;
  late final btc_dart.NetworkType _network;
  late final Coin _coin;
  late final MainDB _db;
  late final ElectrumX _electrumXClient;
  late final SecureStorageInterface _secureStorage;
  late final int _dustLimit;
  late final int _dustLimitP2PKH;
  late final int _minConfirms;

  // passed in wallet functions
  late final Future<String?> Function() _getMnemonicString;
  late final Future<String?> Function() _getMnemonicPassphrase;
  late final Future<int> Function() _getChainHeight;
  late final Future<String> Function() _getCurrentChangeAddress;
  late final int Function({
    required int vSize,
    required int feeRatePerKB,
  }) _estimateTxFee;
  late final Future<Map<String, dynamic>> Function({
    required String address,
    required Amount amount,
    Map<String, dynamic>? args,
  }) _prepareSend;
  late final Future<int> Function({
    required String address,
  }) _getTxCount;
  late final Future<List<SigningData>> Function(
    List<UTXO> utxosToUse,
  ) _fetchBuildTxData;
  late final Future<void> Function() _refresh;
  late final Future<void> Function() _checkChangeAddressForTransactions;

  // initializer
  void initPaynymWalletInterface({
    required String walletId,
    required String walletName,
    required btc_dart.NetworkType network,
    required Coin coin,
    required MainDB db,
    required ElectrumX electrumXClient,
    required SecureStorageInterface secureStorage,
    required int dustLimit,
    required int dustLimitP2PKH,
    required int minConfirms,
    required Future<String?> Function() getMnemonicString,
    required Future<String?> Function() getMnemonicPassphrase,
    required Future<int> Function() getChainHeight,
    required Future<String> Function() getCurrentChangeAddress,
    required int Function({
      required int vSize,
      required int feeRatePerKB,
    })
        estimateTxFee,
    required Future<Map<String, dynamic>> Function({
      required String address,
      required Amount amount,
      Map<String, dynamic>? args,
    })
        prepareSend,
    required Future<int> Function({
      required String address,
    })
        getTxCount,
    required Future<List<SigningData>> Function(
      List<UTXO> utxosToUse,
    )
        fetchBuildTxData,
    required Future<void> Function() refresh,
    required Future<void> Function() checkChangeAddressForTransactions,
  }) {
    _walletId = walletId;
    _walletName = walletName;
    _network = network;
    _coin = coin;
    _db = db;
    _electrumXClient = electrumXClient;
    _secureStorage = secureStorage;
    _dustLimitP2PKH = dustLimit;
    _dustLimitP2PKH = dustLimitP2PKH;
    _minConfirms = minConfirms;
    _getMnemonicString = getMnemonicString;
    _getMnemonicPassphrase = getMnemonicPassphrase;
    _getChainHeight = getChainHeight;
    _getCurrentChangeAddress = getCurrentChangeAddress;
    _estimateTxFee = estimateTxFee;
    _prepareSend = prepareSend;
    _getTxCount = getTxCount;
    _fetchBuildTxData = fetchBuildTxData;
    _refresh = refresh;
    _checkChangeAddressForTransactions = checkChangeAddressForTransactions;
  }

  // convenience getter
  btc_dart.NetworkType get networkType => _network;

  Future<Address> currentReceivingPaynymAddress({
    required PaymentCode sender,
    required bool isSegwit,
  }) async {
    final keys = await lookupKey(sender.toString());

    final address = await _db
        .getAddresses(_walletId)
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
        .anyOf<String, Address>(keys, (q, String e) => q.otherDataEqualTo(e))
        .sortByDerivationIndexDesc()
        .findFirst();

    if (address == null) {
      final generatedAddress = await _generatePaynymReceivingAddress(
        sender: sender,
        index: 0,
        generateSegwitAddress: isSegwit,
      );

      final existing = await _db
          .getAddresses(_walletId)
          .filter()
          .valueEqualTo(generatedAddress.value)
          .findFirst();

      if (existing == null) {
        // Add that new address
        await _db.putAddress(generatedAddress);
      } else {
        // we need to update the address
        await _db.updateAddress(existing, generatedAddress);
      }

      return currentReceivingPaynymAddress(
        isSegwit: isSegwit,
        sender: sender,
      );
    } else {
      return address;
    }
  }

  Future<Address> _generatePaynymReceivingAddress({
    required PaymentCode sender,
    required int index,
    required bool generateSegwitAddress,
  }) async {
    final myPrivateKeyNode = await deriveReceivingPrivateKeyNode(
      mnemonic: (await _getMnemonicString())!,
      mnemonicPassphrase: (await _getMnemonicPassphrase())!,
      index: index,
    );

    final paymentAddress = PaymentAddress(
      bip32Node: myPrivateKeyNode,
      paymentCode: sender,
      networkType: networkType,
    );

    final pair = paymentAddress.getReceiveAddressKeyPair();
    final address = await generatePaynymReceivingAddressFromKeyPair(
      pair: pair,
      derivationIndex: index,
      isSegwit: generateSegwitAddress,
      fromPaymentCode: sender,
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
    final txCount = await _getTxCount(address: address.value);
    if (txCount > 0) {
      // generate next address and add to db
      final nextAddress = await _generatePaynymReceivingAddress(
        sender: sender,
        index: address.derivationIndex + 1,
        generateSegwitAddress: isSegwit,
      );

      final existing = await _db
          .getAddresses(_walletId)
          .filter()
          .valueEqualTo(nextAddress.value)
          .findFirst();

      if (existing == null) {
        // Add that new address
        await _db.putAddress(nextAddress);
      } else {
        // we need to update the address
        await _db.updateAddress(existing, nextAddress);
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
      futures.add(checkCurrentPaynymReceivingAddressForTransactions(
        sender: code,
        isSegwit: true,
      ));
      futures.add(checkCurrentPaynymReceivingAddressForTransactions(
        sender: code,
        isSegwit: false,
      ));
    }
    await Future.wait(futures);
  }

  // generate bip32 payment code root
  Future<bip32.BIP32> _getRootNode({
    required String mnemonic,
    required String mnemonicPassphrase,
  }) async {
    return _cachedRootNode ??= await Bip32Utils.getBip32Root(
      mnemonic,
      mnemonicPassphrase,
      _network,
    );
  }

  bip32.BIP32? _cachedRootNode;

  Future<bip32.BIP32> deriveNotificationBip32Node({
    required String mnemonic,
    required String mnemonicPassphrase,
  }) async {
    final root = await _getRootNode(
      mnemonic: mnemonic,
      mnemonicPassphrase: mnemonicPassphrase,
    );
    final node = root.derivePath(kPaynymDerivePath).derive(0);
    return node;
  }

  Future<bip32.BIP32> deriveReceivingPrivateKeyNode({
    required String mnemonic,
    required String mnemonicPassphrase,
    required int index,
  }) async {
    final root = await _getRootNode(
      mnemonic: mnemonic,
      mnemonicPassphrase: mnemonicPassphrase,
    );
    final node = root.derivePath(kPaynymDerivePath).derive(index);
    return node;
  }

  /// fetch or generate this wallet's bip47 payment code
  Future<PaymentCode> getPaymentCode({
    required bool isSegwit,
  }) async {
    final address = await getMyNotificationAddress(
      isSegwit: isSegwit,
    );
    final pCodeString = await paymentCodeStringByKey(address.otherData!);
    final paymentCode = PaymentCode.fromPaymentCode(
      pCodeString!,
      networkType: _network,
    );
    return paymentCode;
  }

  Future<Uint8List> signWithNotificationKey(Uint8List data) async {
    final myPrivateKeyNode = await deriveNotificationBip32Node(
      mnemonic: (await _getMnemonicString())!,
      mnemonicPassphrase: (await _getMnemonicPassphrase())!,
    );
    final pair = btc_dart.ECPair.fromPrivateKey(myPrivateKeyNode.privateKey!,
        network: _network);
    final signed = pair.sign(SHA256Digest().process(data));
    return signed;
  }

  Future<String> signStringWithNotificationKey(String data) async {
    final bytes =
        await signWithNotificationKey(Uint8List.fromList(utf8.encode(data)));
    return Format.uint8listToString(bytes);
  }

  Future<Map<String, dynamic>> preparePaymentCodeSend({
    required PaymentCode paymentCode,
    required bool isSegwit,
    required Amount amount,
    Map<String, dynamic>? args,
  }) async {
    if (!(await hasConnected(paymentCode.toString()))) {
      throw PaynymSendException(
          "No notification transaction sent to $paymentCode");
    } else {
      final myPrivateKeyNode = await deriveNotificationBip32Node(
        mnemonic: (await _getMnemonicString())!,
        mnemonicPassphrase: (await _getMnemonicPassphrase())!,
      );
      final sendToAddress = await nextUnusedSendAddressFrom(
        pCode: paymentCode,
        privateKeyNode: myPrivateKeyNode,
        isSegwit: isSegwit,
      );

      return _prepareSend(
        address: sendToAddress.value,
        amount: amount,
        args: args,
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
      final address = await _db
          .getAddresses(_walletId)
          .filter()
          .subTypeEqualTo(AddressSubType.paynymSend)
          .and()
          .anyOf<String, Address>(keys, (q, String e) => q.otherDataEqualTo(e))
          .and()
          .derivationIndexEqualTo(i)
          .findFirst();

      if (address != null) {
        final count = await _getTxCount(address: address.value);
        // return address if unused, otherwise continue to next index
        if (count == 0) {
          return address;
        }
      } else {
        final pair = PaymentAddress(
          bip32Node: privateKeyNode,
          index: i, // index to use
          paymentCode: pCode,
          networkType: networkType,
        ).getSendAddressKeyPair();

        // add address to local db
        final address = await generatePaynymSendAddressFromKeyPair(
          pair: pair,
          derivationIndex: i,
          toPaymentCode: pCode,
          isSegwit: isSegwit,
        );

        final storedAddress = await _db.getAddress(_walletId, address.value);
        if (storedAddress == null) {
          await _db.putAddress(address);
        } else {
          await _db.updateAddress(storedAddress, address);
        }
        final count = await _getTxCount(address: address.value);
        // return address if unused, otherwise continue to next index
        if (count == 0) {
          return address;
        }
      }
    }

    throw PaynymSendException("Exhausted unused send addresses!");
  }

  Future<Map<String, dynamic>> prepareNotificationTx({
    required int selectedTxFeeRate,
    required String targetPaymentCodeString,
    required bool isSegwit,
    int additionalOutputs = 0,
    List<UTXO>? utxos,
  }) async {
    try {
      final amountToSend = _dustLimitP2PKH;
      final List<UTXO> availableOutputs =
          utxos ?? await _db.getUTXOs(_walletId).findAll();
      final List<UTXO> spendableOutputs = [];
      int spendableSatoshiValue = 0;

      // Build list of spendable outputs and totaling their satoshi amount
      for (var i = 0; i < availableOutputs.length; i++) {
        if (availableOutputs[i].isBlocked == false &&
            availableOutputs[i]
                    .isConfirmed(await _getChainHeight(), _minConfirms) ==
                true) {
          spendableOutputs.add(availableOutputs[i]);
          spendableSatoshiValue += availableOutputs[i].value;
        }
      }

      if (spendableSatoshiValue < amountToSend) {
        // insufficient balance
        throw InsufficientBalanceException(
            "Spendable balance is less than the minimum required for a notification transaction.");
      } else if (spendableSatoshiValue == amountToSend) {
        // insufficient balance due to missing amount to cover fee
        throw InsufficientBalanceException(
            "Remaining balance does not cover the network fee.");
      }

      // sort spendable by age (oldest first)
      spendableOutputs.sort((a, b) => b.blockTime!.compareTo(a.blockTime!));

      int satoshisBeingUsed = 0;
      int outputsBeingUsed = 0;
      List<UTXO> utxoObjectsToUse = [];

      for (int i = 0;
          satoshisBeingUsed < amountToSend && i < spendableOutputs.length;
          i++) {
        utxoObjectsToUse.add(spendableOutputs[i]);
        satoshisBeingUsed += spendableOutputs[i].value;
        outputsBeingUsed += 1;
      }

      // add additional outputs if required
      for (int i = 0;
          i < additionalOutputs && outputsBeingUsed < spendableOutputs.length;
          i++) {
        utxoObjectsToUse.add(spendableOutputs[outputsBeingUsed]);
        satoshisBeingUsed += spendableOutputs[outputsBeingUsed].value;
        outputsBeingUsed += 1;
      }

      // gather required signing data
      final utxoSigningData = await _fetchBuildTxData(utxoObjectsToUse);

      final int vSizeForNoChange = (await _createNotificationTx(
        targetPaymentCodeString: targetPaymentCodeString,
        utxoSigningData: utxoSigningData,
        change: 0,
        isSegwit: isSegwit,
      ))
          .item2;

      final int vSizeForWithChange = (await _createNotificationTx(
        targetPaymentCodeString: targetPaymentCodeString,
        utxoSigningData: utxoSigningData,
        change: satoshisBeingUsed - amountToSend,
        isSegwit: isSegwit,
      ))
          .item2;

      // Assume 2 outputs, for recipient and payment code script
      int feeForNoChange = _estimateTxFee(
        vSize: vSizeForNoChange,
        feeRatePerKB: selectedTxFeeRate,
      );

      // Assume 3 outputs, for recipient, payment code script, and change
      int feeForWithChange = _estimateTxFee(
        vSize: vSizeForWithChange,
        feeRatePerKB: selectedTxFeeRate,
      );

      if (_coin == Coin.dogecoin || _coin == Coin.dogecoinTestNet) {
        if (feeForNoChange < vSizeForNoChange * 1000) {
          feeForNoChange = vSizeForNoChange * 1000;
        }
        if (feeForWithChange < vSizeForWithChange * 1000) {
          feeForWithChange = vSizeForWithChange * 1000;
        }
      }

      if (satoshisBeingUsed - amountToSend > feeForNoChange + _dustLimitP2PKH) {
        // try to add change output due to "left over" amount being greater than
        // the estimated fee + the dust limit
        int changeAmount = satoshisBeingUsed - amountToSend - feeForWithChange;

        // check estimates are correct and build notification tx
        if (changeAmount >= _dustLimitP2PKH &&
            satoshisBeingUsed - amountToSend - changeAmount ==
                feeForWithChange) {
          var txn = await _createNotificationTx(
            targetPaymentCodeString: targetPaymentCodeString,
            utxoSigningData: utxoSigningData,
            change: changeAmount,
            isSegwit: isSegwit,
          );

          int feeBeingPaid = satoshisBeingUsed - amountToSend - changeAmount;

          // make sure minimum fee is accurate if that is being used
          if (txn.item2 - feeBeingPaid == 1) {
            changeAmount -= 1;
            feeBeingPaid += 1;
            txn = await _createNotificationTx(
              targetPaymentCodeString: targetPaymentCodeString,
              utxoSigningData: utxoSigningData,
              change: changeAmount,
              isSegwit: isSegwit,
            );
          }

          Map<String, dynamic> transactionObject = {
            "hex": txn.item1,
            "recipientPaynym": targetPaymentCodeString,
            "amount": amountToSend,
            "fee": feeBeingPaid,
            "vSize": txn.item2,
            "usedUTXOs": utxoSigningData.map((e) => e.utxo).toList(),
          };
          return transactionObject;
        } else {
          // something broke during fee estimation or the change amount is smaller
          // than the dust limit. Try without change
          final txn = await _createNotificationTx(
            targetPaymentCodeString: targetPaymentCodeString,
            utxoSigningData: utxoSigningData,
            change: 0,
            isSegwit: isSegwit,
          );

          int feeBeingPaid = satoshisBeingUsed - amountToSend;

          Map<String, dynamic> transactionObject = {
            "hex": txn.item1,
            "recipientPaynym": targetPaymentCodeString,
            "amount": amountToSend,
            "fee": feeBeingPaid,
            "vSize": txn.item2,
            "usedUTXOs": utxoSigningData.map((e) => e.utxo).toList(),
          };
          return transactionObject;
        }
      } else if (satoshisBeingUsed - amountToSend >= feeForNoChange) {
        // since we already checked if we need to add a change output we can just
        // build without change here
        final txn = await _createNotificationTx(
          targetPaymentCodeString: targetPaymentCodeString,
          utxoSigningData: utxoSigningData,
          change: 0,
          isSegwit: isSegwit,
        );

        int feeBeingPaid = satoshisBeingUsed - amountToSend;

        Map<String, dynamic> transactionObject = {
          "hex": txn.item1,
          "recipientPaynym": targetPaymentCodeString,
          "amount": amountToSend,
          "fee": feeBeingPaid,
          "vSize": txn.item2,
          "usedUTXOs": utxoSigningData.map((e) => e.utxo).toList(),
        };
        return transactionObject;
      } else {
        // if we get here we do not have enough funds to cover the tx total so we
        // check if we have any more available outputs and try again
        if (spendableOutputs.length > outputsBeingUsed) {
          return prepareNotificationTx(
            selectedTxFeeRate: selectedTxFeeRate,
            targetPaymentCodeString: targetPaymentCodeString,
            additionalOutputs: additionalOutputs + 1,
            isSegwit: isSegwit,
          );
        } else {
          throw InsufficientBalanceException(
              "Remaining balance does not cover the network fee.");
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
    required bool isSegwit,
    required List<SigningData> utxoSigningData,
    required int change,
  }) async {
    try {
      final targetPaymentCode = PaymentCode.fromPaymentCode(
        targetPaymentCodeString,
        networkType: _network,
      );
      final myCode = await getPaymentCode(isSegwit: isSegwit);

      final utxo = utxoSigningData.first.utxo;
      final txPoint = utxo.txid.fromHex.reversed.toList();
      final txPointIndex = utxo.vout;

      final rev = Uint8List(txPoint.length + 4);
      Util.copyBytes(Uint8List.fromList(txPoint), 0, rev, 0, txPoint.length);
      final buffer = rev.buffer.asByteData();
      buffer.setUint32(txPoint.length, txPointIndex, Endian.little);

      final myKeyPair = utxoSigningData.first.keyPair!;

      final S = SecretPoint(
        myKeyPair.privateKey!,
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
      final txb = btc_dart.TransactionBuilder(network: _network);
      txb.setVersion(1);

      txb.addInput(
        utxo.txid,
        txPointIndex,
        null,
        utxoSigningData.first.output!,
      );

      // add rest of possible inputs
      for (var i = 1; i < utxoSigningData.length; i++) {
        final utxo = utxoSigningData[i].utxo;
        txb.addInput(
          utxo.txid,
          utxo.vout,
          null,
          utxoSigningData[i].output!,
        );
      }
      final String notificationAddress;
      if (isSegwit) {
        final publicKey = targetPaymentCode.derivePublicKey(0);
        final data = btc_dart.P2WPKH(
          data: btc_dart.PaymentData(pubkey: publicKey),
          network: networkType,
        );
        notificationAddress = data.data.address!;
      } else {
        notificationAddress = targetPaymentCode.notificationAddressP2PKH();
      }

      txb.addOutput(
        notificationAddress,
        isSegwit ? _dustLimit : _dustLimitP2PKH,
      );
      txb.addOutput(opReturnScript, 0);

      // TODO: add possible change output and mark output as dangerous
      if (change > 0) {
        // generate new change address if current change address has been used
        await _checkChangeAddressForTransactions();
        final String changeAddress = await _getCurrentChangeAddress();
        txb.addOutput(changeAddress, change);
      }

      txb.sign(
        vin: 0,
        keyPair: myKeyPair,
        witnessValue: utxo.value,
        witnessScript: utxoSigningData.first.redeemScript,
      );

      // sign rest of possible inputs
      for (var i = 1; i < utxoSigningData.length; i++) {
        txb.sign(
          vin: i,
          keyPair: utxoSigningData[i].keyPair!,
          witnessValue: utxoSigningData[i].utxo.value,
          witnessScript: utxoSigningData[i].redeemScript,
        );
      }

      final builtTx = txb.build();

      return Tuple2(builtTx.toHex(), builtTx.virtualSize());
    } catch (e, s) {
      Logging.instance.log(
        "_createNotificationTx(): $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  Future<String> broadcastNotificationTx({
    required Map<String, dynamic> preparedTx,
  }) async {
    try {
      Logging.instance.log("confirmNotificationTx txData: $preparedTx",
          level: LogLevel.Info);
      final txHash = await _electrumXClient.broadcastTransaction(
          rawTx: preparedTx["hex"] as String);
      Logging.instance.log("Sent txHash: $txHash", level: LogLevel.Info);

      // TODO: only refresh transaction data
      try {
        await _refresh();
      } catch (e) {
        Logging.instance.log(
          "refresh() failed in confirmNotificationTx ($_walletName::$_walletId): $e",
          level: LogLevel.Error,
        );
      }

      return txHash;
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from confirmSend(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  // Future<bool?> _checkHasConnectedCache(String paymentCodeString) async {
  //   final value = await _secureStorage.read(
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
  //   await _secureStorage.write(
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
    // final tx = await _db
    //     .getTransactions(_walletId)
    //     .filter()
    //     .subTypeEqualTo(TransactionSubType.bip47Notification).and()
    //     .address((q) =>
    //         q.anyOf<String, Transaction>(keys, (q, e) => q.otherDataEqualTo(e)))
    //     .findAll();

    final myNotificationAddress =
        await getMyNotificationAddress(isSegwit: false);
    final myNotificationAddressSegwit =
        await getMyNotificationAddress(isSegwit: true);

    final txns = await _db
        .getTransactions(_walletId)
        .filter()
        .subTypeEqualTo(TransactionSubType.bip47Notification)
        .findAll();

    for (final tx in txns) {
      if (tx.type == TransactionType.incoming &&
          (tx.address.value?.value == myNotificationAddress.value ||
              tx.address.value?.value == myNotificationAddressSegwit.value)) {
        final unBlindedPaymentCode = await unBlindedPaymentCodeFromTransaction(
          transaction: tx,
        );

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
      } else if (tx.type == TransactionType.outgoing) {
        if (tx.address.value?.otherData != null) {
          final code =
              await paymentCodeStringByKey(tx.address.value!.otherData!);
          if (code == paymentCodeString) {
            // await _setConnectedCache(paymentCodeString, true);
            return true;
          }
        }
      }
    }

    // otherwise return no
    // await _setConnectedCache(paymentCodeString, false);
    return false;
  }

  Uint8List? _pubKeyFromInput(Input input) {
    final scriptSigComponents = input.scriptSigAsm?.split(" ") ?? [];
    if (scriptSigComponents.length > 1) {
      return scriptSigComponents[1].fromHex;
    }
    if (input.witness != null) {
      try {
        final witnessComponents = jsonDecode(input.witness!) as List;
        if (witnessComponents.length == 2) {
          return (witnessComponents[1] as String).fromHex;
        }
      } catch (_) {
        //
      }
    }
    return null;
  }

  Future<PaymentCode?> unBlindedPaymentCodeFromTransaction({
    required Transaction transaction,
  }) async {
    try {
      final blindedCodeBytes =
          Bip47Utils.getBlindedPaymentCodeBytesFrom(transaction);

      // transaction does not contain a payment code
      if (blindedCodeBytes == null) {
        return null;
      }

      final designatedInput = transaction.inputs.first;

      final txPoint = designatedInput.txid.fromHex.reversed.toList();
      final txPointIndex = designatedInput.vout;

      final rev = Uint8List(txPoint.length + 4);
      Util.copyBytes(Uint8List.fromList(txPoint), 0, rev, 0, txPoint.length);
      final buffer = rev.buffer.asByteData();
      buffer.setUint32(txPoint.length, txPointIndex, Endian.little);

      final pubKey = _pubKeyFromInput(designatedInput)!;

      final myPrivateKey = (await deriveNotificationBip32Node(
        mnemonic: (await _getMnemonicString())!,
        mnemonicPassphrase: (await _getMnemonicPassphrase())!,
      ))
          .privateKey!;

      final S = SecretPoint(myPrivateKey, pubKey);

      final mask = PaymentCode.getMask(S.ecdhSecret(), rev);

      final unBlindedPayload = PaymentCode.blind(
        payload: blindedCodeBytes,
        mask: mask,
        unBlind: true,
      );

      final unBlindedPaymentCode = PaymentCode.fromPayload(
        unBlindedPayload,
        networkType: _network,
      );

      return unBlindedPaymentCode;
    } catch (e) {
      Logging.instance.log(
        "unBlindedPaymentCodeFromTransaction() failed: $e",
        level: LogLevel.Warning,
      );
      return null;
    }
  }

  Future<PaymentCode?> unBlindedPaymentCodeFromTransactionBad({
    required Transaction transaction,
  }) async {
    try {
      final blindedCodeBytes =
          Bip47Utils.getBlindedPaymentCodeBytesFrom(transaction);

      // transaction does not contain a payment code
      if (blindedCodeBytes == null) {
        return null;
      }

      final designatedInput = transaction.inputs.first;

      final txPoint = designatedInput.txid.fromHex.toList();
      final txPointIndex = designatedInput.vout;

      final rev = Uint8List(txPoint.length + 4);
      Util.copyBytes(Uint8List.fromList(txPoint), 0, rev, 0, txPoint.length);
      final buffer = rev.buffer.asByteData();
      buffer.setUint32(txPoint.length, txPointIndex, Endian.little);

      final pubKey = _pubKeyFromInput(designatedInput)!;

      final myPrivateKey = (await deriveNotificationBip32Node(
        mnemonic: (await _getMnemonicString())!,
        mnemonicPassphrase: (await _getMnemonicPassphrase())!,
      ))
          .privateKey!;

      final S = SecretPoint(myPrivateKey, pubKey);

      final mask = PaymentCode.getMask(S.ecdhSecret(), rev);

      final unBlindedPayload = PaymentCode.blind(
        payload: blindedCodeBytes,
        mask: mask,
        unBlind: true,
      );

      final unBlindedPaymentCode = PaymentCode.fromPayload(
        unBlindedPayload,
        networkType: _network,
      );

      return unBlindedPaymentCode;
    } catch (e) {
      Logging.instance.log(
        "unBlindedPaymentCodeFromTransaction() failed: $e",
        level: LogLevel.Warning,
      );
      return null;
    }
  }

  Future<List<PaymentCode>>
      getAllPaymentCodesFromNotificationTransactions() async {
    final txns = await _db
        .getTransactions(_walletId)
        .filter()
        .subTypeEqualTo(TransactionSubType.bip47Notification)
        .findAll();

    List<PaymentCode> codes = [];

    for (final tx in txns) {
      // tx is sent so we can check the address's otherData for the code String
      if (tx.type == TransactionType.outgoing &&
          tx.address.value?.otherData != null) {
        final codeString =
            await paymentCodeStringByKey(tx.address.value!.otherData!);
        if (codeString != null &&
            codes.where((e) => e.toString() == codeString).isEmpty) {
          codes.add(
            PaymentCode.fromPaymentCode(
              codeString,
              networkType: _network,
            ),
          );
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
      Set<String> otherCodeStrings) async {
    final sentNotificationTransactions = await _db
        .getTransactions(_walletId)
        .filter()
        .subTypeEqualTo(TransactionSubType.bip47Notification)
        .and()
        .typeEqualTo(TransactionType.outgoing)
        .findAll();

    final List<PaymentCode> codes = [];
    for (final codeString in otherCodeStrings) {
      codes.add(PaymentCode.fromPaymentCode(codeString, networkType: _network));
    }

    for (final tx in sentNotificationTransactions) {
      if (tx.address.value != null && tx.address.value!.otherData == null) {
        final oldAddress =
            await _db.getAddress(_walletId, tx.address.value!.value);
        for (final code in codes) {
          final notificationAddress = code.notificationAddressP2PKH();
          if (notificationAddress == oldAddress!.value) {
            final address = Address(
              walletId: _walletId,
              value: notificationAddress,
              publicKey: [],
              derivationIndex: 0,
              derivationPath: oldAddress.derivationPath,
              type: oldAddress.type,
              subType: AddressSubType.paynymNotification,
              otherData: await storeCode(code.toString()),
            );
            await _db.updateAddress(oldAddress, address);
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
          networkType: _network,
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
        restoreHistoryWith(
          other: code,
          maxUnusedAddressGap: maxUnusedAddressGap,
          maxNumberOfIndexesToCheck: maxNumberOfIndexesToCheck,
          checkSegwitAsWell: code.isSegWitEnabled(),
        ),
      );
    }

    await Future.wait(futures);
  }

  Future<void> restoreHistoryWith({
    required PaymentCode other,
    required bool checkSegwitAsWell,
    required int maxUnusedAddressGap,
    required int maxNumberOfIndexesToCheck,
  }) async {
    // https://en.bitcoin.it/wiki/BIP_0047#Path_levels
    const maxCount = 2147483647;
    assert(maxNumberOfIndexesToCheck < maxCount);

    final mnemonic = (await _getMnemonicString())!;
    final mnemonicPassphrase = (await _getMnemonicPassphrase())!;

    final mySendBip32Node = await deriveNotificationBip32Node(
      mnemonic: mnemonic,
      mnemonicPassphrase: mnemonicPassphrase,
    );
    final receivingNode = (await _getRootNode(
      mnemonic: mnemonic,
      mnemonicPassphrase: mnemonicPassphrase,
    ))
        .derivePath(kPaynymDerivePath);

    List<Address> addresses = [];
    int receivingGapCounter = 0;
    int outgoingGapCounter = 0;

    // non segwit receiving
    for (int i = 0;
        i < maxNumberOfIndexesToCheck &&
            receivingGapCounter < maxUnusedAddressGap;
        i++) {
      if (receivingGapCounter < maxUnusedAddressGap) {
        final paymentAddressReceiving = PaymentAddress(
          paymentCode: other,
          bip32Node: receivingNode.derive(i),
          index: 0,
          networkType: networkType,
        );

        final pair = paymentAddressReceiving.getReceiveAddressKeyPair();
        final address = await generatePaynymReceivingAddressFromKeyPair(
          pair: pair,
          derivationIndex: i,
          isSegwit: false,
          fromPaymentCode: other,
        );
        addresses.add(address);

        final count = await _getTxCount(address: address.value);

        if (count > 0) {
          receivingGapCounter = 0;
        } else {
          receivingGapCounter++;
        }
      }
    }

    // non segwit sends
    for (int i = 0;
        i < maxNumberOfIndexesToCheck &&
            outgoingGapCounter < maxUnusedAddressGap;
        i++) {
      if (outgoingGapCounter < maxUnusedAddressGap) {
        final pair = PaymentAddress(
          paymentCode: other,
          bip32Node: mySendBip32Node,
          index: i,
          networkType: networkType,
        ).getSendAddressKeyPair();
        final address = await generatePaynymSendAddressFromKeyPair(
          pair: pair,
          derivationIndex: i,
          isSegwit: false,
          toPaymentCode: other,
        );
        addresses.add(address);

        final count = await _getTxCount(address: address.value);

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
      for (int i = 0;
          i < maxNumberOfIndexesToCheck &&
              receivingGapCounterSegwit < maxUnusedAddressGap;
          i++) {
        if (receivingGapCounterSegwit < maxUnusedAddressGap) {
          final paymentAddressReceiving = PaymentAddress(
            paymentCode: other,
            bip32Node: receivingNode.derive(i),
            index: 0,
            networkType: networkType,
          );

          final pair = paymentAddressReceiving.getReceiveAddressKeyPair();
          final address = await generatePaynymReceivingAddressFromKeyPair(
            pair: pair,
            derivationIndex: i,
            isSegwit: true,
            fromPaymentCode: other,
          );
          addresses.add(address);

          final count = await _getTxCount(address: address.value);

          if (count > 0) {
            receivingGapCounterSegwit = 0;
          } else {
            receivingGapCounterSegwit++;
          }
        }
      }

      // segwit sends
      for (int i = 0;
          i < maxNumberOfIndexesToCheck &&
              outgoingGapCounterSegwit < maxUnusedAddressGap;
          i++) {
        if (outgoingGapCounterSegwit < maxUnusedAddressGap) {
          final pair = PaymentAddress(
            paymentCode: other,
            bip32Node: mySendBip32Node,
            index: i,
            networkType: networkType,
          ).getSendAddressKeyPair();
          final address = await generatePaynymSendAddressFromKeyPair(
            pair: pair,
            derivationIndex: i,
            isSegwit: true,
            toPaymentCode: other,
          );
          addresses.add(address);

          final count = await _getTxCount(address: address.value);

          if (count > 0) {
            outgoingGapCounterSegwit = 0;
          } else {
            outgoingGapCounterSegwit++;
          }
        }
      }
    }
    await _db.updateOrPutAddresses(addresses);
  }

  Future<Address> generatePaynymSendAddressFromKeyPair({
    required btc_dart.ECPair pair,
    required int derivationIndex,
    required bool isSegwit,
    required PaymentCode toPaymentCode,
  }) async {
    final data = btc_dart.PaymentData(pubkey: pair.publicKey);

    final String addressString;

    if (isSegwit) {
      addressString = btc_dart
          .P2WPKH(
            network: _network,
            data: data,
          )
          .data
          .address!;
    } else {
      addressString = btc_dart
          .P2PKH(
            data: data,
            network: _network,
          )
          .data
          .address!;
    }

    final address = Address(
      walletId: _walletId,
      value: addressString,
      publicKey: pair.publicKey,
      derivationIndex: derivationIndex,
      derivationPath: DerivationPath()
        ..value = _sendPaynymAddressDerivationPath(derivationIndex),
      type: AddressType.nonWallet,
      subType: AddressSubType.paynymSend,
      otherData: await storeCode(toPaymentCode.toString()),
    );

    return address;
  }

  Future<Address> generatePaynymReceivingAddressFromKeyPair({
    required btc_dart.ECPair pair,
    required int derivationIndex,
    required bool isSegwit,
    required PaymentCode fromPaymentCode,
  }) async {
    final data = btc_dart.PaymentData(pubkey: pair.publicKey);

    final String addressString;
    final AddressType addressType;

    if (isSegwit) {
      addressString = btc_dart
          .P2WPKH(
            network: _network,
            data: data,
          )
          .data
          .address!;
      addressType = AddressType.p2wpkh;
    } else {
      addressString = btc_dart
          .P2PKH(
            data: data,
            network: _network,
          )
          .data
          .address!;
      addressType = AddressType.p2pkh;
    }

    final address = Address(
      walletId: _walletId,
      value: addressString,
      publicKey: pair.publicKey,
      derivationIndex: derivationIndex,
      derivationPath: DerivationPath()
        ..value = _receivingPaynymAddressDerivationPath(derivationIndex),
      type: addressType,
      subType: AddressSubType.paynymReceive,
      otherData: await storeCode(fromPaymentCode.toString()),
    );

    final myCode = await getPaymentCode(isSegwit: isSegwit);

    final bip32NetworkType = bip32.NetworkType(
      wif: _network.wif,
      bip32: bip32.Bip32Type(
        public: _network.bip32.public,
        private: _network.bip32.private,
      ),
    );

    final bip32.BIP32 node = bip32.BIP32.fromPrivateKey(
      pair.privateKey!,
      myCode.getChain(),
      bip32NetworkType,
    );

    return address;
  }

  Future<Address> getMyNotificationAddress({
    required bool isSegwit,
  }) async {
    final AddressType type = isSegwit ? AddressType.p2wpkh : AddressType.p2pkh;

    final storedAddress = await _db
        .getAddresses(_walletId)
        .filter()
        .subTypeEqualTo(AddressSubType.paynymNotification)
        .and()
        .typeEqualTo(type)
        .and()
        .not()
        .typeEqualTo(AddressType.nonWallet)
        .findFirst();

    if (storedAddress != null) {
      return storedAddress;
    } else {
      final root = await _getRootNode(
        mnemonic: (await _getMnemonicString())!,
        mnemonicPassphrase: (await _getMnemonicPassphrase())!,
      );
      final node = root.derivePath(kPaynymDerivePath);
      final paymentCode = PaymentCode.fromBip32Node(
        node,
        networkType: _network,
        shouldSetSegwitBit: isSegwit,
      );

      final String addressString;
      final data = btc_dart.PaymentData(
        pubkey: paymentCode.notificationPublicKey(),
      );

      if (isSegwit) {
        addressString = btc_dart
            .P2WPKH(
              network: _network,
              data: data,
            )
            .data
            .address!;
      } else {
        addressString = btc_dart
            .P2PKH(
              data: data,
              network: _network,
            )
            .data
            .address!;
      }

      final address = Address(
        walletId: _walletId,
        value: addressString,
        publicKey: paymentCode.getPubKey(),
        derivationIndex: 0,
        derivationPath: DerivationPath()
          ..value = kPaynymNotificationDerivationPath,
        type: type,
        subType: AddressSubType.paynymNotification,
        otherData: await storeCode(paymentCode.toString()),
      );

      await _db.putAddress(address);
      return address;
    }
  }

  /// look up a key that corresponds to a payment code string
  Future<List<String>> lookupKey(String paymentCodeString) async {
    final keys =
        (await _secureStorage.keys).where((e) => e.startsWith(kPCodeKeyPrefix));
    final List<String> result = [];
    for (final key in keys) {
      final value = await _secureStorage.read(key: key);
      if (value == paymentCodeString) {
        result.add(key);
      }
    }
    return result;
  }

  /// fetch a payment code string
  Future<String?> paymentCodeStringByKey(String key) async {
    final value = await _secureStorage.read(key: key);
    return value;
  }

  /// store payment code string and return the generated key used
  Future<String> storeCode(String paymentCodeString) async {
    final key = _generateKey();
    await _secureStorage.write(key: key, value: paymentCodeString);
    return key;
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
        List<int>.generate(n, (_) => rng.nextInt(0xFF + 1)));
  }
}
