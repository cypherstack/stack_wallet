import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:epicmobile/models/contact.dart';
import 'package:epicmobile/models/contact_address_entry.dart';
import 'package:epicmobile/pages/address_book_views/subviews/contact_popup.dart';
import 'package:epicmobile/providers/global/address_book_service_provider.dart';
import 'package:epicmobile/services/address_book_service.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/theme/light_colors.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:epicmobile/widgets/address_book_card.dart';

import 'address_book_card_test.mocks.dart';

class MockedFunctions extends Mock {
  void showDialog();
}

@GenerateMocks([AddressBookService])
void main() {
  testWidgets('test returns Contact Address Entry', (widgetTester) async {
    final service = MockAddressBookService();

    when(service.getContactById("default")).thenAnswer(
      (realInvocation) => Contact(
        name: "John Doe",
        addresses: [
          const ContactAddressEntry(
              coin: Coin.bitcoincash,
              address: "some bch address",
              label: "Bills")
        ],
        isFavorite: true,
      ),
    );

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
            contactId: "default",
          ),
        ),
      ),
    );

    expect(find.text("John Doe"), findsOneWidget);
    expect(find.text("BCH"), findsOneWidget);
    expect(find.text(Coin.bitcoincash.ticker), findsOneWidget);

    if (Platform.isIOS || Platform.isAndroid) {
      await widgetTester.tap(find.byType(RawMaterialButton));
      expect(find.byType(ContactPopUp), findsOneWidget);
    } else if (Util.isDesktop) {
      expect(find.byType(RawMaterialButton), findsNothing);
    }
  });
}
