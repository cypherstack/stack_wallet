import 'package:flutter/material.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/utilities/logger.dart';

class NotesService extends ChangeNotifier {
  final String walletId;

  NotesService({required this.walletId});

  Map<String, String> get notesSync {
    final notes =
        DB.instance.get<dynamic>(boxName: walletId, key: 'notes') as Map?;
    return notes == null ? <String, String>{} : Map<String, String>.from(notes);
  }

  /// Holds transaction notes
  /// map of contact <txid, note>
  /// txid is used as key due to uniqueness
  Future<Map<String, String>>? _notes;
  Future<Map<String, String>> get notes => _notes ??= _fetchNotes();

  // fetch notes map
  Future<Map<String, String>> _fetchNotes() async {
    final notes =
        DB.instance.get<dynamic>(boxName: walletId, key: 'notes') as Map?;

    return notes == null ? <String, String>{} : Map<String, String>.from(notes);
  }

  /// search notes
  //TODO optimize notes search?
  Future<Map<String, String>> search(String text) async {
    if (text.isEmpty) return notes;
    var results = Map<String, String>.from(await notes);
    results.removeWhere(
        (key, value) => (!key.contains(text) && !value.contains(text)));
    return results;
  }

  /// fetch note given a transaction ID
  Future<String> getNoteFor({required String txid}) async {
    final note = (await notes)[txid];
    return note ?? "";
  }

  /// edit or add new note for the given [txid]
  Future<void> editOrAddNote(
      {required String txid, required String note}) async {
    final _notes = await notes;

    _notes[txid] = note;
    await DB.instance
        .put<dynamic>(boxName: walletId, key: 'notes', value: _notes);
    //todo: check if this is needed
    Logging.instance.log("editOrAddNote: tx note saved", level: LogLevel.Info);
    await _refreshNotes();
  }

  /// Remove note from db
  Future<void> deleteNote({required String txid}) async {
    final entries =
        DB.instance.get<dynamic>(boxName: walletId, key: 'notes') as Map;
    entries.remove(txid);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: 'notes', value: entries);
    Logging.instance.log("tx note removed", level: LogLevel.Info);
    await _refreshNotes();
  }

  Future<void> _refreshNotes() async {
    final newNotes = await _fetchNotes();
    _notes = Future(() => newNotes);
    notifyListeners();
  }
}
