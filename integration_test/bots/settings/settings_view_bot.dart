import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/settings_view/settings_view.dart';

class SettingsViewBot {
  final WidgetTester tester;

  const SettingsViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(SettingsView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byKey(Key("settingsAppBarBackButton")));
    await tester.pumpAndSettle();
  }

  Future<void> tapLogout() async {
    await tester.tap(find.byKey(Key("settingsLogoutAppBarButton")));
    await tester.pumpAndSettle();
  }

  Future<void> tapAddressBook() async {
    await tester.tap(find.byKey(Key("settingsOptionAddressBook")));
    await tester.pumpAndSettle();
  }

  Future<void> tapNetwork() async {
    await tester.tap(find.byKey(Key("settingsOptionNetwork")));
    await tester.pumpAndSettle();
  }

  Future<void> tapWalletBackup() async {
    await tester.tap(find.byKey(Key("settingsOptionWalletBackup")));
    await tester.pumpAndSettle();
  }

  Future<void> tapWalletSettings() async {
    await tester.tap(find.byKey(Key("settingsOptionWalletSettings")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCurrency() async {
    await tester.tap(find.byKey(Key("settingsOptionCurrency")));
    await tester.pumpAndSettle();
  }
}
