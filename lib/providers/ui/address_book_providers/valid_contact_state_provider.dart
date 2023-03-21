import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/providers/ui/address_book_providers/address_entry_data_provider.dart';

final validContactStateProvider =
    StateProvider.autoDispose.family<bool, List<int>>((ref, ids) {
  bool isValid = true;

  bool hasAtLeastOneValid = false;

  for (int i = 0; i < ids.length; i++) {
    final _valid = ref.watch(
        addressEntryDataProvider(ids[i]).select((value) => value.isValid));

    final _isEmpty = ref.watch(
        addressEntryDataProvider(ids[i]).select((value) => value.isEmpty));

    isValid = isValid && (_valid || _isEmpty);
    if (_valid) {
      hasAtLeastOneValid = true;
    }
  }
  return isValid && hasAtLeastOneValid;
});
