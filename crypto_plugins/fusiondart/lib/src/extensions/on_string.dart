import 'dart:convert';
import 'dart:typed_data';

// import 'package:dart_bs58/dart_bs58.dart';
// import 'package:dart_bs58check/dart_bs58check.dart';
import 'package:fusiondart/src/extensions/on_uint8list.dart';
import 'package:hex/hex.dart';

extension StringExtensions on String {
  Uint8List get toUint8ListFromUtf8 => Uint8List.fromList(utf8.encode(this));

  Uint8List get toUint8ListFromHex =>
      Uint8List.fromList(HEX.decode(startsWith("0x") ? substring(2) : this));

  // Uint8List get toUint8ListFromBase58Encoded => bs58.decode(this);
  //
  // Uint8List get toUint8ListFromBase58CheckEncoded => bs58check.decode(this);

  BigInt get toBigIntFromHex => toUint8ListFromHex.toBigInt;
}
