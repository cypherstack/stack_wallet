import 'dart:typed_data';

import 'package:bitcoindart/bitcoindart.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';

class SigningData {
  SigningData({
    required this.derivePathType,
    required this.utxo,
    this.output,
    this.keyPair,
    this.redeemScript,
  });

  final DerivePathType derivePathType;
  final UTXO utxo;
  Uint8List? output;
  ECPair? keyPair;
  Uint8List? redeemScript;
}
