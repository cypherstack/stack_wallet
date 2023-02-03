import 'package:isar/isar.dart';

part 'input.g.dart';

@embedded
class Input {
  Input({
    this.txid = "error",
    this.vout = -1,
    this.scriptSig,
    this.scriptSigAsm,
    this.isCoinbase,
    this.sequence,
    this.innerRedeemScriptAsm,
  });

  late final String txid;

  late final int vout;

  late final String? scriptSig;

  late final String? scriptSigAsm;

  late final String? witness;

  late final bool? isCoinbase;

  late final int? sequence;

  late final String? innerRedeemScriptAsm;
}
