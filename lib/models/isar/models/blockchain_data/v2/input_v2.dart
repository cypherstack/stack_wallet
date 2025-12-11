import 'dart:convert';

import 'package:isar_community/isar.dart';

part 'input_v2.g.dart';

@Embedded()
class OutpointV2 {
  late final String txid;
  late final int vout;

  OutpointV2();

  static OutpointV2 isarCantDoRequiredInDefaultConstructor({
    required String txid,
    required int vout,
  }) =>
      OutpointV2()
        ..vout = vout
        ..txid = txid;

  @override
  String toString() {
    return 'OutpointV2(\n'
        '  txid: $txid,\n'
        '  vout: $vout,\n'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OutpointV2 && other.txid == txid && other.vout == vout;
  }

  @override
  int get hashCode {
    return Object.hash(
      txid.hashCode,
      vout.hashCode,
    );
  }
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

  @ignore
  BigInt get value => BigInt.parse(valueStringSats);

  InputV2();

  static InputV2 isarCantDoRequiredInDefaultConstructor({
    required String? scriptSigHex,
    required String? scriptSigAsm,
    required int? sequence,
    required OutpointV2? outpoint,
    required List<String> addresses,
    required String valueStringSats,
    required String? witness,
    required String? innerRedeemScriptAsm,
    required String? coinbase,
    required bool walletOwns,
  }) =>
      InputV2()
        ..scriptSigHex = scriptSigHex
        ..scriptSigAsm = scriptSigAsm
        ..sequence = sequence
        ..outpoint = outpoint
        ..addresses = List.unmodifiable(addresses)
        ..valueStringSats = valueStringSats
        ..witness = witness
        ..innerRedeemScriptAsm = innerRedeemScriptAsm
        ..coinbase = coinbase
        ..walletOwns = walletOwns;

  static InputV2 fromElectrumxJson({
    required Map<String, dynamic> json,
    required OutpointV2? outpoint,
    required List<String> addresses,
    required String valueStringSats,
    required String? coinbase,
    required bool walletOwns,
  }) {
    final dynamicWitness = json["witness"] ?? json["txinwitness"];

    final String? witness;
    if (dynamicWitness is Map || dynamicWitness is List) {
      witness = jsonEncode(dynamicWitness);
    } else if (dynamicWitness is String) {
      witness = dynamicWitness;
    } else {
      witness = null;
    }

    return InputV2()
      ..scriptSigHex = json["scriptSig"]?["hex"] as String?
      ..scriptSigAsm = json["scriptSig"]?["asm"] as String?
      ..sequence = json["sequence"] as int?
      ..outpoint = outpoint
      ..addresses = List.unmodifiable(addresses)
      ..valueStringSats = valueStringSats
      ..witness = witness
      ..innerRedeemScriptAsm = json["innerRedeemscriptAsm"] as String?
      ..coinbase = coinbase
      ..walletOwns = walletOwns;
  }

  InputV2 copyWith({
    String? scriptSigHex,
    String? scriptSigAsm,
    int? sequence,
    OutpointV2? outpoint,
    List<String>? addresses,
    String? valueStringSats,
    String? coinbase,
    String? witness,
    String? innerRedeemScriptAsm,
    bool? walletOwns,
  }) {
    return InputV2.isarCantDoRequiredInDefaultConstructor(
      scriptSigHex: scriptSigHex ?? this.scriptSigHex,
      scriptSigAsm: scriptSigAsm ?? this.scriptSigAsm,
      sequence: sequence ?? this.sequence,
      outpoint: outpoint ?? this.outpoint,
      addresses: addresses ?? this.addresses,
      valueStringSats: valueStringSats ?? this.valueStringSats,
      coinbase: coinbase ?? this.coinbase,
      witness: witness ?? this.witness,
      innerRedeemScriptAsm: innerRedeemScriptAsm ?? this.innerRedeemScriptAsm,
      walletOwns: walletOwns ?? this.walletOwns,
    );
  }

  @override
  String toString() {
    return 'InputV2(\n'
        '  scriptSigHex: $scriptSigHex,\n'
        '  scriptSigAsm: $scriptSigAsm,\n'
        '  sequence: $sequence,\n'
        '  outpoint: $outpoint,\n'
        '  addresses: $addresses,\n'
        '  valueStringSats: $valueStringSats,\n'
        '  coinbase: $coinbase,\n'
        '  witness: $witness,\n'
        '  innerRedeemScriptAsm: $innerRedeemScriptAsm,\n'
        '  walletOwns: $walletOwns,\n'
        ')';
  }
}
