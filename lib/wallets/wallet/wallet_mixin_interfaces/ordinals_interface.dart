import 'package:isar/isar.dart';
import '../../../dto/ordinals/inscription_data.dart';
import '../../../models/isar/models/blockchain_data/utxo.dart';
import '../../../models/isar/ordinal.dart';
import '../../../services/litescribe_api.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import 'electrumx_interface.dart';

mixin OrdinalsInterface<T extends ElectrumXCurrencyInterface>
    on ElectrumXInterface<T> {
  final LitescribeAPI _litescribeAPI =
      LitescribeAPI(baseUrl: 'https://litescribe.io/api');

  // check if an inscription is in a given <UTXO> output
  Future<bool> _inscriptionInAddress(String address) async {
    try {
      return (await _litescribeAPI.getInscriptionsByAddress(address))
          .isNotEmpty;
    } catch (_) {
      Logging.instance.log("Litescribe api failure!", level: LogLevel.Error);

      return false;
    }
  }

  Future<void> refreshInscriptions({
    List<String>? overrideAddressesToCheck,
  }) async {
    try {
      final uniqueAddresses = overrideAddressesToCheck ??
          await mainDB
              .getUTXOs(walletId)
              .filter()
              .addressIsNotNull()
              .distinctByAddress()
              .addressProperty()
              .findAll();
      final inscriptions = await _getInscriptionDataFromAddresses(
          uniqueAddresses.cast<String>());

      final ords = inscriptions
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
      Logging.instance.log(
        "$runtimeType failed refreshInscriptions(): $e\n$s",
        level: LogLevel.Warning,
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

    final utxoAmount = jsonUTXO["value"] as int;

    // TODO: [prio=med] check following 3 todos

    // TODO check the specific output, not just the address in general
    // TODO optimize by freezing output in OrdinalsInterface, so one ordinal API calls is made (or at least many less)
    if (utxoOwnerAddress != null &&
        await _inscriptionInAddress(utxoOwnerAddress)) {
      shouldBlock = true;
      blockReason = "Ordinal";
      label = "Ordinal detected at address";
    } else {
      // TODO implement inscriptionInOutput
      if (utxoAmount <= 10000) {
        shouldBlock = true;
        blockReason = "May contain ordinal";
        label = "Possible ordinal";
      }
    }

    return (blockedReason: blockReason, blocked: shouldBlock, utxoLabel: label);
  }

  @override
  Future<bool> updateUTXOs() async {
    final newUtxosAdded = await super.updateUTXOs();
    if (newUtxosAdded) {
      try {
        await refreshInscriptions();
      } catch (_) {
        // do nothing but do not block/fail this updateUTXOs call based on litescribe call failures
      }
    }

    return newUtxosAdded;
  }

  // ===================== Private =============================================
  Future<List<InscriptionData>> _getInscriptionDataFromAddresses(
      List<String> addresses) async {
    List<InscriptionData> allInscriptions = [];
    for (String address in addresses) {
      try {
        var inscriptions =
            await _litescribeAPI.getInscriptionsByAddress(address);
        allInscriptions.addAll(inscriptions);
      } catch (e) {
        throw Exception("Error fetching inscriptions for address $address: $e");
      }
    }
    return allInscriptions;
  }
}
