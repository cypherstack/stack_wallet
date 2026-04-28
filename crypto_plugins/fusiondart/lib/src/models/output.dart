import 'dart:typed_data';

import 'package:coin/coin.dart' as coin;
import 'package:fusiondart/src/protobuf/fusion.pb.dart';
import 'package:fusiondart/src/util.dart';

/// Output component class
///
/// Based on the protobuf definition of an OutputComponent.
class Output {
  /// Value of the output in satoshis.
  final int value;

  final Uint8List scriptPubKey;

  Output._({
    required this.value,
    required this.scriptPubKey,
  });

  static Output fromScriptPubKey({
    required int value,
    required List<int> scriptPubkey,
  }) {
    return Output._(
      value: value,
      scriptPubKey: Uint8List.fromList(scriptPubkey),
    );
  }

  static Output fromAddress({
    required int value,
    required String address,
    required coin.Chain network,
  }) {
    return Output._(
      value: value,
      scriptPubKey: Utilities.scriptOf(address: address, network: network),
    );
  }

  /// Factory method to create an Output object from an `OutputComponent`.
  static Output fromOutputComponent(
    OutputComponent outputComponent,
  ) {
    return fromScriptPubKey(
      value: outputComponent.amount.toInt(),
      scriptPubkey: outputComponent.scriptpubkey,
    );
  }
}
