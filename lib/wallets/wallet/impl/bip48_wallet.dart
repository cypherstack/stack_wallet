import 'dart:async';

import '../../../electrumx_rpc/cached_electrumx_client.dart';
import '../../../electrumx_rpc/electrumx_client.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/coins/bip48_bitcoin.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import 'bitcoin_wallet.dart';

class BIP48BitcoinWallet extends BitcoinWallet<BIP48Bitcoin> {
  BIP48BitcoinWallet(CryptoCurrencyNetwork network) : super(network);

  late ElectrumXClient electrumXClient;
  late CachedElectrumXClient electrumXCachedClient;

  // ==================== Overrides ============================================

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    final address = await getCurrentReceivingAddress();
    if (address == null) {
      // TODO derive address.
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      Logging.instance.log("confirmSend txData: $txData", level: LogLevel.Info);

      final hex = txData.raw!;

      final txHash = await electrumXClient.broadcastTransaction(rawTx: hex);
      Logging.instance.log("Sent txHash: $txHash", level: LogLevel.Info);

      // mark utxos as used
      final usedUTXOs = txData.utxos!.map((e) => e.copyWith(used: true));
      await mainDB.putUTXOs(usedUTXOs.toList());

      txData = txData.copyWith(
        utxos: usedUTXOs.toSet(),
        txHash: txHash,
        txid: txHash,
      );

      return txData;
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from confirmSend(): $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) {
    // TODO: implement prepareSend
    throw UnimplementedError();
  }

  @override
  Future<void> recover({
    required bool isRescan,
    String? multisigConfig,
  }) async {
    // TODO.
  }

  @override
  Future<void> generateNewChangeAddress() async {
    final current = await getCurrentChangeAddress();
    const chain = 0; // TODO.
    const index = 0; // TODO.

    Address? address;
    while (address == null) {
      try {
        // TODO.
        // address = await _generateAddress(
        //   change: chain,
        //   index: index,
        // );
      } catch (e) {
        rethrow;
      }
    }

    await mainDB.updateOrPutAddresses([address]);
  }

  @override
  Future<void> generateNewReceivingAddress() async {
    final current = await getCurrentReceivingAddress();
    // TODO: Handle null assertion below.
    int index = current!.derivationIndex + 1;
    const chain = 0; // receiving address

    Address? address;
    while (address == null) {
      try {
        // TODO.
        // address = await _generateAddress(
        //   change: chain,
        //   index: index,
        // );
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<Address> _generateAddressSafe({
    required final int chain,
    required int startingIndex,
  }) async {
    Address? address;
    while (address == null) {
      try {
        // TODO.
        // address = await _generateAddress(
        //   change: chain,
        //   index: startingIndex,
        // );
      } catch (e) {
        rethrow;
      }
    }

    return address;
  }
}
