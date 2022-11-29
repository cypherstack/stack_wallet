import 'package:epicmobile/hive/db.dart';

class TransactionNotificationTracker {
  final String walletId;

  TransactionNotificationTracker({required this.walletId});

  List<String> get pendings {
    final notifiedPendingTransactions = DB.instance.get<dynamic>(
            boxName: walletId, key: "notifiedPendingTransactions") as Map? ??
        {};
    return List<String>.from(notifiedPendingTransactions.keys);
  }

  bool wasNotifiedPending(String txid) {
    final notifiedPendingTransactions = DB.instance.get<dynamic>(
            boxName: walletId, key: "notifiedPendingTransactions") as Map? ??
        {};
    return notifiedPendingTransactions[txid] as bool? ?? false;
  }

  Future<void> addNotifiedPending(String txid) async {
    final notifiedPendingTransactions = DB.instance.get<dynamic>(
            boxName: walletId, key: "notifiedPendingTransactions") as Map? ??
        {};
    notifiedPendingTransactions[txid] = true;
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: "notifiedPendingTransactions",
        value: notifiedPendingTransactions);
  }

  List<String> get confirmeds {
    final notifiedConfirmedTransactions = DB.instance.get<dynamic>(
            boxName: walletId, key: "notifiedConfirmedTransactions") as Map? ??
        {};
    return List<String>.from(notifiedConfirmedTransactions.keys);
  }

  bool wasNotifiedConfirmed(String txid) {
    final notifiedConfirmedTransactions = DB.instance.get<dynamic>(
            boxName: walletId, key: "notifiedConfirmedTransactions") as Map? ??
        {};
    return notifiedConfirmedTransactions[txid] as bool? ?? false;
  }

  Future<void> addNotifiedConfirmed(String txid) async {
    final notifiedConfirmedTransactions = DB.instance.get<dynamic>(
            boxName: walletId, key: "notifiedConfirmedTransactions") as Map? ??
        {};
    notifiedConfirmedTransactions[txid] = true;
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: "notifiedConfirmedTransactions",
        value: notifiedConfirmedTransactions);
  }
}
