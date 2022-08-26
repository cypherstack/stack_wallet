import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/settings_view/settings_subviews/network_settings_subviews/node_details_view.dart';
import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_button.dart';

class NodeDetailsViewBot {
  final WidgetTester tester;

  const NodeDetailsViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(NodeDetailsView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byKey(Key("nodeDetailsViewBackButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapMore() async {
    await tester.tap(find.byKey(Key("nodeDetailsViewMoreButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapMoreAndEdit() async {
    await tapMore();
    await tester.tap(find.text("Edit node"));
    await tester.pumpAndSettle();
  }

  Future<void> tapMoreAndDelete() async {
    await tapMore();
    await tester.tap(find.text("Delete node"));
    await tester.pumpAndSettle();
  }

  Future<void> tapCancelDelete() async {
    await tester
        .tap(find.byKey(Key("nodeDetailsConfirmDeleteCancelButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapConfirmDelete() async {
    await tester
        .tap(find.byKey(Key("nodeDetailsConfirmDeleteConfirmButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> enterName(String name) async {
    await tester.enterText(find.byKey(Key("editNodeNodeNameFieldKey")), name);
    await tester.pump();
  }

  Future<void> enterAddress(String address) async {
    await tester.enterText(find.byKey(Key("editNodeAddressFieldKey")), address);
    await tester.pump();
  }

  Future<void> enterPort(String port) async {
    await tester.enterText(find.byKey(Key("editNodeNodePortFieldKey")), port);
    await tester.pump();
  }

  Future<void> tapUseSSLCheckbox() async {
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
  }

  Future<void> tapTestConnection() async {
    await tester.tap(find.byType(SimpleButton));
    await tester.pump(Duration(milliseconds: 500));
  }

  Future<void> tapSave() async {
    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();
  }
}
