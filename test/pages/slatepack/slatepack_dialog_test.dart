import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/pages/slatepack/slatepack_dialog.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/slatepack_terms.dart';
import 'package:stackwallet/utilities/util.dart';

import '../../sample_data/theme_json.dart';

void main() {
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
}
