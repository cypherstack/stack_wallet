import 'package:epicpay/services/locale_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

int _count = 0;
final localeServiceChangeNotifierProvider =
    ChangeNotifierProvider<LocaleService>((_) {
  if (kDebugMode) {
    _count++;
  }

  return LocaleService();
});
