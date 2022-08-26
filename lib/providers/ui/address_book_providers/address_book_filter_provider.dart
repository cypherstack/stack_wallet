import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/address_book_filter.dart';

final addressBookFilterProvider =
    ChangeNotifierProvider<AddressBookFilter>((ref) => AddressBookFilter({}));
