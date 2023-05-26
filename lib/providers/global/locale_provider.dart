import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/services/locale_service.dart';

int _count = 0;
final localeServiceChangeNotifierProvider =
    ChangeNotifierProvider<LocaleService>((_) {
  if (kDebugMode) {
    _count++;
  }

  return LocaleService();
});
