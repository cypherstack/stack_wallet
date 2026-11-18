import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/slatepack/slatepack_input_field.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/slatepack_terms.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/utilities/util.dart';

import '../../sample_data/theme_json.dart';

class _Clipboard extends Fake implements ClipboardInterface {
  final response = Completer<ClipboardData?>();

  @override
  Future<ClipboardData?> getData(String format) => response.future;
}

void main() {
  testWidgets('mobile label fits beside the input actions at 360 dp', (
    tester,
  ) async {
    final previousPlatform = Util.layoutPlatform;
    final previousWidth = Util.screenWidth;
    Util.layoutPlatform = platform.FakePlatform(operatingSystem: 'android');
    Util.screenWidth = 360;
    addTearDown(() {
      Util.layoutPlatform = previousPlatform;
      Util.screenWidth = previousWidth;
    });
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 328,
                child: SlatepackInputField(
                  controller: controller,
                  hint: 'Enter Slatepack Message',
                  terms: SlatepackTerms.slatepack,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final label = find.text('Slatepack');
    final paste = find.byKey(const Key('slatepackPasteButton'));
    expect(label, findsOneWidget);
    expect(paste, findsOneWidget);
    expect(
      tester.getRect(label).right,
      lessThanOrEqualTo(tester.getRect(paste).left),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('paste completes after the input closes', (tester) async {
    final previousThemes = StackFileSystem.themesDir;
    StackFileSystem.themesDir = Directory('test/sample_data').absolute;
    addTearDown(() => StackFileSystem.themesDir = previousThemes);
    final controller = TextEditingController();
    final clipboard = _Clipboard();
    final changes = <String>[];
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: Scaffold(
            body: SlatepackInputField(
              controller: controller,
              hint: 'Slatepack',
              terms: SlatepackTerms.slatepack,
              clipboard: clipboard,
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('slatepackPasteButton')));
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    clipboard.response.complete(const ClipboardData(text: 'slatepack'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(changes, isEmpty);
  });
}
