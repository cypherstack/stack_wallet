import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/dto/ordinals/inscription_data.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';

part 'ordinal.g.dart';

@collection
class Ordinal {
  Id id = Isar.autoIncrement;

  final String walletId;

  @Index(unique: true, replace: true, composite: [
    CompositeIndex("utxoTXID"),
    CompositeIndex("utxoVOUT"),
  ])
  final String inscriptionId;

  final int inscriptionNumber;

  final String content;

  // following two are used to look up the UTXO object in isar combined w/ walletId
  final String utxoTXID;
  final int utxoVOUT;

  Ordinal({
    required this.walletId,
    required this.inscriptionId,
    required this.inscriptionNumber,
    required this.content,
    required this.utxoTXID,
    required this.utxoVOUT,
  });

  factory Ordinal.fromInscriptionData(InscriptionData data, String walletId) {
    return Ordinal(
      walletId: walletId,
      inscriptionId: data.inscriptionId,
      inscriptionNumber: data.inscriptionNumber,
      content: data.content,
      utxoTXID: data.output.split(':')[
          0], // "output": "062f32e21aa04246b8873b5d9a929576addd0339881e1ea478b406795d6b6c47:0"
      utxoVOUT: int.parse(data.output.split(':')[1]),
    );
  }

  Ordinal copyWith({
    String? walletId,
    String? inscriptionId,
    int? inscriptionNumber,
    String? content,
    String? utxoTXID,
    int? utxoVOUT,
  }) {
    return Ordinal(
      walletId: walletId ?? this.walletId,
      inscriptionId: inscriptionId ?? this.inscriptionId,
      inscriptionNumber: inscriptionNumber ?? this.inscriptionNumber,
      content: content ?? this.content,
      utxoTXID: utxoTXID ?? this.utxoTXID,
      utxoVOUT: utxoVOUT ?? this.utxoVOUT,
    );
  }

  UTXO? getUTXO(MainDB db) {
    return db.isar.utxos
        .where()
        .walletIdEqualTo(walletId)
        .filter()
        .txidEqualTo(utxoTXID)
        .and()
        .voutEqualTo(utxoVOUT)
        .findFirstSync();
  }

  @override
  String toString() {
    return 'Ordinal {'
        ' walletId: $walletId,'
        ' inscriptionId: $inscriptionId,'
        ' inscriptionNumber: $inscriptionNumber,'
        ' content: $content,'
        ' utxoTXID: $utxoTXID,'
        ' utxoVOUT: $utxoVOUT'
        ' }';
  }
}
