import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

int _count = 0;

final verifyMnemonicWordIndexStateProvider = StateProvider<int>((_) {
  if (kDebugMode) {
    _count++;
    debugPrint(
        "verifyMnemonicWordIndexStateProvider instantiation count: $_count");
  }

  return 0;
});
