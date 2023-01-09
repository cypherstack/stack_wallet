import 'package:epicpay/services/node_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

int _count = 0;
final nodeServiceChangeNotifierProvider =
    ChangeNotifierProvider<NodeService>((_) {
  if (kDebugMode) {
    _count++;
  }

  return NodeService();
});
