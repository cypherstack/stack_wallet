/// Nongenerated protobuf helpers/wrappers

import 'dart:typed_data';

import 'package:fusiondart/src/protobuf/fusion.pb.dart';

/// Helper class to wrap the protobuf ComponentResult.
class ComponentResult {
  final Uint8List commitment; // Commitment for this component.
  final int counter; // Counter for this component.
  final Uint8List component; // Actual component as Uint8List.
  final Proof proof; // Proof for this component.
  final Uint8List privateKey; // Private key for this component.

  /// Constructor for the ComponentResult class.
  ComponentResult({
    required this.commitment,
    required this.counter,
    required this.component,
    required this.proof,
    required this.privateKey,
  });
}
