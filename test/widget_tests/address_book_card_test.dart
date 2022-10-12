import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/contact.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/services/address_book_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/address_book_card.dart';

import 'address_book_card_test.mocks.dart';

@GenerateMocks([AddressBookService])
void main() {
  testWidgets('test returns Contact Address Entry', (widgetTester) async {
    final service = MockAddressBookService();
    when(service.getContactById("some id"))
        .thenAnswer((realInvocation) => Contact(
            name: "John Doe",
            addresses: [
              const ContactAddressEntry(
                  coin: Coin.bitcoincash,
                  address: "some bch address",
                  label: "Bills")
            ],
            isFavorite: true));

    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [
          addressBookServiceProvider.overrideWithValue(
            service,
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                LightColors(),
              ),
            ],
          ),
          home: const AddressBookCard(
            contactId: "some id",
          ),
        ),
      ),
    );

    expect(find.text("John Doe"), findsOneWidget);
  });
}
