import 'package:epicpay/utilities/prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

int _count = 0;
final prefsChangeNotifierProvider = ChangeNotifierProvider<Prefs>((_) {
  if (kDebugMode) {
    _count++;
  }

  return Prefs.instance;
});
