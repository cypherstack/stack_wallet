import 'package:isar_community/isar.dart';

import '../../../dto/ordinals/inscription_data.dart';
import '../../../models/isar/ordinal.dart';
import '../../../services/ord_api.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import 'electrumx_interface.dart';

mixin OrdinalsInterface<T extends ElectrumXCurrencyInterface>
    on ElectrumXInterface<T> {
  /// Subclasses must provide the base URL for their ord server.
  /// e.g. 'https://ord-litecoin.stackwallet.com'
  String get ordServerBaseUrl;

  late final OrdAPI _ordAPI = OrdAPI(baseUrl: ordServerBaseUrl);

  /// Check whether a specific output contains inscriptions.
  Future<bool> _inscriptionInOutput(String txid, int vout) async {
    try {
      final ids = await _ordAPI.getInscriptionIdsForOutput(txid, vout);
      return ids.isNotEmpty;
    } catch (e, s) {
      Logging.instance.e(
        "Ord API output check failure!",
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  Future<void> refreshInscriptions() async {
    try {
      final utxos = await mainDB.getUTXOs(walletId).findAll();

      final List<InscriptionData> allInscriptions = [];

      for (final utxo in utxos) {
        try {
          final ids = await _ordAPI.getInscriptionIdsForOutput(
            utxo.txid,
            utxo.vout,
          );

          for (final inscriptionId in ids) {
            try {
              final json = await _ordAPI.getInscriptionData(inscriptionId);
              allInscriptions.add(
                InscriptionData.fromOrdJson(
                  json,
                  _ordAPI.contentUrl(inscriptionId),
                ),
              );
            } catch (e) {
              Logging.instance.w(
                "Failed to fetch inscription $inscriptionId: $e",
              );
            }
          }
        } catch (e) {
          Logging.instance.w(
            "Failed to check output ${utxo.txid}:${utxo.vout}: $e",
          );
        }
      }

      final ords = allInscriptions
          .map((e) => Ordinal.fromInscriptionData(e, walletId))
          .toList();

      await mainDB.isar.writeTxn(() async {
        await mainDB.isar.ordinals
            .where()
            .filter()
            .walletIdEqualTo(walletId)
            .deleteAll();
        await mainDB.isar.ordinals.putAll(ords);
      });
    } catch (e, s) {
      Logging.instance.w(
        "$runtimeType failed refreshInscriptions(): ",
        error: e,
        stackTrace: s,
      );
    }
  }

  // =================== Overrides =============================================

  @override
  Future<({bool blocked, String? blockedReason, String? utxoLabel})>
  checkBlockUTXO(
    Map<String, dynamic> jsonUTXO,
    String? scriptPubKeyHex,
    Map<String, dynamic> jsonTX,
    String? utxoOwnerAddress,
  ) async {
    bool shouldBlock = false;
    String? blockReason;
    String? label;

    final txid = jsonTX["txid"] as String;
    final vout = jsonUTXO["tx_pos"] as int;
    final utxoAmount = jsonUTXO["value"] as int;

    if (await _inscriptionInOutput(txid, vout)) {
      shouldBlock = true;
      blockReason = "Ordinal";
      label = "Ordinal detected at output";
    } else if (utxoAmount <= 10000) {
      shouldBlock = true;
      blockReason = "May contain ordinal";
      label = "Possible ordinal";
    }

    return (blockedReason: blockReason, blocked: shouldBlock, utxoLabel: label);
  }
}
