import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/contact.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/address_book_views/subviews/contact_popup.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/services/address_book_service.dart';
import '../sample_data/theme_json.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/address_book_card.dart';

import 'address_book_card_test.mocks.dart';

class MockedFunctions extends Mock {
  void showDialog();
}

@GenerateMocks([AddressBookService])
void main() {
  testWidgets('test returns Contact Address Entry', (widgetTester) async {
    final service = MockAddressBookService();
    final applicationThemesDirectoryPath = "";

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
                StackTheme.fromJson(
                  json: lightThemeJsonMap,
                  applicationThemesDirectoryPath:
                      applicationThemesDirectoryPath,
                ),
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
