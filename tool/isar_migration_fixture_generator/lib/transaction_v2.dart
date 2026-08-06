import 'dart:convert';

import 'package:isar_community/isar.dart';

part 'transaction_v2.g.dart';

enum TransactionType { outgoing, incoming, sentToSelf, unknown }

enum TransactionSubType {
  none,
  bip47Notification,
  mint,
  join,
  ethToken,
  cashFusion,
  sparkMint,
  sparkSpend,
  ordinal,
  mweb,
  splToken,
}

@Embedded()
class OutpointV2 {
  late final String txid;
  late final int vout;

  OutpointV2();

  @override
  int get hashCode => Object.hash(txid, vout);
}

@Embedded()
class InputV2 {
  late final String? scriptSigHex;
  late final String? scriptSigAsm;
  late final int? sequence;
  late final OutpointV2? outpoint;
  late final List<String> addresses;
  late final String valueStringSats;
  late final String? coinbase;
  late final String? witness;
  late final String? innerRedeemScriptAsm;
  late final bool walletOwns;

  InputV2();
}

@Embedded()
class OutputV2 {
  late final String scriptPubKeyHex;
  late final String? scriptPubKeyAsm;
  late final String valueStringSats;
  late final List<String> addresses;
  late final bool walletOwns;

  OutputV2();
}

@Collection()
class TransactionV2 {
  TransactionV2({
    required this.walletId,
    required this.blockHash,
    required this.hash,
    required this.txid,
    required this.timestamp,
    required this.height,
    required this.inputs,
    required this.outputs,
    required this.version,
    required this.type,
    required this.subType,
    required this.otherData,
  });

  Id id = Isar.autoIncrement;

  @Index()
  final String walletId;

  @Index(unique: true, composite: [CompositeIndex('walletId')])
  final String txid;

  final String hash;

  @Index()
  late final int timestamp;

  final int? height;
  final String? blockHash;
  final int version;
  final List<InputV2> inputs;
  final List<OutputV2> outputs;

  @enumerated
  final TransactionType type;

  @enumerated
  final TransactionSubType subType;

  final String? otherData;

  Map<String, dynamic> get _decodedOtherData =>
      jsonDecode(otherData ?? '{}') as Map<String, dynamic>;

  bool get isEpiccashTransaction =>
      _decodedOtherData['isEpiccashTransaction'] == true;

  int? get numberOfMessages => _decodedOtherData['numberOfMessages'] as int?;

  String? get slateId => _decodedOtherData['slateId'] as String?;

  String? get onChainNote => _decodedOtherData['onChainNote'] as String?;

  bool get isCancelled => _decodedOtherData['isCancelled'] == true;

  String? get contractAddress =>
      _decodedOtherData['contractAddress'] as String?;

  int? get nonce => _decodedOtherData['nonce'] as int?;
}
