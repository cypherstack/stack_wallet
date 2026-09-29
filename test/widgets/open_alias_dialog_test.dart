import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/services/openalias/open_alias.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/open_alias_dialog.dart';

import '../sample_data/theme_json.dart';

const recipient = OpenAliasRecipient(
  domain: 'alice.example',
  address: 'full-monero-address',
);

Future<void> open(
  WidgetTester tester,
  Future<OpenAliasRecipient> Function(String) resolve,
  void Function(OpenAliasRecipient?) accepted,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        extensions: [
          StackColors.fromStackColorTheme(
            StackTheme.fromJson(json: lightThemeJsonMap),
          ),
        ],
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              accepted(
                await showDialog<OpenAliasRecipient>(
                  context: context,
                  builder: (_) => OpenAliasDialog(resolve: resolve),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets('explicit lookup and full address acceptance at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Util.isDesktop is false on Linux below 800 logical pixels.
      Util.screenWidth = size.width;
      addTearDown(() => Util.screenWidth = null);
      var calls = 0;
      OpenAliasRecipient? accepted;
      await open(tester, (_) async {
        calls++;
        return recipient;
      }, (r) => accepted = r);
      await tester.enterText(
        find.byKey(const Key('openAliasInput')),
        'alice.example',
      );
      await tester.pump();
      expect(calls, 0);
      await tester.tap(find.text('Look up'));
      await tester.pumpAndSettle();
      expect(find.text('full-monero-address'), findsOneWidget);
      expect(accepted, isNull);
      await tester.tap(find.text('Use address'));
      await tester.pumpAndSettle();
      expect(accepted, same(recipient));
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('edits discard late results and prevent acceptance', (
    tester,
  ) async {
    final pending = Completer<OpenAliasRecipient>();
    await open(tester, (_) => pending.future, (_) {});
    await tester.enterText(
      find.byKey(const Key('openAliasInput')),
      'alice.example',
    );
    await tester.tap(find.text('Look up'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('openAliasInput')),
      'bob.example',
    );
    pending.complete(recipient);
    await tester.pumpAndSettle();
    expect(find.text('Use address'), findsNothing);
    expect(find.text('full-monero-address'), findsNothing);
  });
  testWidgets('editing a verified alias invalidates acceptance', (
    tester,
  ) async {
    await open(tester, (_) async => recipient, (_) {});
    await tester.enterText(
      find.byKey(const Key('openAliasInput')),
      'alice.example',
    );
    await tester.tap(find.text('Look up'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('openAliasInput')),
      'bob.example',
    );
    await tester.pump();
    expect(find.text('Use address'), findsNothing);
  });
  testWidgets('moving the cursor does not discard a verified result', (
    tester,
  ) async {
    await open(tester, (_) async => recipient, (_) {});
    await tester.enterText(
      find.byKey(const Key('openAliasInput')),
      'alice.example',
    );
    await tester.tap(find.text('Look up'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openAliasInput')));
    await tester.pump();
    expect(find.text('Use address'), findsOneWidget);
  });
  testWidgets('failed verification remains visible without an accept action', (
    tester,
  ) async {
    await open(
      tester,
      (_) async => throw const OpenAliasException('DNSSEC failed'),
      (_) {},
    );
    await tester.enterText(
      find.byKey(const Key('openAliasInput')),
      'alice.example',
    );
    await tester.tap(find.text('Look up'));
    await tester.pumpAndSettle();
    expect(find.text('DNSSEC failed'), findsOneWidget);
    expect(find.text('Use address'), findsNothing);
  });
  testWidgets('cancel during lookup does not update a disposed dialog', (
    tester,
  ) async {
    final pending = Completer<OpenAliasRecipient>();
    OpenAliasRecipient? accepted;
    await open(tester, (_) => pending.future, (r) => accepted = r);
    await tester.enterText(
      find.byKey(const Key('openAliasInput')),
      'alice.example',
    );
    await tester.tap(find.text('Look up'));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    pending.complete(recipient);
    await tester.pumpAndSettle();
    expect(accepted, isNull);
    expect(tester.takeException(), isNull);
  });
}
