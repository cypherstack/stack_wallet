import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/models/address_book_filter.dart';

final addressBookFilterProvider =
    ChangeNotifierProvider<AddressBookFilter>((ref) => AddressBookFilter({}));
