import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/widgets/sensitive_wallet_content.dart';

void main() {
  String semantics(WidgetTester tester) => tester
      .binding
      .renderViews
      .single
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!
      .toStringDeep();

  tearDown(() => SensitiveWalletContent.hostFiltered = false);

  final android = TargetPlatformVariant.only(TargetPlatform.android);

  testWidgets('hides sensitive content but not the rest of the page', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('Wallet backup'),
              SensitiveWalletContent(child: SelectableText('test-secret-key')),
              SensitiveWalletContent(
                sensitive: false,
                child: Text('public-address'),
              ),
              TextButton(onPressed: null, child: Text('Done')),
            ],
          ),
        ),
      ),
    );
    final tree = semantics(tester);
    expect(tree, isNot(contains('test-secret-key')));
    expect(tree, contains('Hidden from accessibility services'));
    expect(tree, contains('Wallet backup'));
    expect(tree, contains('public-address'));
    expect(tree, contains('Done'));
    expect(find.text('test-secret-key'), findsOneWidget);
  }, variant: android);

  testWidgets('hides edited input values', (tester) async {
    final controller = TextEditingController(text: 'test-seed-before');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SensitiveWalletContent(
            child: TextField(controller: controller, autofocus: true),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(semantics(tester), isNot(contains('test-seed-before')));
    await tester.enterText(find.byType(TextField), 'test-seed-after');
    await tester.pump();
    expect(controller.text, 'test-seed-after');
    expect(semantics(tester), isNot(contains('test-seed-after')));
  }, variant: android);

  testWidgets('toggling sensitive keeps the input state', (tester) async {
    Widget build(bool sensitive) => MaterialApp(
      home: Scaffold(
        body: SensitiveWalletContent(
          sensitive: sensitive,
          child: TextField(obscureText: !sensitive),
        ),
      ),
    );
    await tester.pumpWidget(build(false));
    await tester.enterText(find.byType(TextField), 'test-password');
    final state = tester.state(find.byType(EditableText));
    await tester.pumpWidget(build(true));
    expect(tester.state(find.byType(EditableText)), same(state));
    expect(semantics(tester), isNot(contains('test-password')));
  }, variant: android);

  testWidgets('no-op when the Android host is filtered', (tester) async {
    SensitiveWalletContent.hostFiltered = true;
    await tester.pumpWidget(
      const MaterialApp(
        home: SensitiveWalletContent(child: Text('test-secret')),
      ),
    );
    expect(semantics(tester), contains('test-secret'));
  }, variant: android);

  testWidgets('no-op off Android', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SensitiveWalletContent(child: Text('test-secret')),
      ),
    );
    expect(semantics(tester), contains('test-secret'));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
