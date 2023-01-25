import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/global/node_service_provider.dart';
import 'package:stackwallet/providers/global/tokens_service_provider.dart';
import 'package:stackwallet/providers/global/wallets_service_provider.dart';
import 'package:stackwallet/services/tokens.dart';
import 'package:stackwallet/services/wallets.dart';

int _count = 0;

final tokensChangeNotifierProvider = ChangeNotifierProvider<Tokens>((ref) {
  if (kDebugMode) {
    _count++;
    debugPrint("tokensChangeNotifierProvider instantiation count: $_count");
  }

  final tokensService = ref.read(tokensServiceChangeNotifierProvider);
  // final nodeService = ref.read(nodeServiceChangeNotifierProvider);

  final tokens = Tokens.sharedInstance;
  tokens.tokensService = tokensService;
  return tokens;
});
