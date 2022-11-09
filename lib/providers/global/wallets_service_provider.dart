import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/services/wallets_service.dart';

int _count = 0;

final walletsServiceChangeNotifierProvider =
    ChangeNotifierProvider<WalletsService>((ref) {
  if (kDebugMode) {
    _count++;
    debugPrint(
        "walletsServiceChangeNotifierProvider instantiation count: $_count");
  }

  return WalletsService(
    secureStorageInterface: ref.read(secureStoreProvider),
  );
});
