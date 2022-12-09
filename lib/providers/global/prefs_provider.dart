import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicpay/utilities/prefs.dart';

int _count = 0;
final prefsChangeNotifierProvider = ChangeNotifierProvider<Prefs>((_) {
  if (kDebugMode) {
    _count++;
    debugPrint("prefsChangeNotifierProvider instantiation count: $_count");
  }

  return Prefs.instance;
});
