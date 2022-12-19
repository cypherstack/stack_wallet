import 'package:epicpay/services/notes_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

int _count = 0;

final notesServiceChangeNotifierProvider =
    ChangeNotifierProvider.family<NotesService, String>((_, walletId) {
  if (kDebugMode) {
    _count++;
  }

  return NotesService(walletId: walletId);
});
