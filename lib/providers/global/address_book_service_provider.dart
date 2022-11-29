import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/services/address_book_service.dart';

final addressBookServiceProvider =
    ChangeNotifierProvider<AddressBookService>((ref) => AddressBookService());
