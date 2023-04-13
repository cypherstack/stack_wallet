import 'package:flutter_riverpod/flutter_riverpod.dart';

final previewTxButtonStateProvider = StateProvider.autoDispose<bool>((_) {
  return false;
});

final previewTokenTxButtonStateProvider = StateProvider.autoDispose<bool>((_) {
  return false;
});
