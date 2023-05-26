import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ChangeNowLoadStatus {
  waiting,
  loading,
  success,
  failed,
}

final changeNowEstimatedInitialLoadStatusStateProvider =
    StateProvider<ChangeNowLoadStatus>((ref) => ChangeNowLoadStatus.waiting);

final changeNowFixedInitialLoadStatusStateProvider =
    StateProvider<ChangeNowLoadStatus>((ref) => ChangeNowLoadStatus.waiting);
