import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/services/address_book_service.dart';

class MockedFunctions extends Mock {
  void showDialog();
}

@GenerateMocks([AddressBookService])
void main() {
  // testWidgets('test returns Contact Address Entry', (widgetTester) async {
  //   final service = MockAddressBookService();
  //
  //   when(service.getContactById("default"))
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
  //           contactId: "default",
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   expect(find.text("John Doe"), findsOneWidget);
  //   expect(find.text("BCH"), findsOneWidget);
  //   expect(find.text(Coin.bitcoincash.ticker), findsOneWidget);
  //
  //   await widgetTester.tap(find.byType(RawMaterialButton));
  // });
}
