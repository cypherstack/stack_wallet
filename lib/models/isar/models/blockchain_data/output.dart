import 'package:isar/isar.dart';

part 'output.g.dart';

@embedded
class Output {
  Output({
    this.scriptPubKey,
    this.scriptPubKeyAsm,
    this.scriptPubKeyType,
    this.scriptPubKeyAddress = "",
    this.value = 0,
  });

  late final String? scriptPubKey;

  late final String? scriptPubKeyAsm;

  late final String? scriptPubKeyType;

  late final String scriptPubKeyAddress;

  late final int value;
}
