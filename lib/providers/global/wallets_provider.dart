import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/providers/global/node_service_provider.dart';
import 'package:stackduo/providers/global/wallets_service_provider.dart';
import 'package:stackduo/services/wallets.dart';

int _count = 0;

final walletsChangeNotifierProvider = ChangeNotifierProvider<Wallets>((ref) {
  if (kDebugMode) {
    _count++;
  }

  final walletsService = ref.read(walletsServiceChangeNotifierProvider);
  final nodeService = ref.read(nodeServiceChangeNotifierProvider);

  final wallets = Wallets.sharedInstance;
  wallets.walletsService = walletsService;
  wallets.nodeService = nodeService;
  return wallets;
});
