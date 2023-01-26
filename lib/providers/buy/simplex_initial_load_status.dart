import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SimplexLoadStatus {
  waiting,
  loading,
  success,
  failed,
}

final simplexLoadStatusStateProvider =
    StateProvider<SimplexLoadStatus>((ref) => SimplexLoadStatus.waiting);
