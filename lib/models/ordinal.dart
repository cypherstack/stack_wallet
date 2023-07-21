import 'package:stackwallet/dto/ordinals/inscription_data.dart';

class Ordinal {
  final String inscriptionId;
  final int inscriptionNumber;
  final String content;

  // following two are used to look up the UTXO object in isar combined w/ walletId
  final String utxoTXID;
  final int utxoVOUT;

  Ordinal({
    required this.inscriptionId,
    required this.inscriptionNumber,
    required this.content,
    required this.utxoTXID,
    required this.utxoVOUT,
  });

  factory Ordinal.fromInscriptionData(InscriptionData data) {
    return Ordinal(
      inscriptionId: data.inscriptionId,
      inscriptionNumber: data.inscriptionNumber,
      content: data.content,
      utxoTXID: data.output.split(':')[0], // "output": "062f32e21aa04246b8873b5d9a929576addd0339881e1ea478b406795d6b6c47:0"
      utxoVOUT: int.parse(data.output.split(':')[1]),
    );
  }
}