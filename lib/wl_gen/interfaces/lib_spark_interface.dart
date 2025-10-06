import 'dart:typed_data';

import 'package:logger/logger.dart';

export '../generated/lib_spark_interface_impl.dart';

abstract class LibSparkInterface {
  const LibSparkInterface();

  String get sparkBaseDerivationPath;
  String get sparkBaseDerivationPathTestnet;
  int get sparkChange;
  int get maxNameRegistrationLengthYears;
  int get maxNameLength;
  int get maxAdditionalInfoLengthBytes;
  String get nameRegexString;
  String get stage3DevelopmentFundAddressMainNet;
  String get stage3DevelopmentFundAddressTestNet;
  List<int> get standardSparkNamesFee;

  void initSparkLogging(Level level);

  String hashTag(String x, String y);

  bool validateAddress({required String address, required bool isTestNet});

  Future<String> getAddress({
    required Uint8List privateKey,
    required int index,
    required int diversifier,
    bool isTestNet = false,
  });

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
  });

  List<({Uint8List scriptPubKey, int amount, bool subtractFeeFromAmount})>
  createSparkMintRecipients({
    required List<({String sparkAddress, int value, String memo})> outputs,
    required Uint8List serialContext,
    bool generate = false,
  });

  Uint8List serializeMintContext({required List<(String, int)> inputs});

  WrappedLibSparkCoin? identifyAndRecoverCoin(
    final String serializedCoin, {
    required final String privateKeyHex,
    required final int index,
    required final Uint8List context,
    final bool isTestNet = false,
  });

  ({
    Uint8List serializedSpendPayload,
    List<Uint8List> outputScripts,
    int fee,
    List<
      ({
        String serializedCoin,
        String serializedCoinContext,
        int groupId,
        int height,
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
        String sparkAddress,
        int amount,
        bool subtractFeeFromAmount,
        String memo,
      })
    >
    privateRecipients,
    required List<
      ({
        String serializedCoin,
        String serializedCoinContext,
        int groupId,
        int height,
      })
    >
    serializedCoins,
    required List<
      ({
        int setId,
        String setHash,
        List<({String serializedCoin, String txHash})> set,
      })
    >
    allAnonymitySets,
    required List<({int setId, Uint8List blockHash})> idAndBlockHashes,
    required Uint8List txHash,
    required int additionalTxSize,
  });

  int estimateSparkFee({
    required String privateKeyHex,
    int index = 1,
    required int sendAmount,
    required bool subtractFeeFromAmount,
    required List<
      ({
        String serializedCoin,
        String serializedCoinContext,
        int groupId,
        int height,
      })
    >
    serializedCoins,
    required int privateRecipientsCount,
    required int utxoNum,
    required int additionalTxSize,
  });
}

// stupid
enum WrappedLibSparkCoinType {
  mint(0),
  spend(1);

  const WrappedLibSparkCoinType(this.value);
  final int value;
}

// stupid
final class WrappedLibSparkCoin {
  final WrappedLibSparkCoinType type;

  final int? id;
  final int? height;

  final bool? isUsed;

  final String? nonceHex;

  final String? address;

  final BigInt? value;

  final String? memo;

  final Uint8List? txHash;

  final Uint8List? serialContext;

  final BigInt? diversifier;
  final Uint8List? encryptedDiversifier;

  final Uint8List? serial;
  final Uint8List? tag;

  final String? lTagHash;

  final String? serializedCoin;

  WrappedLibSparkCoin({
    required this.type,
    this.id,
    this.height,
    this.isUsed,
    this.nonceHex,
    this.address,
    this.value,
    this.memo,
    this.txHash,
    this.serialContext,
    this.diversifier,
    this.encryptedDiversifier,
    this.serial,
    this.tag,
    this.lTagHash,
    this.serializedCoin,
  });

  WrappedLibSparkCoin copyWith({
    WrappedLibSparkCoinType? type,
    int? id,
    int? height,
    bool? isUsed,
    String? nonceHex,
    String? address,
    BigInt? value,
    String? memo,
    Uint8List? txHash,
    Uint8List? serialContext,
    BigInt? diversifier,
    Uint8List? encryptedDiversifier,
    Uint8List? serial,
    Uint8List? tag,
    String? lTagHash,
    String? serializedCoin,
  }) {
    return WrappedLibSparkCoin(
      type: type ?? this.type,
      id: id ?? this.id,
      height: height ?? this.height,
      isUsed: isUsed ?? this.isUsed,
      nonceHex: nonceHex ?? this.nonceHex,
      address: address ?? this.address,
      value: value ?? this.value,
      memo: memo ?? this.memo,
      txHash: txHash ?? this.txHash,
      serialContext: serialContext ?? this.serialContext,
      diversifier: diversifier ?? this.diversifier,
      encryptedDiversifier: encryptedDiversifier ?? this.encryptedDiversifier,
      serial: serial ?? this.serial,
      tag: tag ?? this.tag,
      lTagHash: lTagHash ?? this.lTagHash,
      serializedCoin: serializedCoin ?? this.serializedCoin,
    );
  }

  @override
  String toString() {
    return 'WrappedLibSparkCoin('
        ', type: $type'
        ', id: $id'
        ', height: $height'
        ', isUsed: $isUsed'
        ', k: $nonceHex'
        ', address: $address'
        ', value: $value'
        ', memo: $memo'
        ', txHash: $txHash'
        ', serialContext: $serialContext'
        ', diversifier: $diversifier'
        ', encryptedDiversifier: $encryptedDiversifier'
        ', serial: $serial'
        ', tag: $tag'
        ', lTagHash: $lTagHash'
        ', serializedCoin: $serializedCoin'
        ')';
  }
}
