import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/services/address_book_service.dart';

final addressBookServiceProvider =
    ChangeNotifierProvider<AddressBookService>((ref) => AddressBookService());
