import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

int _count = 0;

final checkBoxStateProvider = StateProvider.autoDispose<bool>((_) {
  if (kDebugMode) {
    _count++;
    debugPrint("checkBoxStateProvider instantiation count: $_count");
  }

  return false;
});
