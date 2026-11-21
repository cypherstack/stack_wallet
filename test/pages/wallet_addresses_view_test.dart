import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/pages/receive_view/addresses/wallet_addresses_view.dart';
import 'package:stackwallet/pages/receive_view/addresses/address_tag_data.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import '../sample_data/theme_json.dart';
import '../support/isar_test_utils.dart';

void main() {
  late Directory dir;
  late Isar isar;
  late Address a, b;
  setUpAll(() async {
    await initializeTestIsar();
    dir = await Directory.systemTemp.createTemp('address-review-');
    isar = await Isar.open(
      [AddressSchema, AddressLabelSchema, TransactionSchema],
      directory: dir.path,
      name: 'review',
    );
    await MainDB.instance.initMainDB(mock: isar);
    Address address(String value, int index) => Address(
      walletId: 'wallet',
      value: value,
      publicKey: [],
      derivationIndex: index,
      derivationPath: null,
      type: AddressType.p2wpkh,
      subType: AddressSubType.receiving,
    );
    a = address('first-address', 0);
    b = address('second-address', 1);
    await isar.writeTxn(() async {
      await isar.addresses.putAll([a, b]);
    });
  });
  tearDownAll(() async {
    await isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });
  testWidgets('mobile address row follows changed address ID', (tester) async {
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    Util.screenWidth = 400;
    final ids = StreamController<List<int>>();
    addTearDown(ids.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeProvider.overrideWithValue(StateController(theme)),
          pWalletCoin('wallet')
              .overrideWithValue(Bitcoin(CryptoCurrencyNetwork.main)),
          walletAddressTagsProvider('wallet').overrideWithProvider(
            StreamProvider.autoDispose((ref) => Stream.value(<String>[])),
          ),
          filteredWalletAddressIdsProvider(
            const WalletAddressFilter(walletId: 'wallet'),
          ).overrideWithProvider(
            StreamProvider.autoDispose((ref) => ids.stream),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: const WalletAddressesView(walletId: 'wallet'),
        ),
      ),
    );
    ids.add([a.id, b.id]);
    await tester.pumpAndSettle();
    expect(find.text('first-address'), findsOneWidget);
    ids.add([b.id]);
    await tester.pumpAndSettle();
    expect(find.text('first-address'), findsNothing);
    final displayedCorrectly = find.text('second-address').evaluate().length;
    await tester.pumpWidget(const SizedBox());
    Util.screenWidth = null;
    expect(displayedCorrectly, 1);
  });
}
