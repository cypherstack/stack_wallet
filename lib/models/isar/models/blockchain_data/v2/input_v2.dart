import 'package:isar/isar.dart';

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
        ..sequence = sequence
        ..outpoint = outpoint
        ..addresses = List.unmodifiable(addresses)
        ..valueStringSats = valueStringSats
        ..witness = witness
        ..innerRedeemScriptAsm = innerRedeemScriptAsm
        ..innerRedeemScriptAsm = innerRedeemScriptAsm
        ..walletOwns = walletOwns;

  InputV2 copyWith({
    String? scriptSigHex,
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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is InputV2 &&
        other.scriptSigHex == scriptSigHex &&
        other.sequence == sequence &&
        other.outpoint == outpoint;
  }

  @override
  int get hashCode => Object.hash(
        scriptSigHex,
        sequence,
        outpoint,
      );

  @override
  String toString() {
    return 'InputV2(\n'
        '  scriptSigHex: $scriptSigHex,\n'
        '  sequence: $sequence,\n'
        '  outpoint: $outpoint,\n'
        '  addresses: $addresses,\n'
        '  valueStringSats: $valueStringSats,\n'
        '  coinbase: $coinbase,\n'
        '  witness: $witness,\n'
        '  innerRedeemScriptAsm: $innerRedeemScriptAsm,\n'
        ')';
  }
}
