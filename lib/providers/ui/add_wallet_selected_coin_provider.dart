import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

int _count = 0;

final addWalletSelectedCoinStateProvider =
    StateProvider.autoDispose<Coin?>((_) {
  if (kDebugMode) {
    _count++;
  }

  return null;
});
