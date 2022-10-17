import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/contact.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/pages/address_book_views/subviews/contact_popup.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/services/address_book_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/address_book_card.dart';

import 'address_book_card_test.mocks.dart';

class MockedFunctions extends Mock {
  void showDialog();
}

@GenerateMocks([AddressBookService])
void main() {
  group('Navigation tests', () {
    late AddressBookService service;
    setUp(() {
      service = MockAddressBookService();

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
    });

    testWidgets('test returns Contact Address Entry', (widgetTester) async {
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
      expect(find.text(Coin.bitcoincash.ticker), findsOneWidget);
    });

    // testWidgets("Test button press opens dialog", (widgetTester) async {
    //   // final service = MockAddressBookService();
    //
    //   when(service.getContactById("some id"))
    //       .thenAnswer((realInvocation) => Contact(
    //           name: "John Doe",
    //           addresses: [
    //             const ContactAddressEntry(
    //                 coin: Coin.bitcoincash,
    //                 address: "some bch address",
    //                 label: "Bills")
    //           ],
    //           isFavorite: true));
    //
    //   await widgetTester.pumpWidget(
    //     ProviderScope(
    //       overrides: [
    //         addressBookServiceProvider.overrideWithValue(
    //           service,
    //         ),
    //       ],
    //       child: MaterialApp(
    //         theme: ThemeData(
    //           extensions: [
    //             StackColors.fromStackColorTheme(
    //               LightColors(),
    //             ),
    //           ],
    //         ),
    //         home: const AddressBookCard(
    //           contactId: "some id",
    //         ),
    //       ),
    //     ),
    //   );
    //   //
    //   //   when(service.getContactById("03177ce0-4af4-11ed-9617-af8aa7a3796f"))
    //   //       .thenAnswer((realInvocation) => Contact(
    //   //           name: "John Doe",
    //   //           addresses: [
    //   //             const ContactAddressEntry(
    //   //                 coin: Coin.bitcoincash,
    //   //                 address: "some bch address",
    //   //                 label: "Bills")
    //   //           ],
    //   //           isFavorite: true));
    //   await widgetTester.tap(find.byType(RawMaterialButton));
    //   // verify(MockedFunctions().showDialog()).called(1);
    //   await widgetTester.pump();
    //   when(service.getContactById("03177ce0-4af4-11ed-9617-af8aa7a3796f"))
    //       .thenAnswer((realInvocation) => Contact(
    //           name: "John Doe",
    //           addresses: [
    //             const ContactAddressEntry(
    //                 coin: Coin.bitcoincash,
    //                 address: "some bch address",
    //                 label: "Bills")
    //           ],
    //           isFavorite: true));
    //
    //   expect(
    //       find.byWidget(const ContactPopUp(
    //           contactId: "03177ce0-4af4-11ed-9617-af8aa7a3796f")),
    //       findsOneWidget);
    //   // await widgetTester.pump();
    //   //   // when(contact)
    //   //   await widgetTester.pump();
    // });
  });

  // testWidgets('test returns Contact Address Entry', (widgetTester) async {
  //   // final service = MockAddressBookService();
  //   // when(service.getContactById("some id"))
  //   //     .thenAnswer((realInvocation) => Contact(
  //   //         name: "John Doe",
  //   //         addresses: [
  //   //           const ContactAddressEntry(
  //   //               coin: Coin.bitcoincash,
  //   //               address: "some bch address",
  //   //               label: "Bills")
  //   //         ],
  //   //         isFavorite: true));
  //
  //   await widgetTester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         addressBookServiceProvider.overrideWithValue(
  //           serv,
  //         ),
  //       ],
  //       child: MaterialApp(
  //         theme: ThemeData(
  //           extensions: [
  //             StackColors.fromStackColorTheme(
  //               LightColors(),
  //             ),
  //           ],
  //         ),
  //         home: const AddressBookCard(
  //           contactId: "some id",
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   expect(find.text("John Doe"), findsOneWidget);
  //   expect(find.text(Coin.bitcoincash.ticker), findsOneWidget);
  // });

  // testWidgets("Test button press opens dialog", (widgetTester) async {
  //   final service = MockAddressBookService();
  //
  //   // when(service.getContactById("some id"))
  //   //     .thenAnswer((realInvocation) => Contact(
  //   //         name: "John Doe",
  //   //         addresses: [
  //   //           const ContactAddressEntry(
  //   //               coin: Coin.bitcoincash,
  //   //               address: "some bch address",
  //   //               label: "Bills")
  //   //         ],
  //   //         isFavorite: true));
  //
  //   await widgetTester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         addressBookServiceProvider.overrideWithValue(
  //           service,
  //         ),
  //       ],
  //       child: MaterialApp(
  //         theme: ThemeData(
  //           extensions: [
  //             StackColors.fromStackColorTheme(
  //               LightColors(),
  //             ),
  //           ],
  //         ),
  //         home: const AddressBookCard(
  //           contactId: "03177ce0-4af4-11ed-9617-af8aa7a3796f",
  //         ),
  //       ),
  //     ),
  //   );
  //   //
  //   //   when(service.getContactById("03177ce0-4af4-11ed-9617-af8aa7a3796f"))
  //   //       .thenAnswer((realInvocation) => Contact(
  //   //           name: "John Doe",
  //   //           addresses: [
  //   //             const ContactAddressEntry(
  //   //                 coin: Coin.bitcoincash,
  //   //                 address: "some bch address",
  //   //                 label: "Bills")
  //   //           ],
  //   //           isFavorite: true));
  //   //   await widgetTester.tap(find.byType(RawMaterialButton));
  //   //   // when(contact)
  //   //   await widgetTester.pump();
  // });
}
