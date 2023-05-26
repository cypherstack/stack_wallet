import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/utilities/listenable_list.dart';

int _count = 0;

final nonFavoritesProvider =
    ChangeNotifierProvider<ListenableList<ChangeNotifierProvider<Manager>>>(
        (ref) {
  if (kDebugMode) {
    _count++;
  }

  return nonFavorites;
});
