import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/services/notes_service.dart';

int _count = 0;

final notesServiceChangeNotifierProvider =
    ChangeNotifierProvider.family<NotesService, String>((_, walletId) {
  if (kDebugMode) {
    _count++;
    debugPrint(
        "notesServiceChangeNotifierProvider instantiation count: $_count");
  }

  return NotesService(walletId: walletId);
});
