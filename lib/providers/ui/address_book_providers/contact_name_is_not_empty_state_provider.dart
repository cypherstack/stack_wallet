import 'package:flutter_riverpod/flutter_riverpod.dart';

final contactNameIsNotEmptyStateProvider =
    StateProvider.autoDispose<bool>((_) => false);
