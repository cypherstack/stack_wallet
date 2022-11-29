import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/models/contact_address_entry_data.dart';

// workaround to refresh entire family
final addressEntryDataProviderFamilyRefresher = Provider((_) => DateTime.now());

final addressEntryDataProvider =
    ChangeNotifierProvider.family<AddressEntryData, int>((ref, id) {
  ref.watch(addressEntryDataProviderFamilyRefresher);
  return AddressEntryData(id);
});
