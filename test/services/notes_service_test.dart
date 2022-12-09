import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:epicmobile/services/notes_service.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    final wallets = await Hive.openBox<dynamic>('wallets');
    await wallets.put('names', {"My Firo Wallet": "wallet_id"});
    await wallets.put('currentWalletName', "My Firo Wallet");
    final wallet = await Hive.openBox<dynamic>("wallet_id");
    await wallet.put("notes", {"txid1": "note1", "txid2": "note2"});
  });

  test("get null notes", () async {
    final service = NotesService(walletId: 'wallet_id');
    final wallet = await Hive.openBox<dynamic>("wallet_id");
    await wallet.put("notes", null);
    expect(await service.notes, <String, String>{});
  });

  test("get empty notes", () async {
    final service = NotesService(walletId: 'wallet_id');
    final wallet = await Hive.openBox<dynamic>("wallet_id");
    await wallet.put("notes", <String, String>{});
    expect(await service.notes, <String, String>{});
  });

  test("get some notes", () async {
    final service = NotesService(walletId: 'wallet_id');
    expect(await service.notes, {"txid1": "note1", "txid2": "note2"});
  });

  test("search finds none", () async {
    final service = NotesService(walletId: 'wallet_id');
    expect(await service.search("some"), <String, String>{});
  });

  test("empty search", () async {
    final service = NotesService(walletId: 'wallet_id');
    expect(await service.search(""), {"txid1": "note1", "txid2": "note2"});
  });

  test("search finds some", () async {
    final service = NotesService(walletId: 'wallet_id');
    expect(await service.search("note"), {"txid1": "note1", "txid2": "note2"});
  });

  test("search finds one", () async {
    final service = NotesService(walletId: 'wallet_id');
    expect(await service.search("2"), {"txid2": "note2"});
  });

  test("get note for existing txid", () async {
    final service = NotesService(walletId: 'wallet_id');
    expect(await service.getNoteFor(txid: "txid1"), "note1");
  });

  test("get note for non existing txid", () async {
    final service = NotesService(walletId: 'wallet_id');
    expect(await service.getNoteFor(txid: "txid"), "");
  });

  test("add new note", () async {
    final service = NotesService(walletId: 'wallet_id');
    await service.editOrAddNote(txid: "txid3", note: "note3");
    expect(await service.notes,
        {"txid1": "note1", "txid2": "note2", "txid3": "note3"});
  });

  test("add or overwrite note for new txid", () async {
    final service = NotesService(walletId: 'wallet_id');
    await service.editOrAddNote(txid: "txid3", note: "note3");
    expect(await service.notes,
        {"txid1": "note1", "txid2": "note2", "txid3": "note3"});
  });

  test("add or overwrite note for existing txid", () async {
    final service = NotesService(walletId: 'wallet_id');
    await service.editOrAddNote(txid: "txid2", note: "note3");
    expect(await service.notes, {"txid1": "note1", "txid2": "note3"});
  });

  test("delete existing note", () async {
    final service = NotesService(walletId: 'wallet_id');
    await service.deleteNote(txid: "txid2");
    expect(await service.notes, {"txid1": "note1"});
  });

  test("delete non existing note", () async {
    final service = NotesService(walletId: 'wallet_id');
    await service.deleteNote(txid: "txid5");
    expect(await service.notes, {"txid1": "note1", "txid2": "note2"});
  });

  tearDown(() async {
    await tearDownTestHive();
  });
}
