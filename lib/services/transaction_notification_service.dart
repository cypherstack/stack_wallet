import '../models/isar/models/blockchain_data/transaction.dart';
import '../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../wallets/crypto_currency/crypto_currency.dart';
import 'event_bus/events/global/crypto_notification_event.dart';
import 'transaction_notification_tracker.dart';

typedef CryptoNotificationSink =
    Future<void> Function(CryptoNotificationEvent event);

class TransactionNotificationService {
  TransactionNotificationService({
    required this.store,
    CryptoNotificationSink? notificationSink,
  }) : _notificationSink = notificationSink ?? _deliverThroughEventBus;

  final TransactionNotificationStore store;
  final CryptoNotificationSink _notificationSink;

  static Future<void> _deliverThroughEventBus(
    CryptoNotificationEvent event,
  ) async {
    if (!CryptoNotificationsEventBus.hasListeners) {
      throw StateError("No crypto notification listener is registered");
    }
    CryptoNotificationsEventBus.instance.fire(event);
    await event.delivered.timeout(const Duration(seconds: 30));
  }

  Future<void> notifyNewIncomingTransactions({
    required Set<String> knownTxids,
    required Iterable<TransactionV2> transactions,
    required CryptoCurrency coin,
    required String walletId,
    required String walletName,
    required int chainHeight,
    required bool supportsConfirmationUpdates,
  }) async {
    final deliveredTxids = store.deliveredTxids;
    final incoming = transactions
        .where((tx) => tx.type == TransactionType.incoming)
        .where((tx) => !knownTxids.contains(tx.txid))
        .where((tx) => !deliveredTxids.contains(tx.txid))
        .toList();

    if (!store.isInitialized && knownTxids.isEmpty) {
      await store.markInitialized();
      return;
    }

    if (!store.isInitialized) {
      await store.markInitialized();
    }

    for (final tx in incoming) {
      final amount = tx.getAmountReceivedInThisWallet(
        fractionDigits: coin.fractionDigits,
      );
      final formattedAmount = amount.decimal.toStringAsFixed(
        coin.fractionDigits,
      );
      final payload = "$formattedAmount ${coin.ticker}";

      final event = CryptoNotificationEvent(
        title: "Incoming ${coin.prettyName} transaction",
        walletId: walletId,
        walletName: walletName,
        date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
        shouldWatchForUpdates:
            supportsConfirmationUpdates &&
            (tx.height == null || tx.height! <= 0),
        coin: coin,
        txid: tx.txid,
        confirmations: tx.getConfirmations(chainHeight),
        requiredConfirmations: coin.minConfirms,
        payload: payload,
      );

      await _notificationSink(event);
      await store.recordDelivered(tx.txid);
    }
  }
}
