import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/services/transaction_note_service.dart';

import '../utilities/isar_test_core.dart';

void main() {
  const walletId = "wallet-1";
  late Directory tempDir;
  late Isar isar;
  final db = MainDB.instance;

  UTXO utxo({
    required String txid,
    String wallet = walletId,
    int vout = 0,
    int value = 1000,
    String name = "",
  }) => UTXO(
    walletId: wallet,
    txid: txid,
    vout: vout,
    value: value,
    name: name,
    isBlocked: false,
    blockedReason: null,
    isCoinbase: false,
    blockHash: "block",
    blockHeight: 1,
    blockTime: 1,
  );

  TransactionNote note(String txid, String value) =>
      TransactionNote(walletId: walletId, txid: txid, value: value);

  UTXO stored(String txid, int vout, {String wallet = walletId}) => isar.utxos
      .where()
      .txidWalletIdVoutEqualTo(txid, wallet, vout)
      .findFirstSync()!;

  setUpAll(() async {
    await initializeIsarCoreForTests();
    tempDir = await Directory.systemTemp.createTemp("stack-note-test-");
    isar = await Isar.open(
      [TransactionNoteSchema, UTXOSchema],
      directory: tempDir.path,
      name: "transaction_note_test",
    );
    await db.initMainDB(mock: isar);
  });

  setUp(() async {
    await isar.writeTxn(() async {
      await isar.transactionNotes.clear();
      await isar.utxos.clear();
    });
  });

  tearDownAll(() async {
    await isar.close(deleteFromDisk: true);
    await tempDir.delete(recursive: true);
  });

  test("labels outputs that arrive after their note", () async {
    await db.putTransactionNote(note("tx-1", "exchange"));

    await db.updateUTXOs(walletId, [
      utxo(txid: "tx-1"),
      utxo(txid: "tx-1", vout: 1, name: "manual"),
    ]);

    expect(stored("tx-1", 0).name, "exchange");
    expect(stored("tx-1", 1).name, "manual");
  });

  test("labels existing blank outputs when a note is saved", () async {
    await db.updateUTXOs(walletId, [utxo(txid: "tx-2")]);

    await db.putTransactionNote(note("tx-2", "salary"));

    expect(stored("tx-2", 0).name, "salary");
  });

  test("later note edits preserve existing output labels", () async {
    await db.updateUTXOs(walletId, [
      utxo(txid: "tx-3"),
      utxo(txid: "tx-3", vout: 1, name: "manual"),
    ]);
    await db.putTransactionNote(note("tx-3", "first"));

    await db.putTransactionNote(note("tx-3", "second"));

    expect(stored("tx-3", 0).name, "first");
    expect(stored("tx-3", 1).name, "manual");
  });

  test("wallet refreshes preserve an inherited label", () async {
    await db.putTransactionNote(note("tx-refresh", "savings"));
    await db.updateUTXOs(walletId, [utxo(txid: "tx-refresh")]);

    await db.updateUTXOs(walletId, [utxo(txid: "tx-refresh", value: 1200)]);

    expect(stored("tx-refresh", 0).name, "savings");
    expect(stored("tx-refresh", 0).value, 1200);
  });

  test("refresh labels legacy blank outputs with an existing note", () async {
    await isar.writeTxn(() async {
      await isar.transactionNotes.put(note("tx-legacy", "legacy"));
      await isar.utxos.put(utxo(txid: "tx-legacy"));
    });

    await db.updateUTXOs(walletId, [utxo(txid: "tx-legacy")]);

    expect(stored("tx-legacy", 0).name, "legacy");
  });

  test("blank notes do not label outputs", () async {
    await db.putTransactionNote(note("tx-4", ""));
    await db.updateUTXOs(walletId, [utxo(txid: "tx-4")]);

    expect(stored("tx-4", 0).name, isEmpty);
  });

  test("notes never cross wallet boundaries", () async {
    await db.putTransactionNote(note("shared-txid", "private"));

    await db.updateUTXOs("wallet-2", [
      utxo(txid: "shared-txid", wallet: "wallet-2"),
    ]);

    expect(stored("shared-txid", 0, wallet: "wallet-2").name, isEmpty);
  });

  test("post-send note failures do not report a send failure", () async {
    final saved = await saveTransactionNotesAfterSend(
      notes: [note("tx-5", "gift")],
      persist: (_) async => throw StateError("disk full"),
    );

    expect(saved, isFalse);
  });

  test("post-send note persistence receives the complete batch", () async {
    List<TransactionNote>? persisted;
    final notes = [note("tx-6", "one"), note("tx-7", "two")];

    final saved = await saveTransactionNotesAfterSend(
      notes: notes,
      persist: (value) async => persisted = value,
    );

    expect(saved, isTrue);
    expect(persisted, same(notes));
  });
}
