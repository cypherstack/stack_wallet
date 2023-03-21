import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/services/coins/manager.dart';
import 'package:stackduo/services/wallets.dart';
import 'package:stackduo/utilities/listenable_list.dart';

int _count = 0;

final nonFavoritesProvider =
    ChangeNotifierProvider<ListenableList<ChangeNotifierProvider<Manager>>>(
        (ref) {
  if (kDebugMode) {
    _count++;
  }

  return nonFavorites;
});
