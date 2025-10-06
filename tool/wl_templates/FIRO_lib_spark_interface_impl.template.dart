//ON
import 'dart:typed_data';

import 'package:flutter_libsparkmobile/flutter_libsparkmobile.dart';
import 'package:logger/logger.dart';

import '../../utilities/logger.dart';
//END_ON
import '../interfaces/lib_spark_interface.dart';

LibSparkInterface get libSpark => _getInterface();

//OFF
LibSparkInterface _getInterface() => throw Exception("FIRO not enabled!");

List<String> hashTags({required List<String> base64Tags}) =>
    throw Exception("FIRO not enabled!");

//END_OFF
//ON
LibSparkInterface _getInterface() => _LibSparkInterfaceImpl();

List<String> hashTags({required List<String> base64Tags}) =>
    LibSpark.hashTags(base64Tags: base64Tags);

class _LibSparkInterfaceImpl extends LibSparkInterface {
  @override
  String get sparkBaseDerivationPath => kSparkBaseDerivationPath;

  @override
  String get sparkBaseDerivationPathTestnet => kSparkBaseDerivationPathTestnet;

  @override
  int get sparkChange => kSparkChange;

  @override
  int get maxAdditionalInfoLengthBytes => kMaxAdditionalInfoLengthBytes;

  @override
  int get maxNameLength => kMaxNameLength;

  @override
  int get maxNameRegistrationLengthYears => kMaxNameRegistrationLengthYears;

  @override
  String get nameRegexString => kNameRegexString;

  @override
  String get stage3DevelopmentFundAddressMainNet =>
      kStage3DevelopmentFundAddressMainNet;

  @override
  String get stage3DevelopmentFundAddressTestNet =>
      kStage3DevelopmentFundAddressTestNet;

  @override
  List<int> get standardSparkNamesFee =>
      List.unmodifiable(kStandardSparkNamesFee);

  @override
  void initSparkLogging(Level level) {
    final levels = Level.values.where((e) => e >= level).map((e) => e.name);
    Log.levels.addAll(
      LoggingLevel.values.where((e) => levels.contains(e.name)),
    );
    Log.onLog = (level, value, {error, stackTrace, required time}) {
      Logging.instance.log(
        level.getLoggerLevel(),
        value,
        error: error,
        stackTrace: stackTrace,
        time: time,
      );
    };
  }

  @override
  String hashTag(String x, String y) => LibSpark.hashTag(x, y);

  @override
  bool validateAddress({required String address, required bool isTestNet}) =>
      LibSpark.validateAddress(address: address, isTestNet: isTestNet);

  @override
  Future<String> getAddress({
    required Uint8List privateKey,
    required int index,
    required int diversifier,
    bool isTestNet = false,
  }) => LibSpark.getAddress(
    privateKey: privateKey,
    index: index,
    diversifier: diversifier,
    isTestNet: isTestNet,
  );

  @override
  ({Uint8List script, int size}) createSparkNameScript({
    required int sparkNameValidityBlocks,
    required String name,
    required String additionalInfo,
    required String scalarHex,
    required String privateKeyHex,
    required int spendKeyIndex,
    required int diversifier,
    required bool isTestNet,
    required int hashFailSafe,
    required bool ignoreProof,
  }) => LibSpark.createSparkNameScript(
    sparkNameValidityBlocks: sparkNameValidityBlocks,
    name: name,
    additionalInfo: additionalInfo,
    scalarHex: scalarHex,
    privateKeyHex: privateKeyHex,
    spendKeyIndex: spendKeyIndex,
    diversifier: diversifier,
    isTestNet: isTestNet,
    hashFailSafe: hashFailSafe,
    ignoreProof: ignoreProof,
  );

  @override
  List<({int amount, Uint8List scriptPubKey, bool subtractFeeFromAmount})>
  createSparkMintRecipients({
    required List<({String memo, String sparkAddress, int value})> outputs,
    required Uint8List serialContext,
    bool generate = false,
  }) => LibSpark.createSparkMintRecipients(
    outputs: outputs,
    serialContext: serialContext,
    generate: generate,
  );

  @override
  Uint8List serializeMintContext({required List<(String, int)> inputs}) =>
      LibSpark.serializeMintContext(inputs: inputs);

  @override
  WrappedLibSparkCoin? identifyAndRecoverCoin(
    String serializedCoin, {
    required String privateKeyHex,
    required int index,
    required Uint8List context,
    bool isTestNet = false,
  }) {
    final coin = LibSpark.identifyAndRecoverCoin(
      serializedCoin,
      privateKeyHex: privateKeyHex,
      index: index,
      context: context,
      isTestNet: isTestNet,
    );

    if (coin == null) return null;

    return WrappedLibSparkCoin(
      type: WrappedLibSparkCoinType.values.firstWhere(
        (e) => e.value == coin.type.value,
      ),

      id: coin.id,
      height: coin.height,
      isUsed: coin.isUsed,
      nonceHex: coin.nonceHex,
      address: coin.address,
      value: coin.value,
      serial: coin.serial,
      memo: coin.memo,
      txHash: coin.txHash,
      serialContext: coin.serialContext,
      diversifier: coin.diversifier,
      encryptedDiversifier: coin.encryptedDiversifier,
      tag: coin.tag,
      lTagHash: coin.lTagHash,
      serializedCoin: coin.serializedCoin,
    );
  }

  @override
  ({
    int fee,
    List<Uint8List> outputScripts,
    Uint8List serializedSpendPayload,
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
  createSparkSendTransaction({
    required String privateKeyHex,
    int index = 1,
    required List<({String address, int amount, bool subtractFeeFromAmount})>
    recipients,
    required List<
      ({
        int amount,
        String memo,
        String sparkAddress,
        bool subtractFeeFromAmount,
      })
    >
    privateRecipients,
    required List<
      ({
        int groupId,
        int height,
        String serializedCoin,
        String serializedCoinContext,
      })
    >
    serializedCoins,
    required List<
      ({
        List<({String serializedCoin, String txHash})> set,
        String setHash,
        int setId,
      })
    >
    allAnonymitySets,
    required List<({Uint8List blockHash, int setId})> idAndBlockHashes,
    required Uint8List txHash,
    required int additionalTxSize,
  }) => LibSpark.createSparkSendTransaction(
    index: index,
    privateKeyHex: privateKeyHex,
    recipients: recipients,
    privateRecipients: privateRecipients,
    serializedCoins: serializedCoins,
    allAnonymitySets: allAnonymitySets,
    idAndBlockHashes: idAndBlockHashes,
    txHash: txHash,
    additionalTxSize: additionalTxSize,
  );

  @override
  int estimateSparkFee({
    required String privateKeyHex,
    int index = 1,
    required int sendAmount,
    required bool subtractFeeFromAmount,
    required List<
      ({
        int groupId,
        int height,
        String serializedCoin,
        String serializedCoinContext,
      })
    >
    serializedCoins,
    required int privateRecipientsCount,
    required int utxoNum,
    required int additionalTxSize,
  }) => LibSpark.estimateSparkFee(
    privateKeyHex: privateKeyHex,
    sendAmount: sendAmount,
    subtractFeeFromAmount: subtractFeeFromAmount,
    serializedCoins: serializedCoins,
    privateRecipientsCount: privateRecipientsCount,
    utxoNum: utxoNum,
    additionalTxSize: additionalTxSize,
    index: index,
  );
}

// convenience conversion for spark
extension _LoggingLevelExt on LoggingLevel {
  Level getLoggerLevel() {
    switch (this) {
      case LoggingLevel.info:
        return Level.info;
      case LoggingLevel.warning:
        return Level.warning;
      case LoggingLevel.error:
        return Level.error;
      case LoggingLevel.fatal:
        return Level.fatal;
      case LoggingLevel.debug:
        return Level.debug;
      case LoggingLevel.trace:
        return Level.trace;
    }
  }
}

//END_ON
