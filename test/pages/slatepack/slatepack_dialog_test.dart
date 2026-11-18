import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/pages/slatepack/slatepack_dialog.dart';
import 'package:stackwallet/pages/slatepack/slatepack_popup.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/slatepack_terms.dart';
import 'package:stackwallet/utilities/util.dart';

import '../../sample_data/theme_json.dart';

void main() {
  test('slatepack text uses a platform-native monospace family', () {
    expect(slatepackMonospaceFontFamily(TargetPlatform.iOS), 'Menlo');
    expect(slatepackMonospaceFontFamily(TargetPlatform.macOS), 'Menlo');
    expect(slatepackMonospaceFontFamily(TargetPlatform.windows), 'Consolas');
    expect(slatepackMonospaceFontFamily(TargetPlatform.android), 'monospace');
    expect(slatepackMonospaceFontFamily(TargetPlatform.fuchsia), 'monospace');
    expect(slatepackMonospaceFontFamily(TargetPlatform.linux), 'monospace');
  });

  test("uses a coin-specific file name", () {
    const slate = SlatepackDialog(
      terms: SlatepackTerms.slate,
      slatepack: '{}',
      state: SlateState.s1,
      slateId: "epic-id",
    );
    const slatepack = SlatepackDialog(
      terms: SlatepackTerms.slatepack,
      slatepack: "BEGINSLATEPACK. test. ENDSLATEPACK.",
      state: SlateState.s2,
      slateId: "mwc-id",
    );
    const unnamedSlate = SlatepackDialog(
      terms: SlatepackTerms.slate,
      slatepack: '{}',
      state: SlateState.unknown,
    );

    expect(slate.fileName, "epic-id.S1.slate");
    expect(slatepack.fileName, "mwc-id.S2.slatepack");
    expect(unnamedSlate.fileName, "slate.slate");
  });

  test("uses coin-specific screen wording", () {
    const slate = SlatepackDialog(
      terms: SlatepackTerms.slate,
      slatepack: '{}',
      state: SlateState.s1,
    );
    const slatepack = SlatepackDialog(
      terms: SlatepackTerms.slatepack,
      slatepack: "BEGINSLATEPACK. test. ENDSLATEPACK.",
      state: SlateState.s1,
    );

    expect(slate.instructions, contains("on the Slate screen"));
    expect(slate.instructions, isNot(contains("Slatepack screen")));
    expect(slatepack.instructions, contains("on the Slatepack screen"));
  });

  testWidgets("Share anchors the share sheet to the Share button", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Share is only offered on the phone layout.
    final previousWidth = Util.screenWidth;
    Util.screenWidth = 400;
    addTearDown(() => Util.screenWidth = previousWidth);

    const channel = MethodChannel("dev.fluttercommunity.plus/share");
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return "";
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: const Scaffold(
            body: SlatepackDialog(
              terms: SlatepackTerms.slate,
              slatepack: '{"slate": true}',
              state: SlateState.s1,
              slateId: "test-slate",
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Share"));
    await tester.pump();

    expect(calls, hasLength(1));
    final args = calls.single.arguments as Map;
    expect(args["text"], '{"slate": true}');
    final origin = Rect.fromLTWH(
      args["originX"] as double,
      args["originY"] as double,
      args["originWidth"] as double,
      args["originHeight"] as double,
    );
    expect(origin.isEmpty, isFalse);
    expect(origin.contains(tester.getCenter(find.text("Share"))), isTrue);
    expect(
      (Offset.zero & tester.view.physicalSize).contains(origin.topLeft),
      isTrue,
    );
  });

  testWidgets('actions fit at 360 dp with 115 percent text', (tester) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previousWidth = Util.screenWidth;
    Util.screenWidth = 360;
    addTearDown(() => Util.screenWidth = previousWidth);

    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.15)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSlatepackPopup<void>(
                  context: context,
                  child: const SlatepackDialog(
                    terms: SlatepackTerms.slatepack,
                    slatepack: 'BEGINSLATEPACK. test. ENDSLATEPACK.',
                    state: SlateState.s1,
                    slateId: 'test-slate',
                  ),
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
