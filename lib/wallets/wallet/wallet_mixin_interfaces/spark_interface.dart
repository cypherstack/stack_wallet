import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:coin/coin.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:logger/logger.dart';

import '../../../db/drift/database.dart' show Drift;
import '../../../db/sqlite/firo_cache.dart';
import '../../../models/balance.dart';
import '../../../models/electrumx_response/spark_models.dart';
import '../../../models/input.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../models/keys/view_only_wallet_data.dart';
import '../../../services/event_bus/events/global/refresh_percent_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
import '../../../services/spark_names_service.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/prefs.dart';
import '../../../wl_gen/interfaces/lib_spark_interface.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../../isar/models/spark_coin.dart';
import '../../isar/models/wallet_info.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_hd_wallet.dart';
import 'cpfp_interface.dart';
import 'electrumx_interface.dart';

const kDefaultSparkIndex = 1;

// TODO dart style constants. Maybe move to spark lib?
// https://github.com/firoorg/firo/pull/1457/files#diff-1fc0f6b5081e8ed5dfa8bf230744ad08cc6f4c1147e98552f1f424b0492fe9bdR28
const MAX_NEW_TX_WEIGHT = 1000000;

//https://github.com/firoorg/sparkmobile/blob/ef2e39aae18ecc49e0ddc63a3183e9764b96012e/include/spark.h#L16
const SPARK_OUT_LIMIT_PER_TX = 16;

const OP_SPARKMINT = 0xd1;
const OP_SPARKSMINT = 0xd2;
const OP_SPARKSPEND = 0xd3;

/// top level function for use with [compute]
String _hashTag(String tag) {
  final components = tag.split(",");
  final x = components[0].substring(1);
  final y = components[1].substring(0, components[1].length - 1);

  final hash = libSpark.hashTag(x, y);
  return hash;
}

void initSparkLogging(Level level) => libSpark.initSparkLogging(level);

abstract class _SparkIsolate {
  static Isolate? _isolate;
  static SendPort? _sendPort;
  static final ReceivePort _receivePort = ReceivePort();

  static Completer<void>? completer;

  static Future<void> initialize() async {
    if (completer != null) {
      if (!completer!.isCompleted) {
        await completer!.future;
      }

      return;
    }
    completer = Completer();

    final level = Prefs.instance.logLevel;

    _isolate = await Isolate.spawn((SendPort sendPort) {
      initSparkLogging(level); // ensure logging is set up in isolate

      final receivePort = ReceivePort();

      sendPort.send(receivePort.sendPort);

      receivePort.listen((message) async {
        if (message is List && message.length == 3) {
          final function = message[0] as Function;
          final argument = message[1];
          final replyPort = message[2] as SendPort;

          final result = await function(argument);
          replyPort.send(result);
        }
      });
    }, _receivePort.sendPort);
    _sendPort = await _receivePort.first as SendPort;
    completer!.complete();
  }

  static Future<R> run<M, R>(ComputeCallback<M, R> task, M argument) async {
    if (_isolate == null || _sendPort == null) await initialize();

    final ReceivePort responsePort = ReceivePort();
    _sendPort?.send([task, argument, responsePort.sendPort]);
    return await responsePort.first as R;
  }
}

Future<R> computeWithLibSparkLogging<M, R>(
  ComputeCallback<M, R> callback,
  M message,
) async {
  return _SparkIsolate.run(callback, message);
}

mixin SparkInterface<T extends ElectrumXCurrencyInterface>
    on Bip39HDWallet<T>, ElectrumXInterface<T> {
  Address? _currentSparkAddress;

  String? _viewKeyHex;
  String? get sparkViewKey => _viewKeyHex!;

  Address? _sparkChangeAddress;

  String? get sparkChangeAddress => _sparkChangeAddress?.value;

  bool get isTestNet {
    return cryptoCurrency.network.isTestNet;
  }

  // This is the BIP44 derivation path for the spark private key; spark public
  // keys will have their own derivation path.
  String get sparkDerivationPath {
    // NOTE: This is reusing the sparkIndex for backwards compatibility, but
    // these are actually distinct things which do not have to be the same.
    // sparkIndex has nothing at all to do with the derivation path.
    if (isTestNet) {
      return "${libSpark.sparkBaseDerivationPathTestnet}$kDefaultSparkIndex";
    } else {
      return "${libSpark.sparkBaseDerivationPath}$kDefaultSparkIndex";
    }
  }

  // This is the index for the spark key, which is NOT the diversifier or the
  // BIP44 derivation path (which generates the private key data).
  int get sparkIndex => kDefaultSparkIndex;

  Future<Address> _generateSparkAddress(int diversifier) async {
    if (isViewOnly && viewOnlyType != .spark) {
      throw Exception(
        "Cannot generate a spark address for a non spark view only firo wallet",
      );
    }

    final sparkAddress =
        await computeWithLibSparkLogging(_getAddressFromFullViewKey, (
          fullViewKeyHex: _viewKeyHex!,
          index: sparkIndex,
          diversifier: diversifier,
          isTestNet: isTestNet,
        ));

    return Address(
      walletId: walletId,
      value: sparkAddress,
      publicKey: [],
      derivationIndex: diversifier,
      derivationPath: DerivationPath()..value = sparkDerivationPath,
      type: AddressType.spark,
      subType: diversifier == libSpark.sparkChange ? .change : .receiving,
    );
  }

  static bool validateSparkAddress({
    required String address,
    required bool isTestNet,
  }) {
    return libSpark.validateAddress(address: address, isTestNet: isTestNet);
  }

  Future<List<SparkCoin>> identifyCoins({
    required List<dynamic> anonymitySetCoins,
    required int groupId,
  }) async {
    return await computeWithLibSparkLogging(identifyCoinsStatic, (
      walletId_: walletId,
      viewKeyHex_: _viewKeyHex!,
      isTestNet_: isTestNet,
      anonymitySetCoins: anonymitySetCoins,
      groupId: groupId,
    ));
  }

  static Future<List<SparkCoin>> identifyCoinsStatic(
    ({
      List<dynamic> anonymitySetCoins,
      int groupId,
      bool isTestNet_,
      String viewKeyHex_,
      String walletId_,
    })
    args,
  ) async {
    final List<SparkCoin> myCoins = [];

    for (final dynData in args.anonymitySetCoins) {
      final data = List<String>.from(dynData as List);

      if (data.length != 3) {
        Logging.instance.e(
          "Unexpected serialized coin info found",
          error: data,
        );
        continue;
      }

      final serializedCoinB64 = data[0];
      final txHash = data[1].toHexReversedFromBase64;
      final contextB64 = data[2];

      final WrappedLibSparkCoin? coin;
      try {
        coin = libSpark.identifyAndRecoverCoinByFullViewKey(
          serializedCoinB64,
          fullViewKeyHex: args.viewKeyHex_,
          context: base64Decode(contextB64),
          isTestNet: args.isTestNet_,
        );
      } catch (e) {
        Logging.instance.e(
          "Error identifying coin in tx $txHash (this is not expected)",
          error: e,
        );
        continue;
      }

      // its ours
      if (coin != null) {
        final SparkCoinType coinType;
        switch (coin.type.value) {
          case 0:
            coinType = SparkCoinType.mint;
          case 1:
            coinType = SparkCoinType.spend;
          default:
            Logging.instance.e(
              "Unknown spark coin type detected",
              error: coin.type.value,
            );
            continue;
        }

        myCoins.add(
          SparkCoin(
            walletId: args.walletId_,
            type: coinType,
            // isUsed is a placeholder value here; its value is incorrect.
            isUsed: false,
            groupId: args.groupId,
            nonce: coin.nonceHex?.toUint8ListFromHex,
            address: coin.address!,
            txHash: txHash,
            valueIntString: coin.value!.toString(),
            memo: coin.memo,
            serialContext: coin.serialContext,
            diversifierIntString: coin.diversifier!.toString(),
            encryptedDiversifier: coin.encryptedDiversifier,
            serial: coin.serial,
            tag: coin.tag,
            lTagHash: coin.lTagHash!,
            height: coin.height,
            serializedCoinB64: serializedCoinB64,
            contextB64: contextB64,
          ),
        );
      }
    }

    return myCoins;
  }

  Future<String> hashTag(String tag) async {
    try {
      return await computeWithLibSparkLogging(_hashTag, tag);
    } catch (_) {
      throw ArgumentError("Invalid tag string format", "tag");
    }
  }

  @override
  Future<void> init() async {
    if (isViewOnly && viewOnlyType != .spark) {
      return super.init();
    }

    try {
      final sparkUsedTagsResetVersion =
          info.otherData[WalletInfoKeys.firoSparkUsedTagsCacheResetVersion]
              as int? ??
          0;

      if (sparkUsedTagsResetVersion == 0) {
        await info.updateOtherData(
          newEntries: {WalletInfoKeys.firoSparkUsedTagsCacheResetVersion: 1},
          isar: mainDB.isar,
        );
        await FiroCacheCoordinator.clearSharedCache(
          cryptoCurrency.network,
          clearOnlyUsedTagsCache: true,
        );
      }

      if (isViewOnly) {
        final walletData = await getViewOnlyWalletData();
        if (walletData is SparkViewOnlyWalletData) {
          _viewKeyHex = walletData.viewKey;
        } else {
          // TODO anything needed here?
        }
      } else {
        final root = await getRootHDNode();
        final privateKey =
            (root.derivePath(sparkDerivationPath) as DerivedSecretKey)
                .secretKey
                .bytes;
        _viewKeyHex = libSpark.getFullViewKeyHexFromPrivateKeyData(
          privateKeyHex: privateKey.toHex,
          index: sparkIndex,
        );
      }

      Address? address = await getCurrentReceivingSparkAddress();
      if (address == null) {
        address = await _generateSparkAddress(1);
        await mainDB.putAddress(address);
        if (isViewOnly &&
            viewOnlyType == .spark &&
            info.mainAddressType == .spark) {
          await info.updateReceivingAddress(
            newAddress: address.value,
            isar: mainDB.isar,
          );
        }
      }

      if (address.derivationIndex == -1) {
        throw Exception("Error finding spark receiving address");
      }

      _currentSparkAddress = address;
      _sparkChangeAddress = await _generateSparkAddress(libSpark.sparkChange);
    } catch (e, s) {
      // do nothing, still allow user into wallet
      Logging.instance.e("$runtimeType init() failed", error: e, stackTrace: s);
    }

    await super.init();
  }

  @override
  Future<List<Address>> fetchAddressesForElectrumXScan() async {
    return await mainDB
        .getAddresses(walletId)
        .filter()
        .not()
        .group(
          (q) => q
              .typeEqualTo(AddressType.spark)
              .or()
              .typeEqualTo(AddressType.nonWallet)
              .or()
              .subTypeEqualTo(AddressSubType.nonWallet),
        )
        .findAll();
  }

  Future<Address?> getCurrentReceivingSparkAddress() async {
    try {
      // if _currentSparkAddress is not initialized, this will throw.
      return _currentSparkAddress!;
    } catch (e) {
      return await mainDB.isar.addresses
          .where()
          .walletIdEqualTo(walletId)
          .filter()
          .typeEqualTo(AddressType.spark)
          .sortByDerivationIndexDesc()
          .findFirst();
    }
  }

  Future<Address> generateNextSparkAddress({required bool saveToDB}) async {
    final currentDiversifier =
        (await getCurrentReceivingSparkAddress())?.derivationIndex;
    // if current is null, start at index 1
    int diversifier = (currentDiversifier ?? 0) + 1;
    if (diversifier == libSpark.sparkChange) {
      diversifier++; // ensure only receiving addresses are shown
    }
    final newAddress = await _generateSparkAddress(diversifier);
    _currentSparkAddress = newAddress;
    if (saveToDB) {
      await mainDB.updateOrPutAddresses([newAddress]);
      if (isViewOnly &&
          viewOnlyType == .spark &&
          info.mainAddressType == .spark) {
        await info.updateReceivingAddress(
          newAddress: newAddress.value,
          isar: mainDB.isar,
        );
      }
    }

    return newAddress;
  }

  Future<Amount> estimateFeeForSpark(Amount amount) async {
    if (isViewOnly) {
      throw Exception("Fee estimation is not supported for view only wallets");
    }

    final spendAmount = amount.raw.toInt();
    if (spendAmount == 0) {
      return Amount(
        rawValue: BigInt.from(0),
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    } else {
      // fetch spendable spark coins
      final coins = await mainDB.isar.sparkCoins
          .where()
          .walletIdEqualToAnyLTagHash(walletId)
          .filter()
          .isUsedEqualTo(false)
          .and()
          .heightIsNotNull()
          .and()
          .not()
          .valueIntStringEqualTo("0")
          .findAll();

      final available = coins
          .map((e) => e.value)
          .fold(BigInt.zero, (p, e) => p + e);

      if (amount.raw > available) {
        return Amount(
          rawValue: BigInt.from(0),
          fractionDigits: cryptoCurrency.fractionDigits,
        );
      }

      // prepare coin data for ffi
      final serializedCoins = coins
          .map(
            (e) => (
              serializedCoin: e.serializedCoinB64!,
              serializedCoinContext: e.contextB64!,
              groupId: e.groupId,
              height: e.height!,
            ),
          )
          .toList();

      final root = await getRootHDNode();
      final privateKey =
          (root.derivePath(sparkDerivationPath) as DerivedSecretKey)
              .secretKey
              .bytes;
      int estimate = await _asyncSparkFeesWrapper(
        privateKeyHex: privateKey.toHex,
        index: sparkIndex,
        sendAmount: spendAmount,
        subtractFeeFromAmount: true,
        serializedCoins: serializedCoins,
        // privateRecipientsCount: (txData.sparkRecipients?.length ?? 0),
        privateRecipientsCount: 1, // ROUGHLY!
        utxoNum: 0, // TODO not zero?
        additionalTxSize: 0, // spark name script size
      );

      if (estimate < 0) {
        estimate = 0;
      }

      return Amount(
        rawValue: BigInt.from(estimate),
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    }
  }

  /// Spark to Spark/Transparent (spend) creation
  Future<TxData> prepareSendSpark({required TxData txData}) async {
    if (isViewOnly) {
      throw Exception("Spending is not supported for view only wallets");
    }

    // There should be at least one output.
    if (!(txData.recipients?.isNotEmpty == true ||
        txData.sparkRecipients?.isNotEmpty == true)) {
      throw Exception("No recipients provided.");
    }

    if (txData.sparkRecipients?.isNotEmpty == true &&
        txData.sparkRecipients!.length >= SPARK_OUT_LIMIT_PER_TX - 1) {
      throw Exception("Spark shielded output limit exceeded.");
    }

    final transparentSumOut = (txData.recipients ?? [])
        .map((e) => e.amount)
        .fold(
          Amount(
            rawValue: BigInt.zero,
            fractionDigits: cryptoCurrency.fractionDigits,
          ),
          (p, e) => p + e,
        );

    // See SPARK_VALUE_SPEND_LIMIT_PER_TRANSACTION at https://github.com/firoorg/sparkmobile/blob/ef2e39aae18ecc49e0ddc63a3183e9764b96012e/include/spark.h#L17
    // and COIN https://github.com/firoorg/sparkmobile/blob/ef2e39aae18ecc49e0ddc63a3183e9764b96012e/bitcoin/amount.h#L17
    // Note that as MAX_MONEY is greater than this limit, we can ignore it.  See https://github.com/firoorg/sparkmobile/blob/ef2e39aae18ecc49e0ddc63a3183e9764b96012e/bitcoin/amount.h#L31
    // NOTE: This was updated to 5x what is was before (previously 10k)
    if (transparentSumOut >
        Amount.fromDecimal(
          Decimal.parse("50000"),
          fractionDigits: cryptoCurrency.fractionDigits,
        )) {
      throw Exception(
        "Spend to transparent address limit exceeded "
        "(50,000 Firo per transaction).",
      );
    }

    final sparkSumOut = (txData.sparkRecipients ?? [])
        .map((e) => e.amount)
        .fold(
          Amount(
            rawValue: BigInt.zero,
            fractionDigits: cryptoCurrency.fractionDigits,
          ),
          (p, e) => p + e,
        );

    final txAmount = transparentSumOut + sparkSumOut;

    // fetch spendable spark coins
    final coins = await mainDB.isar.sparkCoins
        .where()
        .walletIdEqualToAnyLTagHash(walletId)
        .filter()
        .isUsedEqualTo(false)
        .and()
        .heightIsNotNull()
        .and()
        .not()
        .valueIntStringEqualTo("0")
        .findAll();

    if (coins.isEmpty) {
      throw Exception("No spendable Spark coins found");
    }

    final available = info.cachedBalanceTertiary.spendable;

    if (txAmount > available) {
      throw Exception("Insufficient Spark balance");
    }

    final bool isSendAll = available == txAmount;

    // prepare coin data for ffi
    final serializedCoins = coins
        .map(
          (e) => (
            serializedCoin: e.serializedCoinB64!,
            serializedCoinContext: e.contextB64!,
            groupId: e.groupId,
            height: e.height!,
          ),
        )
        .toList();

    final myCoinGroupIds = coins.map((e) => e.groupId).toSet();

    final List<Map<String, dynamic>> setMaps = [];
    final List<({int groupId, String blockHash})> idAndBlockHashes = [];
    for (final i in myCoinGroupIds) {
      final resultSet = await FiroCacheCoordinator.getSetCoinsForGroupId(
        i,
        network: cryptoCurrency.network,
      );
      if (resultSet.isEmpty) {
        continue;
      }

      final info = await FiroCacheCoordinator.getLatestSetInfoForGroupId(
        i,
        cryptoCurrency.network,
      );
      if (info == null) {
        throw Exception("The `info` should never be null here");
      }

      final Map<String, dynamic> setData = {
        "blockHash": info.blockHash,
        "setHash": info.setHash,
        "coinGroupID": i,
        "coins": resultSet
            .map((e) => [e.serialized, e.txHash, e.context])
            .toList(),
      };

      setData["coinGroupID"] = i;
      setMaps.add(setData);
      idAndBlockHashes.add((
        groupId: i,
        blockHash: setData["blockHash"] as String,
      ));
    }

    final allAnonymitySets = setMaps
        .map(
          (e) => (
            setId: e["coinGroupID"] as int,
            setHash: e["setHash"] as String,
            set: (e["coins"] as List)
                .map(
                  (e) =>
                      (serializedCoin: e[0] as String, txHash: e[1] as String),
                )
                .toList(),
          ),
        )
        .toList();

    final root = await getRootHDNode();
    final privateKey =
        (root.derivePath(sparkDerivationPath) as DerivedSecretKey)
            .secretKey
            .bytes;

    final sparkTxVersion = 3 | (9 << 16);
    final sparkLockTime = await chainHeight;

    List<TxRecipient>? recipientsWithFeeSubtracted;
    List<({String address, Amount amount, String memo, bool isChange})>?
    sparkRecipientsWithFeeSubtracted;
    final recipientCount =
        (txData.recipients?.where((e) => e.amount.raw > BigInt.zero).length ??
        0);
    final totalRecipientCount =
        recipientCount + (txData.sparkRecipients?.length ?? 0);
    final BigInt estimatedFee;
    if (isSendAll) {
      final estFee = await _asyncSparkFeesWrapper(
        privateKeyHex: privateKey.toHex,
        index: sparkIndex,
        sendAmount: txAmount.raw.toInt(),
        subtractFeeFromAmount: true,
        serializedCoins: serializedCoins,
        privateRecipientsCount: (txData.sparkRecipients?.length ?? 0),
        utxoNum: recipientCount,
        additionalTxSize: 0, // name script size
      );
      estimatedFee = BigInt.from(estFee);
    } else {
      estimatedFee = BigInt.zero;
    }

    if ((txData.sparkRecipients?.length ?? 0) > 0) {
      sparkRecipientsWithFeeSubtracted = [];
    }
    if (recipientCount > 0) {
      recipientsWithFeeSubtracted = [];
    }

    for (int i = 0; i < (txData.sparkRecipients?.length ?? 0); i++) {
      sparkRecipientsWithFeeSubtracted!.add((
        address: txData.sparkRecipients![i].address,
        amount: Amount(
          rawValue:
              txData.sparkRecipients![i].amount.raw -
              (estimatedFee ~/ BigInt.from(totalRecipientCount)),
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        memo: txData.sparkRecipients![i].memo,
        isChange:
            _sparkChangeAddress!.value == txData.sparkRecipients![i].address,
      ));
    }

    // temp tx data to show in gui while waiting for real data from server
    final List<InputV2> tempInputs = [];
    final List<OutputV2> tempOutputs = [];

    final extractedTx = _FiroRawTx(
      version: sparkTxVersion,
      locktime: sparkLockTime,
    );

    for (int i = 0; i < (txData.recipients?.length ?? 0); i++) {
      if (txData.recipients![i].amount.raw == BigInt.zero) {
        continue;
      }
      recipientsWithFeeSubtracted!.add(
        txData.recipients![i].copyWith(
          amount: Amount(
            rawValue:
                txData.recipients![i].amount.raw -
                (estimatedFee ~/ BigInt.from(totalRecipientCount)),
            fractionDigits: cryptoCurrency.fractionDigits,
          ),
        ),
      );

      final scriptPubKey = Addr.fromString(
        txData.recipients![i].address,
        _coinChain,
      ).scriptPubKey;
      extractedTx.addOutput(
        scriptPubKey,
        recipientsWithFeeSubtracted[i].amount.raw.toInt(),
      );

      tempOutputs.add(
        OutputV2.isarCantDoRequiredInDefaultConstructor(
          scriptPubKeyHex: scriptPubKey.toHex,
          valueStringSats: recipientsWithFeeSubtracted[i].amount.raw.toString(),
          addresses: [recipientsWithFeeSubtracted[i].address.toString()],
          walletOwns:
              (await mainDB.isar.addresses
                  .where()
                  .walletIdEqualTo(walletId)
                  .filter()
                  .valueEqualTo(recipientsWithFeeSubtracted[i].address)
                  .valueProperty()
                  .findFirst()) !=
              null,
        ),
      );
    }

    if (sparkRecipientsWithFeeSubtracted != null) {
      for (final recip in sparkRecipientsWithFeeSubtracted) {
        tempOutputs.add(
          OutputV2.isarCantDoRequiredInDefaultConstructor(
            scriptPubKeyHex: Uint8List.fromList([OP_SPARKSMINT]).toHex,
            valueStringSats: recip.amount.raw.toString(),
            addresses: [recip.address.toString()],
            walletOwns:
                (await mainDB.isar.addresses
                    .where()
                    .walletIdEqualTo(walletId)
                    .filter()
                    .valueEqualTo(recip.address)
                    .valueProperty()
                    .findFirst()) !=
                null,
          ),
        );
      }
    }

    extractedTx.addInput(
      '0000000000000000000000000000000000000000000000000000000000000000'
          .toUint8ListFromHex,
      0xffffffff,
      0xffffffff,
      "d3".toUint8ListFromHex, // OP_SPARKSPEND
    );
    extractedTx.setPayload(Uint8List(0));

    ({Uint8List script, int size})? noProofNameTxData;
    if (txData.sparkNameInfo != null) {
      noProofNameTxData = libSpark.createSparkNameScript(
        sparkNameValidityBlocks: txData.sparkNameInfo!.validBlocks,
        name: txData.sparkNameInfo!.name,
        additionalInfo: txData.sparkNameInfo!.additionalInfo,
        scalarHex: extractedTx.getId(),
        privateKeyHex: privateKey.toHex,
        spendKeyIndex: sparkIndex,
        diversifier: txData.sparkNameInfo!.sparkAddress.derivationIndex,
        isTestNet: cryptoCurrency.network != CryptoCurrencyNetwork.main,
        ignoreProof: true,
        hashFailSafe: 0,
      );
    }

    final spend = await computeWithLibSparkLogging(_createSparkSend, (
      privateKeyHex: privateKey.toHex,
      index: sparkIndex,
      recipients:
          txData.recipients
              ?.map(
                (e) => (
                  address: e.address,
                  amount: e.amount.raw.toInt(),
                  subtractFeeFromAmount: isSendAll,
                ),
              )
              .toList() ??
          [],
      privateRecipients:
          txData.sparkRecipients
              ?.map(
                (e) => (
                  sparkAddress: e.address,
                  amount: e.amount.raw.toInt(),
                  subtractFeeFromAmount: isSendAll,
                  memo: e.memo,
                ),
              )
              .toList() ??
          [],
      serializedCoins: serializedCoins,
      allAnonymitySets: allAnonymitySets,
      idAndBlockHashes: idAndBlockHashes
          .map((e) => (setId: e.groupId, blockHash: base64Decode(e.blockHash)))
          .toList(),
      txHash: extractedTx.getHash(),
      additionalTxSize: txData.sparkNameInfo == null
          ? 0
          : noProofNameTxData!.size,
    ));

    for (final outputScript in spend.outputScripts) {
      extractedTx.addOutput(outputScript, 0);
    }

    extractedTx.setPayload(spend.serializedSpendPayload);

    if (txData.sparkNameInfo != null) {
      // this is name reg tx

      extractedTx.setPayload(
        Uint8List.fromList([
          ...spend.serializedSpendPayload,
          ...noProofNameTxData!.script,
        ]),
      );

      final hash = extractedTx.getId();

      ({Uint8List script, int size})? nameScriptData;
      int hashFailSafe = 0;
      while (nameScriptData == null) {
        try {
          nameScriptData = libSpark.createSparkNameScript(
            sparkNameValidityBlocks: txData.sparkNameInfo!.validBlocks,
            name: txData.sparkNameInfo!.name,
            additionalInfo: txData.sparkNameInfo!.additionalInfo,
            scalarHex: hash,
            privateKeyHex: privateKey.toHex,
            spendKeyIndex: sparkIndex,
            diversifier: txData.sparkNameInfo!.sparkAddress.derivationIndex,
            isTestNet: cryptoCurrency.network != CryptoCurrencyNetwork.main,
            ignoreProof: false,
            hashFailSafe: hashFailSafe,
          );
          break;
        } catch (e) {
          if (e.toString() != "Exception: hash fail") {
            rethrow;
          }
          hashFailSafe++;
        }
      }

      extractedTx.setPayload(
        Uint8List.fromList([
          ...spend.serializedSpendPayload,
          ...nameScriptData.script,
        ]),
      );
    }

    final rawTxHex = extractedTx.toHex();

    if (isSendAll) {
      txData = txData.copyWith(
        recipients: recipientsWithFeeSubtracted,
        sparkRecipients: sparkRecipientsWithFeeSubtracted,
      );
    }

    final fee = Amount(
      rawValue: BigInt.from(spend.fee),
      fractionDigits: cryptoCurrency.fractionDigits,
    );

    tempInputs.add(
      InputV2.isarCantDoRequiredInDefaultConstructor(
        scriptSigHex: "d3",
        scriptSigAsm: null,
        sequence: 0xffffffff,
        outpoint: null,
        addresses: [],
        valueStringSats: tempOutputs
            .map((e) => e.value)
            .fold(fee.raw, (p, e) => p + e)
            .toString(),
        witness: null,
        innerRedeemScriptAsm: null,
        coinbase: null,
        walletOwns: true,
      ),
    );

    final List<SparkCoin> usedSparkCoins = [];

    for (final usedCoin in spend.usedCoins) {
      try {
        usedSparkCoins.add(
          coins
              .firstWhere(
                (e) =>
                    usedCoin.height == e.height &&
                    usedCoin.groupId == e.groupId &&
                    base64Decode(e.serializedCoinB64!).toHex.startsWith(
                      base64Decode(usedCoin.serializedCoin).toHex,
                    ),
              )
              .copyWith(isUsed: true),
        );
      } catch (_) {
        throw Exception(
          "Unexpectedly did not find used spark coin. "
          "This should never happen.",
        );
      }
    }

    return txData.copyWith(
      raw: rawTxHex,
      vSize: extractedTx.virtualSize(),
      fee: fee,
      tempTx: TransactionV2(
        walletId: walletId,
        blockHash: null,
        hash: extractedTx.getId(),
        txid: extractedTx.getId(),
        timestamp: DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
        inputs: List.unmodifiable(tempInputs),
        outputs: List.unmodifiable(tempOutputs),
        type: tempOutputs.map((e) => e.walletOwns).fold(true, (p, e) => p &= e)
            ? TransactionType.sentToSelf
            : TransactionType.outgoing,
        subType: TransactionSubType.sparkSpend,
        otherData: jsonEncode({"overrideFee": fee.toJsonString()}),
        height: null,
        version: 3,
      ),
      usedSparkCoins: usedSparkCoins,
    );
  }

  // this may not be needed for either mints or spends or both
  Future<TxData> confirmSendSpark({required TxData txData}) async {
    if (isViewOnly) {
      throw Exception("Spending is not supported for view only wallets");
    }

    try {
      Logging.instance.d("confirmSend txData: $txData");

      final txHash = await electrumXClient.broadcastTransaction(
        rawTx: txData.raw!,
      );
      Logging.instance.d("Sent txHash: $txHash");

      txData = txData.copyWith(
        // TODO revisit setting these both
        txHash: txHash,
        txid: txHash,
      );

      // Update used spark coins as used in database. They should already have
      // been marked as isUsed.
      // TODO: [prio=med] Could (probably should) throw an exception here
      //  if txData.usedSparkCoins is null or empty
      if (txData.usedSparkCoins != null && txData.usedSparkCoins!.isNotEmpty) {
        await mainDB.isar.writeTxn(() async {
          await mainDB.isar.sparkCoins.putAll(txData.usedSparkCoins!);
        });
      }

      return await updateSentCachedTxData(txData: txData);
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from confirmSend(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // in mem cache
  Set<String> _mempoolTxids = {};
  Set<String> _mempoolTxidsChecked = {};

  Future<List<SparkCoin>> _refreshSparkCoinsMempoolCheck({
    required int groupId,
  }) async {
    final start = DateTime.now();

    // update cache
    _mempoolTxids = await electrumXClient.getMempoolTxids();

    // remove any checked txids that are not in the mempool anymore
    _mempoolTxidsChecked = _mempoolTxidsChecked.intersection(_mempoolTxids);

    // get all unchecked txids currently in mempool
    final txidsToCheck = _mempoolTxids.difference(_mempoolTxidsChecked);
    if (txidsToCheck.isEmpty) {
      return [];
    }

    // fetch spark data to scan if we own any unconfirmed spark coins
    List<SparkMempoolData> sparkDataToCheck = [];
    try {
      sparkDataToCheck = await electrumXClient.getMempoolSparkData(
        txids: txidsToCheck.toList(),
      );
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from _refreshSparkCoinsMempoolCheck(): ",
        error: e,
        stackTrace: s,
      );
      return [];
    }

    final Set<String> checkedTxids = {};
    final List<List<String>> rawCoins = [];

    for (final data in sparkDataToCheck) {
      for (int i = 0; i < data.coins.length; i++) {
        rawCoins.add([data.coins[i], data.txid, data.serialContext.first]);
      }

      checkedTxids.add(data.txid);
    }

    // if there is new data we try and identify the coins
    final List<SparkCoin> myCoins = await identifyCoins(
      anonymitySetCoins: rawCoins,
      groupId: groupId,
    );

    // add checked txids after identification
    _mempoolTxidsChecked.addAll(checkedTxids);

    Logging.instance.d(
      "Finished _refreshSparkCoinsMempoolCheck(). "
      "Duration=${DateTime.now().difference(start)}",
    );

    return myCoins;
  }

  // returns next percent
  double _triggerEventHelper(double current, double increment) {
    refreshingPercent = current;
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(current, walletId));
    return current + increment;
  }

  // Linearly make calls so there is less chance of timing out or otherwise
  // breaking
  Future<void> refreshSparkData(
    (double startingPercent, double endingPercent)? refreshProgressRange,
  ) async {
    final start = DateTime.now();

    try {
      // start by checking if any previous sets are missing from db and add the
      // missing groupIds to the list if sets to check and update
      final latestGroupId = await electrumXClient.getSparkLatestCoinId();

      final List<int> groupIds = [];
      if (latestGroupId > 1) {
        for (int id = 1; id < latestGroupId; id++) {
          final setExists =
              await FiroCacheCoordinator.checkSetInfoForGroupIdExists(
                id,
                cryptoCurrency.network,
              );
          if (!setExists) {
            groupIds.add(id);
          }
        }
      }
      groupIds.add(latestGroupId);

      final steps =
          groupIds.length +
          1 // get used tags step
          +
          1 // check updated cache step
          +
          1 // identify coins step
          +
          1 // cross ref coins and txns
          +
          1; // update balance

      final percentIncrement = refreshProgressRange == null
          ? null
          : (refreshProgressRange.$2 - refreshProgressRange.$1) / steps;
      double currentPercent = refreshProgressRange?.$1 ?? 0;

      //   fetch and update process for each set groupId as required
      for (final gId in groupIds) {
        await FiroCacheCoordinator.runFetchAndUpdateSparkAnonSetCacheForGroupId(
          gId,
          electrumXClient,
          cryptoCurrency.network,
          // null,
          (a, b) {
            if (percentIncrement != null) {
              _triggerEventHelper(
                currentPercent + (percentIncrement * (a / b)),
                0,
              );
            }
          },
        );
        if (percentIncrement != null) {
          currentPercent += percentIncrement;
        }
      }

      if (percentIncrement != null) {
        currentPercent = _triggerEventHelper(currentPercent, percentIncrement);
      }

      await FiroCacheCoordinator.runFetchAndUpdateSparkUsedCoinTags(
        electrumXClient,
        cryptoCurrency.network,
      );

      if (percentIncrement != null) {
        currentPercent = _triggerEventHelper(currentPercent, percentIncrement);
      }

      // Get cached block hashes per groupId. These hashes are used to check
      // and try to id coins that were added to the spark anon set cache
      // after that block.
      final groupIdBlockHashMap =
          info.otherData[WalletInfoKeys.firoSparkCacheSetBlockHashCache]
              as Map? ??
          {};

      // iterate through the cache, fetching spark coin data that hasn't been
      // processed by this wallet yet
      final Map<int, List<List<String>>> rawCoinsBySetId = {};
      for (int i = 1; i <= latestGroupId; i++) {
        final lastCheckedHash = groupIdBlockHashMap[i.toString()] as String?;
        final info = await FiroCacheCoordinator.getLatestSetInfoForGroupId(
          i,
          cryptoCurrency.network,
        );
        final anonymitySetResult =
            await FiroCacheCoordinator.getSetCoinsForGroupId(
              i,
              afterBlockHash: lastCheckedHash,
              network: cryptoCurrency.network,
            );
        final coinsRaw = anonymitySetResult
            .map((e) => [e.serialized, e.txHash, e.context])
            .toList();

        if (coinsRaw.isNotEmpty) {
          rawCoinsBySetId[i] = coinsRaw;
        }

        // update last checked
        groupIdBlockHashMap[i.toString()] = info?.blockHash;
      }

      if (percentIncrement != null) {
        currentPercent = _triggerEventHelper(currentPercent, percentIncrement);
      }

      // try to identify any coins in the unchecked set data
      final List<SparkCoin> newlyIdCoins = [];
      for (final groupId in rawCoinsBySetId.keys) {
        newlyIdCoins.addAll(
          await identifyCoins(
            anonymitySetCoins: rawCoinsBySetId[groupId]!,
            groupId: groupId,
          ),
        );
      }
      // if any were found, add to database
      if (newlyIdCoins.isNotEmpty) {
        await mainDB.isar.writeTxn(() async {
          await mainDB.isar.sparkCoins.putAll(newlyIdCoins);
        });
      }

      // finally update the cached block hashes in the database
      await info.updateOtherData(
        newEntries: {
          WalletInfoKeys.firoSparkCacheSetBlockHashCache: groupIdBlockHashMap,
        },
        isar: mainDB.isar,
      );

      if (percentIncrement != null) {
        currentPercent = _triggerEventHelper(currentPercent, percentIncrement);
      }

      // check for spark coins in mempool
      final List<SparkCoin> mempoolMyCoins =
          await _refreshSparkCoinsMempoolCheck(groupId: latestGroupId);

      // if any were found, add to database
      if (mempoolMyCoins.isNotEmpty) {
        await mainDB.isar.writeTxn(() async {
          await mainDB.isar.sparkCoins.putAll(mempoolMyCoins);
        });
      }

      // get unused and or unconfirmed coins from db
      final coinsToCheck = await mainDB.isar.sparkCoins
          .where()
          .walletIdEqualToAnyLTagHash(walletId)
          .filter()
          .heightIsNull()
          .or()
          .isUsedEqualTo(false)
          .findAll();

      List<String>? spentCoinTags;
      // only fetch tags from db if we need them to compare against any items
      // in coinsToCheck
      if (coinsToCheck.isNotEmpty) {
        spentCoinTags = await FiroCacheCoordinator.getUsedCoinTags(
          0,
          cryptoCurrency.network,
        );
      }

      Logging.instance.d(
        "refreshSparkData() coinsToCheck.length: "
        "${coinsToCheck.length}",
      );

      // prepare data for next step
      final coinsToCheckTxids = coinsToCheck
          .where((e) => e.height == null)
          .map((e) => e.txHash)
          .toList(growable: false);

      final Map<String, Map<String, dynamic>> coinsToCheckTransactions = {};
      if (coinsToCheckTxids.isNotEmpty) {
        const batchSize = 100;
        final remainder = coinsToCheckTxids.length % batchSize;
        final batchCount = coinsToCheckTxids.length ~/ batchSize;

        for (int i = 0; i < batchCount; i++) {
          final start = i * batchSize;
          final end = start + batchSize;
          Logging.instance.i("[coinsToCheck]: Fetching batch #$i");
          final txns = await electrumXCachedClient.getBatchTransactions(
            txHashes: coinsToCheckTxids.sublist(start, end),
            cryptoCurrency: cryptoCurrency,
          );
          for (final tx in txns) {
            coinsToCheckTransactions[tx["txid"] as String] = tx;
          }
        }
        // handle remainder
        if (remainder > 0) {
          final txns = await electrumXCachedClient.getBatchTransactions(
            txHashes: coinsToCheckTxids.sublist(
              coinsToCheckTxids.length - remainder,
            ),
            cryptoCurrency: cryptoCurrency,
          );
          for (final tx in txns) {
            coinsToCheckTransactions[tx["txid"] as String] = tx;
          }
        }
      }

      // check and update coins if required
      final List<SparkCoin> checkedCoins = [];
      for (final coin in coinsToCheck) {
        final SparkCoin checked;

        if (coin.height == null) {
          final tx = coinsToCheckTransactions[coin.txHash]!;

          if (tx["height"] is int) {
            checked = coin.copyWith(
              height: tx["height"] as int,
              isUsed: spentCoinTags!.contains(coin.lTagHash),
            );
          } else {
            checked = coin;
          }
        } else {
          checked = spentCoinTags!.contains(coin.lTagHash)
              ? coin.copyWith(isUsed: true)
              : coin;
        }

        checkedCoins.add(checked);
      }
      // add/update in db
      if (checkedCoins.isNotEmpty) {
        await mainDB.isar.writeTxn(() async {
          await mainDB.isar.sparkCoins.putAll(checkedCoins);
        });
      }

      if (percentIncrement != null) {
        currentPercent = _triggerEventHelper(currentPercent, percentIncrement);
      }

      // used to check if balance is spendable or total
      final currentHeight = await chainHeight;

      // get all unused coins to update wallet spark balance
      final unusedCoins = await mainDB.isar.sparkCoins
          .where()
          .walletIdEqualToAnyLTagHash(walletId)
          .filter()
          .isUsedEqualTo(false)
          .findAll();

      final sparkNamesUpdateFuture = refreshSparkNames();

      final total = Amount(
        rawValue: unusedCoins
            .map((e) => e.value)
            .fold(BigInt.zero, (prev, e) => prev + e),
        fractionDigits: cryptoCurrency.fractionDigits,
      );
      final spendable = Amount(
        rawValue: unusedCoins
            .where(
              (e) => e.isConfirmed(currentHeight, cryptoCurrency.minConfirms),
            )
            .map((e) => e.value)
            .fold(BigInt.zero, (prev, e) => prev + e),
        fractionDigits: cryptoCurrency.fractionDigits,
      );

      final sparkBalance = Balance(
        total: total,
        spendable: spendable,
        blockedTotal: Amount(
          rawValue: BigInt.zero,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        pendingSpendable: total - spendable,
      );

      // finally update balance in db
      await info.updateBalanceTertiary(
        newBalance: sparkBalance,
        isar: mainDB.isar,
      );

      await sparkNamesUpdateFuture;
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType $walletId ${info.name}: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    } finally {
      Logging.instance.d(
        "${info.name} refreshSparkData() duration:"
        " ${DateTime.now().difference(start)}",
      );
    }
  }

  Future<Set<LTagPair>> getSparkSpendTransactionIds() async {
    final tags = await mainDB.isar.sparkCoins
        .where()
        .walletIdEqualToAnyLTagHash(walletId)
        .filter()
        .isUsedEqualTo(true)
        .lTagHashProperty()
        .findAll();

    final pairs = await FiroCacheCoordinator.getUsedCoinTxidsFor(
      tags: tags,
      network: cryptoCurrency.network,
    );

    return pairs.toSet();
  }

  /// Should only be called within the standard wallet [recover] function due to
  /// mutex locking. Otherwise behaviour MAY be undefined.
  Future<void> recoverSparkWallet({required int latestSparkCoinId}) async {
    try {
      await refreshSparkData(null);
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType $walletId ${info.name}: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<({String address, int validUntil, String additionalInfo})>
  getSparkNameData({required String sparkName}) async {
    return await electrumXClient.getSparkNameData(sparkName: sparkName);
  }

  Future<void> refreshSparkNames() async {
    try {
      Logging.instance.i("Refreshing spark names for $walletId ${info.name}");

      final db = Drift.get(walletId);
      final names = await electrumXClient.getSparkNames();

      // start update shared cache of all names
      final nameUpdateFuture = SparkNamesService.update(
        names,
        network: cryptoCurrency.network,
      );

      final myAddresses =
          (await mainDB.isar.addresses
                  .where()
                  .walletIdEqualTo(walletId)
                  .filter()
                  .typeEqualTo(AddressType.spark)
                  .and()
                  .subTypeEqualTo(AddressSubType.receiving)
                  .valueProperty()
                  .findAll())
              .toSet();

      // some look ahead
      // TODO revisit this and clean up (track pre gen'd addresses instead of
      //  generating every time) arbitrary number of addresses
      const lookAheadCount = 100;

      // force unwrap optional should be fine here. If not then the
      // eclosing function is being called somewhere it probably shouldn't be.
      int diversifier = _currentSparkAddress!.derivationIndex;
      final maxDiversifier = diversifier + lookAheadCount;

      while (diversifier < maxDiversifier) {
        // change address check
        if (diversifier == libSpark.sparkChange) {
          diversifier++;
        }
        final addressString = await _generateSparkAddress(diversifier);
        myAddresses.add(addressString.value);

        diversifier++;
      }

      names.retainWhere((e) => myAddresses.contains(e.address));
      Logging.instance.d("Found $names spark names");

      if (names.isNotEmpty) {
        final List<
          ({
            String name,
            String address,
            int validUntil,
            String? additionalInfo,
          })
        >
        data = [];

        for (final name in names) {
          final info = await getSparkNameData(sparkName: name.name);

          data.add((
            name: name.name,
            address: name.address,
            validUntil: info.validUntil,
            additionalInfo: info.additionalInfo,
          ));
        }

        await db.upsertSparkNames(data);
      }

      // finally ensure shared cache update has completed
      await nameUpdateFuture;
    } catch (e, s) {
      Logging.instance.e(
        "refreshing spark names for $walletId \"${info.name}\" failed",
        error: e,
        stackTrace: s,
      );
    }
  }

  // modelled on CSparkWallet::CreateSparkMintTransactions https://github.com/firoorg/firo/blob/39c41e5e7ec634ced3700fe3f4f5509dc2e480d0/src/spark/sparkwallet.cpp#L752
  Future<List<TxData>> _createSparkMintTransactions({
    required List<UTXO> availableUtxos,
    required List<MutableSparkRecipient> outputs,
    required bool subtractFeeFromAmount,
    required bool autoMintAll,
  }) async {
    if (isViewOnly) {
      throw Exception("Minting is not supported for view only wallets");
    }

    // pre checks
    if (outputs.isEmpty) {
      throw Exception("Cannot mint without some recipients");
    }

    // TODO remove when multiple recipients gui is added. Will need to handle
    // addresses when confirming the transactions later as well
    assert(outputs.length == 1);

    BigInt valueToMint = outputs
        .map((e) => e.value)
        .reduce((value, element) => value + element);

    if (valueToMint <= BigInt.zero) {
      throw Exception("Cannot mint amount=$valueToMint");
    }
    final totalUtxosValue = _sum(availableUtxos);
    if (valueToMint > totalUtxosValue) {
      throw Exception("Insufficient balance to create spark mint(s)");
    }

    // organise utxos
    final Map<String, List<UTXO>> utxosByAddress = {};
    for (final utxo in availableUtxos) {
      utxosByAddress[utxo.address!] ??= [];
      utxosByAddress[utxo.address!]!.add(utxo);
    }
    final valueAndUTXOs = utxosByAddress.values.toList();

    // setup some vars
    int nChangePosInOut = -1;
    final int nChangePosRequest = nChangePosInOut;
    List<MutableSparkRecipient> outputs_ = outputs
        .map((e) => MutableSparkRecipient(e.address, e.value, e.memo))
        .toList(); // deep copy
    final feesObject = await fees;
    final minRelayFeeRatePerKB = BigInt.from(1000);
    final mintFeeRatePerKB = feesObject.medium < minRelayFeeRatePerKB
        ? minRelayFeeRatePerKB
        : feesObject.medium;
    final currentHeight = await chainHeight;
    final random = Random.secure();
    final List<TxData> results = [];

    final String? autoMintSparkAddress = autoMintAll
        ? (await getCurrentReceivingSparkAddress())?.value
        : null;
    if (autoMintAll && autoMintSparkAddress == null) {
      throw Exception("No current Spark receiving address found.");
    }

    // Cache signing keys lazily for selected inputs. This mirrors the subset
    // of addSigningKeys used by Firo Spark mints; Firo currently supports only
    // BIP44 transparent inputs, so caching from the wallet root is valid here.
    final root = await getRootHDNode();
    final Map<String, _SparkMintSigningKey> signingKeyCache = {};
    Future<_SparkMintSigningKey> getCachedSigningKey(String address) async {
      final existing = signingKeyCache[address];
      if (existing != null) {
        return existing;
      }

      final derivePathType = cryptoCurrency.addressType(address: address);
      final dbAddress = await mainDB.getAddress(walletId, address);
      if (dbAddress?.derivationPath == null) {
        throw Exception(
          "Signing key not found for address $address. "
          "Local db may be corrupt. Rescan wallet.",
        );
      }

      final key = root.derivePath(dbAddress!.derivationPath!.value);
      final cached = (derivePathType: derivePathType, key: key);
      signingKeyCache[address] = cached;
      return cached;
    }

    Address? cachedChangeAddress;
    Future<Address> getMintChangeAddress() async {
      cachedChangeAddress ??= await getCurrentChangeAddress();
      if (cachedChangeAddress == null) {
        throw Exception("No current change address found.");
      }
      return cachedChangeAddress!;
    }

    // Pre-fetch wallet-owned addresses for output ownership checks.
    final walletAddresses = await mainDB.isar.addresses
        .where()
        .walletIdEqualTo(walletId)
        .valueProperty()
        .findAll();
    final walletAddressSet = walletAddresses.toSet();

    valueAndUTXOs.shuffle(random);

    while (valueAndUTXOs.isNotEmpty) {
      final lockTime = random.nextInt(10) == 0
          ? max(0, currentHeight - random.nextInt(100))
          : currentHeight;
      const txVersion = 1;
      final List<StandardInput> vin = [];
      final List<(dynamic, int, String?)> vout = [];

      BigInt nFeeRet = BigInt.zero;

      final itr = valueAndUTXOs.first;
      BigInt valueToMintInTx = _sum(itr);

      if (!autoMintAll) {
        valueToMintInTx = _min(valueToMintInTx, valueToMint);
      }

      BigInt nValueToSelect, mintedValue;
      final List<StandardInput> setCoins = [];
      bool skipCoin = false;

      // Start with no fee and loop until there is enough fee
      while (true) {
        mintedValue = valueToMintInTx;

        if (subtractFeeFromAmount) {
          nValueToSelect = mintedValue;
        } else {
          nValueToSelect = mintedValue + nFeeRet;
        }

        // if not enough coins in this group then subtract fee from mint
        if (nValueToSelect > _sum(itr) && !subtractFeeFromAmount) {
          nValueToSelect = mintedValue;
          mintedValue -= nFeeRet;
        }

        // if (!MoneyRange(mintedValue) || mintedValue == 0) {
        if (mintedValue <= BigInt.zero) {
          valueAndUTXOs.remove(itr);
          skipCoin = true;
          break;
        }

        nChangePosInOut = nChangePosRequest;
        vin.clear();
        vout.clear();
        setCoins.clear();

        // deep copy
        final remainingOutputs = outputs_
            .map((e) => MutableSparkRecipient(e.address, e.value, e.memo))
            .toList();
        final List<MutableSparkRecipient> singleTxOutputs = [];

        if (autoMintAll) {
          singleTxOutputs.add(
            MutableSparkRecipient(autoMintSparkAddress!, mintedValue, ""),
          );
        } else {
          BigInt remainingMintValue = BigInt.parse(mintedValue.toString());

          while (remainingMintValue > BigInt.zero) {
            final singleMintValue = _min(
              remainingMintValue,
              remainingOutputs.first.value,
            );
            singleTxOutputs.add(
              MutableSparkRecipient(
                remainingOutputs.first.address,
                singleMintValue,
                remainingOutputs.first.memo,
              ),
            );

            // subtract minted amount from remaining value
            remainingMintValue -= singleMintValue;
            remainingOutputs.first.value -= singleMintValue;

            if (remainingOutputs.first.value == BigInt.zero) {
              remainingOutputs.remove(remainingOutputs.first);
            }
          }
        }

        if (subtractFeeFromAmount && nFeeRet > BigInt.zero) {
          var remainingFee = nFeeRet;
          var outputIndex = 0;
          while (singleTxOutputs.isNotEmpty && remainingFee > BigInt.zero) {
            if (outputIndex >= singleTxOutputs.length) {
              outputIndex = 0;
            }

            final outputsLeft = BigInt.from(
              singleTxOutputs.length - outputIndex,
            );
            var feeShare = remainingFee ~/ outputsLeft;
            if (remainingFee % outputsLeft != BigInt.zero) {
              feeShare += BigInt.one;
            }

            if (singleTxOutputs[outputIndex].value <= feeShare) {
              remainingFee -= singleTxOutputs[outputIndex].value;
              singleTxOutputs.removeAt(outputIndex);
              continue;
            }

            singleTxOutputs[outputIndex].value -= feeShare;
            remainingFee -= feeShare;
            ++outputIndex;
          }

          if (singleTxOutputs.isEmpty) {
            if (autoMintAll) {
              throw Exception(
                "UTXO value is too small to cover Spark mint fee",
              );
            }
            valueAndUTXOs.remove(itr);
            skipCoin = true;
            break;
          }
        }

        // Generate dummy mint coins to save time
        final dummyRecipients = libSpark.createSparkMintRecipients(
          outputs: singleTxOutputs
              .map(
                (e) =>
                    (sparkAddress: e.address, value: e.value.toInt(), memo: ""),
              )
              .toList(),
          serialContext: Uint8List(0),
          generate: false,
        );

        for (int i = 0; i < dummyRecipients.length; i++) {
          final recipient = dummyRecipients[i];
          if (recipient.amount < cryptoCurrency.dustLimit.raw.toInt()) {
            throw Exception("Output amount too small");
          }
          vout.add((
            recipient.scriptPubKey,
            recipient.amount,
            singleTxOutputs[i].address,
          ));
        }

        // Choose coins to use
        BigInt nValueIn = BigInt.zero;
        for (final utxo in itr) {
          if (nValueToSelect > nValueIn) {
            final cached = await getCachedSigningKey(utxo.address!);
            final input = StandardInput(
              utxo,
              derivePathType: cached.derivePathType,
            );
            input.key = cached.key;
            setCoins.add(input);
            nValueIn += BigInt.from(utxo.value);
          }
        }
        if (nValueIn < nValueToSelect) {
          throw Exception("Insufficient funds");
        }

        // priority stuff???

        final BigInt nChange = nValueIn - nValueToSelect;
        if (nChange > BigInt.zero) {
          if (nChange < cryptoCurrency.dustLimit.raw) {
            nChangePosInOut = -1;
            nFeeRet += nChange;
          } else {
            if (nChangePosInOut == -1) {
              nChangePosInOut = random.nextInt(vout.length + 1);
            } else if (nChangePosInOut > vout.length) {
              throw Exception("Change index out of range");
            }

            final changeAddress = await getMintChangeAddress();
            vout.insert(nChangePosInOut, (
              changeAddress.value,
              nChange.toInt(),
              null,
            ));
          }
        }

        // Build all outputs for dummy tx
        final dummyOutputs = <TxOutput>[];
        for (final out in vout) {
          final addressOrScript = out.$1;
          final value = out.$2;
          if (addressOrScript is Uint8List) {
            dummyOutputs.add(TxOutput(
              value: BigInt.from(value),
              scriptPubKey: addressOrScript,
            ));
          } else {
            dummyOutputs.add(TxOutput(
              value: BigInt.from(value),
              scriptPubKey: Addr.fromString(
                addressOrScript as String,
                _coinChain,
              ).scriptPubKey,
            ));
          }
        }

        // fill vin
        for (final sd in setCoins) {
          vin.add(sd);
        }

        // Build unsigned dummy tx with RawInput placeholders
        final dummyUnsignedInputs = setCoins.map((sd) {
          final txidBytes = Uint8List.fromList(
            hexDecode(sd.utxo.txid).reversed.toList(),
          );
          return RawInput(
            prevOut: Outpoint(txid: txidBytes, vout: sd.utxo.vout),
            sequence: 0xffffffff - 1,
          );
        }).toList();

        final dummyUnsignedTx = Tx(
          version: txVersion,
          inputs: dummyUnsignedInputs,
          outputs: dummyOutputs,
          locktime: lockTime,
        );

        // Sign each input for dummy tx
        final dummySignedInputs = <TxInput>[];
        for (var i = 0; i < setCoins.length; i++) {
          final sd = setCoins[i];
          final pubKey = sd.key!.publicKey.bytes;
          final pubKeyHash = hash160(pubKey);
          final sk = (sd.key! as DerivedSecretKey).secretKey;

          final Uint8List digest;
          if (sd.derivePathType == DerivePathType.bip84 ||
              sd.derivePathType == DerivePathType.bip49) {
            final prevScript = PayToPubKeyHash(pubKeyHash).compiled;
            digest = WitnessSigHasher().hash(
              dummyUnsignedTx,
              i,
              SigHashType.all,
              prevScript: prevScript,
              amount: BigInt.from(sd.utxo.value),
            );
          } else {
            final prevScript = _outputScriptForKey(
              pubKey,
              sd.derivePathType!,
            );
            digest = LegacySigHasher().hash(
              dummyUnsignedTx,
              i,
              SigHashType.all,
              prevScript: prevScript,
            );
          }

          final sig = EcdsaSig.sign(digest, sk.bytes);
          final inputSig = InputSig(
            derSig: sig.toDer(),
            hashType: SigHashType.all,
          );
          final txidBytes = Uint8List.fromList(
            hexDecode(sd.utxo.txid).reversed.toList(),
          );
          final outpoint = Outpoint(txid: txidBytes, vout: sd.utxo.vout);

          if (sd.derivePathType == DerivePathType.bip84 ||
              sd.derivePathType == DerivePathType.bip49) {
            dummySignedInputs.add(P2wpkhInput(
              prevOut: outpoint,
              inputSig: inputSig,
              publicKey: pubKey,
              sequence: 0xffffffff - 1,
            ));
          } else {
            dummySignedInputs.add(P2pkhInput(
              prevOut: outpoint,
              inputSig: inputSig,
              publicKey: pubKey,
              sequence: 0xffffffff - 1,
            ));
          }
        }

        final dummyTx = Tx(
          version: txVersion,
          inputs: dummySignedInputs,
          outputs: dummyOutputs,
          locktime: lockTime,
        );
        final dummyWeight = _txWeight(dummyTx);
        final nBytes = (dummyWeight / 4).ceil();

        if (dummyWeight > MAX_NEW_TX_WEIGHT) {
          throw Exception("Transaction too large");
        }

        // ECDSA DER signatures are not fixed-size. Even with low-S
        // normalization, the encoded signature length can vary across
        // signatures, so the dummy signed transaction used for fee estimation
        // can be smaller than the final signed transaction. Use a per-input
        // safety margin so fee estimation remains an upper bound for many-input
        // Spark mints.
        final nBytesBuffer = 10 + 4 * setCoins.length;
        final nFeeNeeded = BigInt.from(
          estimateTxFee(
            vSize: nBytes + nBytesBuffer,
            feeRatePerKB: mintFeeRatePerKB,
          ),
        );

        if (nFeeRet >= nFeeNeeded) {
          for (final usedCoin in setCoins) {
            itr.removeWhere((e) => e == usedCoin.utxo);
          }
          if (itr.isEmpty) {
            final preLength = valueAndUTXOs.length;
            valueAndUTXOs.remove(itr);
            assert(preLength - 1 == valueAndUTXOs.length);
          }

          // Generate real mint coins
          final serialContext = libSpark.serializeMintContext(
            inputs: setCoins.map((e) => (e.utxo.txid, e.utxo.vout)).toList(),
          );
          final recipients = libSpark.createSparkMintRecipients(
            outputs: singleTxOutputs
                .map(
                  (e) => (
                    sparkAddress: e.address,
                    memo: e.memo,
                    value: e.value.toInt(),
                  ),
                )
                .toList(),
            serialContext: serialContext,
            generate: true,
          );

          for (int i = 0; i < recipients.length; i++) {
            final recipient = recipients[i];
            final out = (
              recipient.scriptPubKey,
              recipient.amount,
              singleTxOutputs[i].address,
            );
            while (i < vout.length) {
              if (vout[i].$1 is Uint8List &&
                  (vout[i].$1 as Uint8List).isNotEmpty &&
                  (vout[i].$1 as Uint8List)[0] == OP_SPARKMINT) {
                vout[i] = out;
                break;
              }
              ++i;
            }
            ++i;
          }

          // deep copy
          outputs_ = remainingOutputs
              .map((e) => MutableSparkRecipient(e.address, e.value, e.memo))
              .toList();

          break; // Done, enough fee included.
        }

        // Include more fee and try again.
        nFeeRet = nFeeNeeded;
        continue;
      }

      if (skipCoin) {
        continue;
      }

      // temp tx data to show in gui while waiting for real data from server
      final List<InputV2> tempInputs = [];
      final List<OutputV2> tempOutputs = [];

      // Build outputs for signed tx
      final mintOutputs = <TxOutput>[];
      for (final input in vin) {
        final pubKey = input.key!.publicKey.bytes;
        final outputScript = _outputScriptForKey(
          pubKey,
          input.derivePathType!,
        );

        tempInputs.add(
          InputV2.isarCantDoRequiredInDefaultConstructor(
            scriptSigHex: outputScript.toHex,
            scriptSigAsm: null,
            sequence: 0xffffffff - 1,
            outpoint: OutpointV2.isarCantDoRequiredInDefaultConstructor(
              txid: input.utxo.txid,
              vout: input.utxo.vout,
            ),
            addresses: input.utxo.address == null ? [] : [input.utxo.address!],
            valueStringSats: input.utxo.value.toString(),
            witness: null,
            innerRedeemScriptAsm: null,
            coinbase: null,
            walletOwns: true,
          ),
        );
      }

      for (final output in vout) {
        final addressOrScript = output.$1;
        final value = output.$2;
        if (addressOrScript is Uint8List) {
          mintOutputs.add(TxOutput(
            value: BigInt.from(value),
            scriptPubKey: addressOrScript,
          ));
        } else {
          mintOutputs.add(TxOutput(
            value: BigInt.from(value),
            scriptPubKey: Addr.fromString(
              addressOrScript as String,
              _coinChain,
            ).scriptPubKey,
          ));
        }

        tempOutputs.add(
          OutputV2.isarCantDoRequiredInDefaultConstructor(
            scriptPubKeyHex: addressOrScript is Uint8List
                ? addressOrScript.toHex
                : "000000",
            valueStringSats: value.toString(),
            addresses: [
              if (addressOrScript is String) addressOrScript.toString(),
            ],
            walletOwns: walletAddressSet.contains(
              addressOrScript is Uint8List
                  ? output.$3!
                  : addressOrScript as String,
            ),
          ),
        );
      }

      // Build unsigned tx with RawInput placeholders
      final unsignedMintInputs = vin.map((input) {
        final txidBytes = Uint8List.fromList(
          hexDecode(input.utxo.txid).reversed.toList(),
        );
        return RawInput(
          prevOut: Outpoint(txid: txidBytes, vout: input.utxo.vout),
          sequence: 0xffffffff - 1,
        );
      }).toList();

      final unsignedMintTx = Tx(
        version: txVersion,
        inputs: unsignedMintInputs,
        outputs: mintOutputs,
        locktime: lockTime,
      );

      // Sign each input
      final Tx builtTx;
      try {
        final signedMintInputs = <TxInput>[];
        for (var i = 0; i < vin.length; i++) {
          final sd = vin[i];
          final pubKey = sd.key!.publicKey.bytes;
          final pubKeyHash = hash160(pubKey);
          final sk = (sd.key! as DerivedSecretKey).secretKey;

          final Uint8List digest;
          if (sd.derivePathType == DerivePathType.bip84 ||
              sd.derivePathType == DerivePathType.bip49) {
            final prevScript = PayToPubKeyHash(pubKeyHash).compiled;
            digest = WitnessSigHasher().hash(
              unsignedMintTx,
              i,
              SigHashType.all,
              prevScript: prevScript,
              amount: BigInt.from(sd.utxo.value),
            );
          } else {
            final prevScript = _outputScriptForKey(
              pubKey,
              sd.derivePathType!,
            );
            digest = LegacySigHasher().hash(
              unsignedMintTx,
              i,
              SigHashType.all,
              prevScript: prevScript,
            );
          }

          final sig = EcdsaSig.sign(digest, sk.bytes);
          final inputSig = InputSig(
            derSig: sig.toDer(),
            hashType: SigHashType.all,
          );
          final txidBytes = Uint8List.fromList(
            hexDecode(sd.utxo.txid).reversed.toList(),
          );
          final outpoint = Outpoint(txid: txidBytes, vout: sd.utxo.vout);

          if (sd.derivePathType == DerivePathType.bip84 ||
              sd.derivePathType == DerivePathType.bip49) {
            signedMintInputs.add(P2wpkhInput(
              prevOut: outpoint,
              inputSig: inputSig,
              publicKey: pubKey,
              sequence: 0xffffffff - 1,
            ));
          } else {
            signedMintInputs.add(P2pkhInput(
              prevOut: outpoint,
              inputSig: inputSig,
              publicKey: pubKey,
              sequence: 0xffffffff - 1,
            ));
          }
        }

        builtTx = Tx(
          version: txVersion,
          inputs: signedMintInputs,
          outputs: mintOutputs,
          locktime: lockTime,
        );
      } catch (e, s) {
        Logging.instance.e(
          "Caught exception while signing spark mint transaction: ",
          error: e,
          stackTrace: s,
        );
        rethrow;
      }
      final actualFee =
          vin
              .map((e) => BigInt.from(e.utxo.value))
              .fold(BigInt.zero, (p, e) => p + e) -
          vout.map((e) => BigInt.from(e.$2)).fold(BigInt.zero, (p, e) => p + e);
      if (actualFee != nFeeRet) {
        Logging.instance.e(
          "Spark mint fee accounting mismatch: "
          "expected=$nFeeRet, actual=$actualFee",
        );
        throw Exception("Spark mint fee accounting mismatch");
      }

      // TODO: see todo at top of this function
      assert(outputs.length == 1);

      final data = TxData(
        sparkRecipients: vout
            .where((e) => e.$1 is Uint8List) // ignore change
            .map(
              (e) => (
                // for display purposes on confirm tx screen.
                // See todos above
                address: outputs.first.address,

                memo: "",
                amount: Amount(
                  rawValue: BigInt.from(e.$2),
                  fractionDigits: cryptoCurrency.fractionDigits,
                ),
                isChange: false, // ok?
              ),
            )
            .toList(),
        vSize: (_txWeight(builtTx) / 4).ceil(),
        txid: builtTx.txid,
        raw: builtTx.toHex(),
        fee: Amount(
          rawValue: nFeeRet,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        usedUTXOs: vin,
        tempTx: TransactionV2(
          walletId: walletId,
          blockHash: null,
          hash: builtTx.txid,
          txid: builtTx.txid,
          timestamp: DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
          inputs: List.unmodifiable(tempInputs),
          outputs: List.unmodifiable(tempOutputs),
          type:
              tempOutputs.map((e) => e.walletOwns).fold(true, (p, e) => p &= e)
              ? TransactionType.sentToSelf
              : TransactionType.outgoing,
          subType: TransactionSubType.sparkMint,
          otherData: null,
          height: null,
          version: 3,
        ),
      );

      Logging.instance.i("nFeeRet=$nFeeRet, vSize=${data.vSize}");
      // Sanity check: with the fee rate clamped to at least 1 sat/vbyte, this
      // should only fire if fee accounting or size estimation regresses.
      if (nFeeRet.toInt() < data.vSize!) {
        Logging.instance.w(
          "Fee rate below 1 sat/byte minimum relay fee: "
          "fee=$nFeeRet sats, vSize=${data.vSize} bytes",
        );
        throw Exception("Fee rate below 1 sat/byte minimum relay fee");
      }

      results.add(data);

      if (nChangePosInOut >= 0) {
        final vOut = vout[nChangePosInOut];
        assert(vOut.$1 is String); // check to make sure is change address

        final out = UTXO(
          walletId: walletId,
          txid: data.txid!,
          vout: nChangePosInOut,
          value: vOut.$2,
          address: vOut.$1 as String,
          name: "Spark mint change",
          isBlocked: false,
          blockedReason: null,
          isCoinbase: false,
          blockHash: null,
          blockHeight: null,
          blockTime: null,
        );

        bool added = false;
        for (final utxos in valueAndUTXOs) {
          if (utxos.first.address == out.address) {
            utxos.add(out);
            added = true;
          }
        }

        if (!added) {
          valueAndUTXOs.add([out]);
        }
      }

      if (!autoMintAll) {
        valueToMint -= mintedValue;
        if (valueToMint == BigInt.zero) {
          break;
        }
      }
    }

    if (!autoMintAll && valueToMint > BigInt.zero) {
      // TODO: Is this a valid error message?
      throw Exception("Failed to mint expected amounts");
    }

    if (autoMintAll && results.isEmpty) {
      throw Exception("No Spark mint transactions were created");
    }

    return results;
  }

  Future<void> anonymizeAllSpark() async {
    if (isViewOnly) {
      throw Exception("Anonymizing is not supported for view only wallets");
    }

    try {
      const subtractFeeFromAmount = true; // must be true for mint all
      final currentHeight = await chainHeight;

      final spendableUtxos = await mainDB.isar.utxos
          .where()
          .walletIdEqualTo(walletId)
          .filter()
          .isBlockedEqualTo(false)
          .and()
          .group((q) => q.usedEqualTo(false).or().usedIsNull())
          .and()
          .valueGreaterThan(0)
          .findAll();

      spendableUtxos.removeWhere(
        (e) => !e.isConfirmed(
          currentHeight,
          cryptoCurrency.minConfirms,
          cryptoCurrency.minCoinbaseConfirms,
        ),
      );

      if (spendableUtxos.isEmpty) {
        throw Exception("No available UTXOs found to anonymize");
      }

      final mints = await _createSparkMintTransactions(
        subtractFeeFromAmount: subtractFeeFromAmount,
        autoMintAll: true,
        availableUtxos: spendableUtxos,
        outputs: [
          MutableSparkRecipient(
            (await getCurrentReceivingSparkAddress())!.value,
            spendableUtxos
                .map((e) => BigInt.from(e.value))
                .fold(BigInt.zero, (p, e) => p + e),
            "",
          ),
        ],
      );

      await confirmSparkMintTransactions(txData: TxData(sparkMints: mints));
    } catch (e, s) {
      Logging.instance.w(
        "Exception caught in anonymizeAllSpark(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Transparent to Spark (mint) transaction creation.
  ///
  /// See https://docs.google.com/document/d/1RG52GoYTZDvKlZz_3G4sQu-PpT6JWSZGHLNswWcrE3o
  Future<TxData> prepareSparkMintTransaction({required TxData txData}) async {
    if (isViewOnly) {
      throw Exception("Minting is not supported for view only wallets");
    }

    try {
      if (txData.sparkRecipients?.isNotEmpty != true) {
        throw Exception("Missing spark recipients.");
      }
      final recipients = txData.sparkRecipients!
          .map((e) => MutableSparkRecipient(e.address, e.amount.raw, e.memo))
          .toList();

      final total = recipients
          .map((e) => e.value)
          .reduce((value, element) => value += element);

      if (total < BigInt.zero) {
        throw Exception("Attempted send of negative amount");
      } else if (total == BigInt.zero) {
        throw Exception("Attempted send of zero amount");
      }

      final utxos = txData.utxos
          ?.whereType<StandardInput>()
          .map((e) => e.utxo)
          .toList();
      final bool coinControl = utxos != null;

      final utxosTotal = coinControl
          ? utxos
                .map((e) => e.value)
                .fold(BigInt.zero, (p, e) => p + BigInt.from(e))
          : null;

      if (coinControl && utxosTotal! < total) {
        throw Exception("Insufficient selected UTXOs!");
      }

      final isSendAllCoinControlUtxos = coinControl && total == utxosTotal;

      final currentHeight = await chainHeight;

      final availableOutputs =
          utxos?.toList() ??
          await mainDB.isar.utxos
              .where()
              .walletIdEqualTo(walletId)
              .filter()
              .isBlockedEqualTo(false)
              .and()
              .group((q) => q.usedEqualTo(false).or().usedIsNull())
              .and()
              .valueGreaterThan(0)
              .findAll();

      final canCPFP = this is CpfpInterface && coinControl;

      final spendableUtxos = availableOutputs
          .where(
            (e) =>
                canCPFP ||
                e.isConfirmed(
                  currentHeight,
                  cryptoCurrency.minConfirms,
                  cryptoCurrency.minCoinbaseConfirms,
                ),
          )
          .toList();

      if (spendableUtxos.isEmpty) {
        throw Exception("No available UTXOs found to anonymize");
      }

      final available = spendableUtxos
          .map((e) => BigInt.from(e.value))
          .reduce((value, element) => value += element);

      final bool subtractFeeFromAmount;
      if (isSendAllCoinControlUtxos) {
        subtractFeeFromAmount = true;
      } else if (available < total) {
        throw Exception("Insufficient balance");
      } else if (available == total) {
        subtractFeeFromAmount = true;
      } else {
        subtractFeeFromAmount = false;
      }

      final mints = await _createSparkMintTransactions(
        subtractFeeFromAmount: subtractFeeFromAmount,
        autoMintAll: false,
        availableUtxos: spendableUtxos,
        outputs: recipients,
      );

      return txData.copyWith(sparkMints: mints);
    } catch (e, s) {
      Logging.instance.w(
        "Exception caught in prepareSparkMintTransaction(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<TxData> confirmSparkMintTransactions({required TxData txData}) async {
    if (isViewOnly) {
      throw Exception("Minting is not supported for view only wallets");
    }

    final futures = txData.sparkMints!.map((e) => confirmSend(txData: e));
    return txData.copyWith(sparkMints: await Future.wait(futures));
  }

  Future<TxData> prepareSparkNameTransaction({
    required String name,
    required String address,
    required int years,
    required String additionalInfo,
  }) async {
    // TODO remove after block 1104500
    if (cryptoCurrency.network == CryptoCurrencyNetwork.main) {
      final height = await fetchChainHeight();
      if (height < 1104500) {
        throw Exception("Spark names not enabled on main net yet");
      }
    }

    if (years < 1 || years > libSpark.maxNameRegistrationLengthYears) {
      throw Exception("Invalid spark name registration period years: $years");
    }

    if (name.isEmpty || name.length > libSpark.maxNameLength) {
      throw Exception("Invalid spark name length: ${name.length}");
    }
    if (!RegExp(libSpark.nameRegexString).hasMatch(name)) {
      throw Exception("Invalid symbols found in spark name: $name");
    }

    if (additionalInfo.toUint8ListFromUtf8.length >
        libSpark.maxAdditionalInfoLengthBytes) {
      throw Exception(
        "Additional info exceeds "
        "${libSpark.maxAdditionalInfoLengthBytes}"
        " bytes.",
      );
    }

    final sparkAddress = await mainDB.getAddress(walletId, address);
    if (sparkAddress == null) {
      throw Exception("Address '$address' not found in local DB.");
    }
    if (sparkAddress.type != AddressType.spark) {
      throw Exception("Address '$address' is not a spark address.");
    }

    final data = (
      name: name,
      additionalInfo: additionalInfo,
      validBlocks: years * 365 * 24 * 24,
      sparkAddress: sparkAddress,
    );

    final String destinationAddress;
    switch (cryptoCurrency.network) {
      case CryptoCurrencyNetwork.main:
        destinationAddress = libSpark.stage3CommunityFundAddressMainNet;
        break;

      case CryptoCurrencyNetwork.test:
        destinationAddress = libSpark.stage3CommunityFundAddressTestNet;
        break;

      default:
        throw Exception(
          "Invalid network "
          "'${cryptoCurrency.network}'"
          " for spark name registration.",
        );
    }

    final txData = await prepareSendSpark(
      txData: TxData(
        sparkNameInfo: data,
        recipients: [
          TxRecipient(
            address: destinationAddress,
            amount: Amount.fromDecimal(
              Decimal.fromInt(
                libSpark.standardSparkNamesFee[name.length] * years,
              ),
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            isChange: false,
            addressType: cryptoCurrency.getAddressType(destinationAddress)!,
          ),
        ],
      ),
    );

    return txData;
  }

  @override
  Future<void> updateBalance() async {
    // call to super to update transparent balance
    final normalBalanceFuture = super.updateBalance();

    // todo: spark balance aka update info.tertiaryBalance here?
    // currently happens on spark coins update/refresh

    // wait for normalBalanceFuture to complete before returning
    await normalBalanceFuture;
  }

  // ====================== Private ============================================

  Chain get _coinChain => Chain(
    wifPrefix: cryptoCurrency.networkParams.wifPrefix,
    p2pkhPrefix: cryptoCurrency.networkParams.p2pkhPrefix,
    p2shPrefix: cryptoCurrency.networkParams.p2shPrefix,
    bech32Hrp: cryptoCurrency.networkParams.bech32Hrp,
    privHDPrefix: cryptoCurrency.networkParams.privHDPrefix,
    pubHDPrefix: cryptoCurrency.networkParams.pubHDPrefix,
    name: '',
    bip44CoinType: 0,
    supportsSegwit: true,
    supportsTaproot: false,
  );

  /// Compute the segwit weight of a coin Tx.
  /// weight = base_size * 3 + total_size
  /// where base_size excludes witness data and total_size includes it.
  static int _txWeight(Tx tx) {
    final totalSize = tx.wireSize;
    // Compute non-witness size by re-serializing without witness
    // Non-witness = version(4) + varint(inputs) + inputs + varint(outputs) +
    //   outputs + locktime(4)
    var baseSize = 8; // version + locktime
    baseSize += _varIntSize(tx.inputs.length);
    for (final inp in tx.inputs) {
      // prevOut(32+4) + scriptSig + sequence(4)
      baseSize += 32 + 4 + _varSliceSize(inp.scriptSig) + 4;
    }
    baseSize += _varIntSize(tx.outputs.length);
    for (final out in tx.outputs) {
      // value(8) + scriptPubKey
      baseSize += 8 + _varSliceSize(out.scriptPubKey);
    }
    return baseSize * 3 + totalSize;
  }

  static int _varIntSize(int i) {
    if (i < 0xfd) return 1;
    if (i <= 0xffff) return 3;
    if (i <= 0xffffffff) return 5;
    return 9;
  }

  static int _varSliceSize(Uint8List slice) =>
      _varIntSize(slice.length) + slice.length;

  Uint8List _outputScriptForKey(
    Uint8List pubKey,
    DerivePathType derivePathType,
  ) {
    final pubKeyHash = hash160(pubKey);
    switch (derivePathType) {
      case DerivePathType.bip44:
        return PayToPubKeyHash(pubKeyHash).compiled;
      case DerivePathType.bip84:
        return PayToWitnessPubKey(pubKeyHash).compiled;
      case DerivePathType.bip49:
        final p2wpkhScript = PayToWitnessPubKey(pubKeyHash).compiled;
        return PayToScriptHash(hash160(p2wpkhScript)).compiled;
      default:
        throw Exception("DerivePathType unsupported");
    }
  }
}

/// Top level function which should be called wrapped in [compute]
Future<
  ({
    Uint8List serializedSpendPayload,
    List<Uint8List> outputScripts,
    int fee,
    List<
      ({
        int groupId,
        int height,
        String serializedCoin,
        String serializedCoinContext,
      })
    >
    usedCoins,
  })
>
_createSparkSend(
  ({
    String privateKeyHex,
    int index,
    List<({String address, int amount, bool subtractFeeFromAmount})> recipients,
    List<
      ({
        String sparkAddress,
        int amount,
        bool subtractFeeFromAmount,
        String memo,
      })
    >
    privateRecipients,
    List<
      ({
        String serializedCoin,
        String serializedCoinContext,
        int groupId,
        int height,
      })
    >
    serializedCoins,
    List<
      ({
        int setId,
        String setHash,
        List<({String serializedCoin, String txHash})> set,
      })
    >
    allAnonymitySets,
    List<({int setId, Uint8List blockHash})> idAndBlockHashes,
    Uint8List txHash,
    int additionalTxSize,
  })
  args,
) async {
  final spend = libSpark.createSparkSendTransaction(
    privateKeyHex: args.privateKeyHex,
    index: args.index,
    recipients: args.recipients,
    privateRecipients: args.privateRecipients,
    serializedCoins: args.serializedCoins,
    allAnonymitySets: args.allAnonymitySets,
    idAndBlockHashes: args.idAndBlockHashes,
    txHash: args.txHash,
    additionalTxSize: args.additionalTxSize,
  );

  return spend;
}

BigInt _min(BigInt a, BigInt b) {
  if (a <= b) {
    return a;
  } else {
    return b;
  }
}

BigInt _sum(List<UTXO> utxos) => utxos
    .map((e) => BigInt.from(e.value))
    .fold(BigInt.zero, (previousValue, element) => previousValue + element);

typedef _SparkMintSigningKey = ({
  DerivePathType derivePathType,
  DerivedKey key,
});

class MutableSparkRecipient {
  String address;
  BigInt value;
  String memo;

  MutableSparkRecipient(this.address, this.value, this.memo);

  @override
  String toString() {
    return 'MutableSparkRecipient{ '
        'address: $address, '
        'value: $value,'
        ' memo: $memo'
        ' }';
  }
}

typedef SerializedCoinData = ({
  int groupId,
  int height,
  String serializedCoin,
  String serializedCoinContext,
});

Future<int> _asyncSparkFeesWrapper({
  required String privateKeyHex,
  int index = 1,
  required int sendAmount,
  required bool subtractFeeFromAmount,
  required List<SerializedCoinData> serializedCoins,
  required int privateRecipientsCount,
  required int utxoNum,
  required int additionalTxSize,
}) async {
  return await computeWithLibSparkLogging(_estSparkFeeComputeFunc, (
    privateKeyHex: privateKeyHex,
    index: index,
    sendAmount: sendAmount,
    subtractFeeFromAmount: subtractFeeFromAmount,
    serializedCoins: serializedCoins,
    privateRecipientsCount: privateRecipientsCount,
    utxoNum: utxoNum,
    additionalTxSize: additionalTxSize,
  ));
}

int _estSparkFeeComputeFunc(
  ({
    String privateKeyHex,
    int index,
    int sendAmount,
    bool subtractFeeFromAmount,
    List<SerializedCoinData> serializedCoins,
    int privateRecipientsCount,
    int utxoNum,
    int additionalTxSize,
  })
  args,
) {
  final est = libSpark.estimateSparkFee(
    privateKeyHex: args.privateKeyHex,
    index: args.index,
    sendAmount: args.sendAmount,
    subtractFeeFromAmount: args.subtractFeeFromAmount,
    serializedCoins: args.serializedCoins,
    privateRecipientsCount: args.privateRecipientsCount,
    utxoNum: args.utxoNum,
    additionalTxSize: args.additionalTxSize,
  );

  return est;
}

Future<String> _getAddressFromFullViewKey(
  ({String fullViewKeyHex, int index, int diversifier, bool isTestNet}) args,
) => libSpark.getAddressFromFullViewKey(
  fullViewKeyHex: args.fullViewKeyHex,
  index: args.index,
  diversifier: args.diversifier,
  isTestNet: args.isTestNet,
);

/// Minimal mutable raw transaction class for Firo/Spark protocol operations.
///
/// Replaces the bitcoindart Transaction object that was returned by
/// TransactionBuilder.buildIncomplete(). Supports the Firo-specific
/// payload field and mutable addInput/addOutput operations needed by
/// the Spark spend protocol.
class _FiroRawTx {
  int version;
  int locktime;
  final List<_FiroRawInput> ins = [];
  final List<_FiroRawOutput> outs = [];
  Uint8List? payload;

  _FiroRawTx({required this.version, required this.locktime});

  void addInput(
    Uint8List hash,
    int index, [
    int sequence = 0xffffffff,
    Uint8List? scriptSig,
  ]) {
    ins.add(_FiroRawInput(
      hash: hash,
      index: index,
      sequence: sequence,
      script: scriptSig ?? Uint8List(0),
    ));
  }

  void addOutput(Uint8List scriptPubKey, int value) {
    outs.add(_FiroRawOutput(script: scriptPubKey, value: value));
  }

  void setPayload(Uint8List data) {
    payload = data;
  }

  Uint8List _toBuffer({bool allowWitness = true}) {
    final hasWitness = allowWitness && _hasWitnesses();
    final size = _byteLength(allowWitness);
    final buffer = Uint8List(size);
    final bd = buffer.buffer.asByteData();
    var offset = 0;

    void writeSlice(Uint8List slice) {
      buffer.setRange(offset, offset + slice.length, slice);
      offset += slice.length;
    }

    void writeUInt8(int i) {
      bd.setUint8(offset, i);
      offset++;
    }

    void writeUInt32(int i) {
      bd.setUint32(offset, i, Endian.little);
      offset += 4;
    }

    void writeInt32(int i) {
      bd.setInt32(offset, i, Endian.little);
      offset += 4;
    }

    void writeUInt64(int i) {
      bd.setUint64(offset, i, Endian.little);
      offset += 8;
    }

    void writeVarInt(int i) {
      if (i < 0xfd) {
        writeUInt8(i);
      } else if (i <= 0xffff) {
        writeUInt8(0xfd);
        bd.setUint16(offset, i, Endian.little);
        offset += 2;
      } else if (i <= 0xffffffff) {
        writeUInt8(0xfe);
        writeUInt32(i);
      } else {
        writeUInt8(0xff);
        writeUInt64(i);
      }
    }

    void writeVarSlice(Uint8List slice) {
      writeVarInt(slice.length);
      writeSlice(slice);
    }

    void writeVector(List<Uint8List> vector) {
      writeVarInt(vector.length);
      for (final buf in vector) {
        writeVarSlice(buf);
      }
    }

    writeInt32(version);

    if (hasWitness) {
      writeUInt8(0x00); // marker
      writeUInt8(0x01); // flag
    }

    writeVarInt(ins.length);
    for (final txIn in ins) {
      writeSlice(txIn.hash);
      writeUInt32(txIn.index);
      writeVarSlice(txIn.script);
      writeUInt32(txIn.sequence);
    }

    writeVarInt(outs.length);
    for (final txOut in outs) {
      writeUInt64(txOut.value);
      writeVarSlice(txOut.script);
    }

    if (hasWitness) {
      for (final txIn in ins) {
        writeVector(txIn.witness);
      }
    }

    writeUInt32(locktime);

    if (payload != null) {
      writeVarSlice(payload!);
    }

    return buffer;
  }

  bool _hasWitnesses() => ins.any((i) => i.witness.isNotEmpty);

  int _byteLength(bool allowWitness) {
    final hasWitness = allowWitness && _hasWitnesses();
    var size = 8 + // version(4) + locktime(4)
        (hasWitness ? 2 : 0) + // marker + flag
        _varIntSize(ins.length) +
        _varIntSize(outs.length);

    for (final txIn in ins) {
      size += 40 + _varSliceSize(txIn.script);
    }
    for (final txOut in outs) {
      size += 8 + _varSliceSize(txOut.script);
    }
    if (payload != null) {
      size += _varSliceSize(payload!);
    }
    if (hasWitness) {
      for (final txIn in ins) {
        size += _vectorSize(txIn.witness);
      }
    }
    return size;
  }

  static int _varIntSize(int i) {
    if (i < 0xfd) return 1;
    if (i <= 0xffff) return 3;
    if (i <= 0xffffffff) return 5;
    return 9;
  }

  static int _varSliceSize(Uint8List slice) =>
      _varIntSize(slice.length) + slice.length;

  static int _vectorSize(List<Uint8List> vector) {
    var size = _varIntSize(vector.length);
    for (final buf in vector) {
      size += _varSliceSize(buf);
    }
    return size;
  }

  Uint8List getHash() {
    final data = _toBuffer(allowWitness: false);
    return sha256d(data);
  }

  String getId() {
    return hexEncode(Uint8List.fromList(getHash().reversed.toList()));
  }

  String toHex() {
    return hexEncode(_toBuffer());
  }

  int weight() {
    final base = _byteLength(false);
    final total = _byteLength(true);
    return base * 3 + total;
  }

  int virtualSize() {
    return (weight() / 4).ceil();
  }
}

class _FiroRawInput {
  final Uint8List hash;
  final int index;
  final int sequence;
  final Uint8List script;
  final List<Uint8List> witness;

  _FiroRawInput({
    required this.hash,
    required this.index,
    required this.sequence,
    required this.script,
    List<Uint8List>? witness,
  }) : witness = witness ?? [];
}

class _FiroRawOutput {
  final Uint8List script;
  final int value;

  _FiroRawOutput({required this.script, required this.value});
}
