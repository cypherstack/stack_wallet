import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/notifications/campfire_alert.dart';
import 'package:stackwallet/pages/settings_view/settings_subviews/wallet_settings_view.dart';
import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_button.dart';

class WalletSettingsViewBot {
  final WidgetTester tester;

  const WalletSettingsViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(WalletSettingsView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byKey(Key("settingsAppBarBackButton")));
    await tester.pumpAndSettle();
  }

  Future<void> tapChangePIN() async {
    await tester.tap(find.byKey(Key("walletSettingsChangePinButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapToggleBiometrics() async {
    await tester
        .tap(find.byKey(Key("walletSettingsEnableBiometricsButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCancelBiometricsSystemSettingsDialog() async {
    await tester.tap(find.byType(SimpleButton));
    await tester.pumpAndSettle();
  }

  Future<void> tapRenameWallet() async {
    await tester.tap(find.byKey(Key("walletSettingsRenameWalletButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapDeleteWallet() async {
    await tester.tap(find.byKey(Key("walletSettingsDeleteWalletButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapFullRescan() async {
    await tester.tap(find.byKey(Key("walletSettingsFullRescanButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCancelDeleteConfirmationDialog() async {
    expect(find.byType(ConfirmationDialog), findsOneWidget);
    expect(find.text("CANCEL"), findsOneWidget);
    expect(find.text("DELETE"), findsOneWidget);
    expect(find.textContaining("Do you want to delete "), findsOneWidget);
    await tester.tap(find.byType(SimpleButton));
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmationDialog), findsNothing);
  }

  Future<void> tapDeleteOnDeleteConfirmationDialog() async {
    expect(find.byType(ConfirmationDialog), findsOneWidget);
    expect(find.text("CANCEL"), findsOneWidget);
    expect(find.text("DELETE"), findsOneWidget);
    expect(find.textContaining("Do you want to delete "), findsOneWidget);
    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmationDialog), findsNothing);
  }

  Future<void> tapCancelRescanConfirmationDialog() async {
    expect(find.byType(ConfirmationDialog), findsOneWidget);
    expect(find.text("CANCEL"), findsOneWidget);
    expect(find.text("RESCAN"), findsOneWidget);
    expect(find.text("Are you sure you want to do a full rescan?"),
        findsOneWidget);
    await tester.tap(find.byType(SimpleButton));
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmationDialog), findsNothing);
  }

  Future<void> tapRescanOnRescanConfirmationDialog() async {
    expect(find.byType(ConfirmationDialog), findsOneWidget);
    expect(find.text("CANCEL"), findsOneWidget);
    expect(find.text("RESCAN"), findsOneWidget);
    expect(find.text("Are you sure you want to do a full rescan?"),
        findsOneWidget);
    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmationDialog), findsNothing);
  }

  Future<void> tapClearCache() async {
    await tester
        .tap(find.byKey(Key("walletSettingsClearSharedCacheButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCancelClearCache() async {
    expect(find.byType(ConfirmationDialog), findsOneWidget);
    expect(find.text("CANCEL"), findsOneWidget);
    expect(find.text("CLEAR"), findsOneWidget);
    expect(
        find.textContaining(
            "Are you sure you want to clear all shared cached "),
        findsOneWidget);
    await tester.tap(find.byType(SimpleButton));
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmationDialog), findsNothing);
  }

  Future<void> tapClearOnClearCache() async {
    expect(find.byType(ConfirmationDialog), findsOneWidget);
    expect(find.text("CANCEL"), findsOneWidget);
    expect(find.text("CLEAR"), findsOneWidget);
    expect(
        find.textContaining(
            "Are you sure you want to clear all shared cached "),
        findsOneWidget);
    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmationDialog), findsNothing);
  }

  Future<void> tapOkOnCacheClearedAlert() async {
    expect(find.byType(CampfireAlert), findsOneWidget);
    expect(find.text("Transaction cache cleared!"), findsOneWidget);
    expect(find.text("OK"), findsOneWidget);
    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();
    expect(find.byType(CampfireAlert), findsNothing);
  }
}
