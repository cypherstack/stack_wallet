import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/services/wallets.dart';
import 'package:epicmobile/utilities/listenable_list.dart';

int _count = 0;

final favoritesProvider =
    ChangeNotifierProvider<ListenableList<ChangeNotifierProvider<Manager>>>(
        (ref) {
  if (kDebugMode) {
    _count++;
    debugPrint("favoritesProvider instantiation count: $_count");
  }

  return favorites;
});
