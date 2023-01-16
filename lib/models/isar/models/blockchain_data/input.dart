import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/output.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';

part 'input.g.dart';

@Collection()
class Input {
  Input({
    required this.walletId,
    required this.txid,
    required this.vout,
    required this.scriptSig,
    required this.scriptSigAsm,
    required this.isCoinbase,
    required this.sequence,
    required this.innerRedeemScriptAsm,
  });

  Id id = Isar.autoIncrement;

  @Index()
  late String walletId;

  late String txid;

  late int vout;

  late String? scriptSig;

  late String? scriptSigAsm;

  // TODO: find witness type // is it even used?
  // late List<dynamic>? witness;

  late bool? isCoinbase;

  late int? sequence;

  late String? innerRedeemScriptAsm;

  final prevOut = IsarLink<Output>();

  @Backlink(to: 'inputs')
  final transaction = IsarLink<Transaction>();
}
