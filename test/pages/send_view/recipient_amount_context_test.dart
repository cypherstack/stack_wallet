import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/send_view/frost_ms/recipient.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import '../../sample_data/theme_json.dart';

class _TestMonero extends Monero {
  _TestMonero() : super(CryptoCurrencyNetwork.main);
  @override
  bool validateAddress(String address) => address.startsWith("address");
}

class _Locale extends LocaleService {
  String _locale = "en_US";
  @override
  String get locale => _locale;
  void setLocale(String l) {
    _locale = l;
    notifyListeners();
  }
}

void main() {
  final coin = _TestMonero();
  const RecipientId id = (walletId: "wallet", index: 1);
  Amount xmr(String v) =>
      Amount.tryParseCanonicalAmount(v, fractionDigits: coin.fractionDigits)!;

  for (final unitFirst in [false, true]) {
    testWidgets('recipient same-frame unit+locale unitFirst=$unitFirst', (
      tester,
    ) async {
      final prev = Util.layoutPlatform;
      Util.layoutPlatform = platform.FakePlatform(operatingSystem: "android");
      addTearDown(() => Util.layoutPlatform = prev);
      final unit = StateProvider((_) => AmountUnit.normal);
      final locale = _Locale();
      final container = ProviderContainer(
        overrides: [
          pAmountUnit.overrideWithProvider(
            (_) => Provider((ref) => ref.watch(unit)),
          ),
          pMaxDecimals.overrideWithProvider(
            (coin) => Provider((_) => coin.fractionDigits),
          ),
          localeServiceChangeNotifierProvider.overrideWithValue(locale),
        ],
      );
      addTearDown(container.dispose);
      container.read(pRecipient(id).notifier).state = (
        address: "address0",
        amount: xmr("1.2501"),
        label: null,
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                StackColors.fromStackColorTheme(
                  StackTheme.fromJson(json: lightThemeJsonMap),
                ),
              ],
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Recipient(
                  walletId: id.walletId,
                  index: id.index,
                  displayNumber: 1,
                  coin: coin,
                  remove: () {},
                  addAnotherRecipientTapped: () {},
                  sendAllTapped: () => "",
                ),
              ),
            ),
          ),
        ),
      );
      final amountField = find.byKey(
        const Key("amountInputFieldCryptoTextFieldKey"),
      );
      final addressField = find.byKey(const Key("sendViewAddressFieldKey"));
      String text() => tester.widget<TextField>(amountField).controller!.text;
      expect(text(), "1.2501");

      if (unitFirst) {
        container.read(unit.notifier).state = AmountUnit.milli;
        locale.setLocale("de_DE");
      } else {
        locale.setLocale("de_DE");
        container.read(unit.notifier).state = AmountUnit.milli;
      }
      await tester.pump();
      await tester.pump();
      expect(text(), "1250,1");
      expect(container.read(pRecipient(id))?.amount, xmr("1.2501"));

      await tester.enterText(addressField, "address1");
      await tester.pump();
      expect(container.read(pRecipient(id))?.amount, xmr("1.2501"));
    });
  }
}
