import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/services/node_service.dart';

int _count = 0;
final nodeServiceChangeNotifierProvider =
    ChangeNotifierProvider<NodeService>((ref) {
  if (kDebugMode) {
    _count++;
  }

  return NodeService(secureStorageInterface: ref.read(secureStoreProvider));
});
