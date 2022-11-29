import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/providers/ui/address_book_providers/address_entry_data_provider.dart';

final validContactStateProvider =
    StateProvider.autoDispose.family<bool, List<int>>((ref, ids) {
  bool isValid = true;

  for (int i = 0; i < ids.length; i++) {
    isValid = isValid &&
        ref.watch(
            addressEntryDataProvider(ids[i]).select((value) => value.isValid));
  }
  return isValid;
});
