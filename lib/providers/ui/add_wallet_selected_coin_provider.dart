import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';

int _count = 0;

final addWalletSelectedCoinStateProvider =
    StateProvider.autoDispose<Coin?>((_) {
  if (kDebugMode) {
    _count++;
    debugPrint(
        "addWalletSelectedCoinStateProvider instantiation count: $_count");
  }

  return null;
});
