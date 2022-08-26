import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ChangeNowLoadStatus {
  loading,
  success,
  failed,
}

final changeNowEstimatedInitialLoadStatusStateProvider =
    StateProvider<ChangeNowLoadStatus>((ref) => ChangeNowLoadStatus.loading);

final changeNowFixedInitialLoadStatusStateProvider =
    StateProvider<ChangeNowLoadStatus>((ref) => ChangeNowLoadStatus.loading);
