import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/settings_view/settings_subviews/network_settings_view.dart';

class NetworkSettingsViewBot {
  final WidgetTester tester;

  const NetworkSettingsViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(NetworkSettingsView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byKey(Key("settingsAppBarBackButton")));
    await tester.pumpAndSettle();
  }

  Future<void> tapAdd() async {
    await tester.tap(find.byKey(Key("networkSettingsAddNodeButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapNode(String name) async {
    await tester.tap(find.byKey(Key("networkSettingsViewNodeCard_$name")));
    await tester.pumpAndSettle();
  }
}
