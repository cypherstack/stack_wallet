import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/services/tokens_service.dart';
import 'package:stackwallet/services/wallets_service.dart';

int _count = 0;

final tokensServiceChangeNotifierProvider =
    ChangeNotifierProvider<TokensService>((ref) {
  if (kDebugMode) {
    _count++;
    debugPrint(
        "tokensServiceChangeNotifierProvider instantiation count: $_count");
  }

  return TokensService(
    secureStorageInterface: ref.read(secureStoreProvider),
  );
});
