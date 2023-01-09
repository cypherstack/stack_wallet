import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

int _count = 0;

final introViewIndexProvider = StateProvider<int>((_) {
  if (kDebugMode) {
    _count++;
  }

  return 0;
});
