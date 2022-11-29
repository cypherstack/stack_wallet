import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/services/node_service.dart';

int _count = 0;
final nodeServiceChangeNotifierProvider =
    ChangeNotifierProvider<NodeService>((_) {
  if (kDebugMode) {
    _count++;
    debugPrint(
        "nodeServiceChangeNotifierProvider instantiation count: $_count");
  }

  return NodeService();
});
