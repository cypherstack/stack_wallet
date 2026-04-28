import 'dart:convert';
import 'dart:typed_data';

import 'package:coin/coin.dart' as coin;
import 'package:fusiondart/src/util.dart';

/// A class representing a cryptocurrency address (Bitcoin Cash specifically for
/// CashFusion).
class Address {
  /// The address as a String.
  ///
  /// Can be used with _db.getAddress to get any of the other parameters below.
  final String address;

  /// The public key as a List<int>
  final List<int> publicKey;

  /// The derivation path as a DerivationPath
  final DerivationPath? derivationPath;

  /// Should be set to true if the corresponding address in the wallet is
  /// marked as reserved for fusion purposes
  final bool fusionReserved;

  /// Constructor for Address.
  Address({
    required this.address,
    required this.publicKey,
    required this.fusionReserved,
    this.derivationPath,
  });

  /// Creates an Address from a script public key
  static Address fromScriptPubKey(
    List<int> scriptPubKey,
    coin.Chain network, [
    bool fusionReserved = false,
  ]) {
    return Utilities.getAddressFromOutputScript(
      Uint8List.fromList(scriptPubKey),
      network,
      fusionReserved,
    );
  }

  /// Returns a JSON-String representation of the Address for easier debugging.
  @override
  String toString() => toJsonString();

  /// Converts the Address to a JSON-formatted String
  String toJsonString() => jsonEncode({
        "addr": address,
        "publicKey": publicKey,
        "derivationPath": derivationPath?.value,
      });
}

/// A class representing a derivation path.
///
/// Attributes:
/// - [value]: The derivation path as a String.
class DerivationPath {
  // Holds the derivation path string
  final String value;

  // Constructor: Initializes 'value' with the given string
  DerivationPath(this.value);

  /// Splits the derivation path string into its components
  List<String> getComponents() => value.split("/");

  /// Extracts the 'purpose' from the derivation path components
  String getPurpose() => getComponents()[1];

  /// Overridden `toString` method for easier debugging
  @override
  toString() => value;

  /// Equality operator
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DerivationPath && value == other.value;

  /// hashCode implementation for use in collections
  @override
  int get hashCode => value.hashCode;
}
