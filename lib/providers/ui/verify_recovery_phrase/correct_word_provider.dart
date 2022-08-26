import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

int _count = 0;

final verifyMnemonicCorrectWordStateProvider = StateProvider<String>((_) {
  if (kDebugMode) {
    _count++;
    debugPrint(
        "verifyMnemonicCorrectWordStateProvider instantiation count: $_count");
  }

  return "";
});
