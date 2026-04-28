import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/pages/pinpad_views/create_pin_view.dart';
import 'package:stackwallet/pages/pinpad_views/lock_screen_view.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/biometrics.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/widgets/custom_pin_put/pin_keyboard.dart';

import '../../sample_data/theme_json.dart';
import '../../widget_tests/custom_loading_overlay_test.mocks.dart';
import '../../widget_tests/node_options_sheet_test.mocks.dart';
import '../../widget_tests/support/platform_test_overrides.dart';

class SpyBiometrics extends Biometrics {
  SpyBiometrics({this.result = false});

  final bool result;
  int calls = 0;

  @override
  Future<bool> authenticate({
    required String cancelButtonText,
    required String localizedReason,
    required String title,
  }) async {
    calls += 1;
    return result;
  }
}

void main() {
  ThemeData buildTheme() {
    return ThemeData(
      extensions: [
        StackColors.fromStackColorTheme(
          StackTheme.fromJson(json: lightThemeJsonMap),
        ),
      ],
    );
  }

  void stubPrefs(MockPrefs prefs) {
    when(prefs.randomizePIN).thenReturn(false);
    when(prefs.hasPin).thenReturn(false);
  }

  Future<void> pumpCreatePinView(
    WidgetTester tester, {
    required MockPrefs prefs,
    required SpyBiometrics biometrics,
    required List<Override> overrides,
  }) async {
    final mockThemeService = MockThemeService();
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);

    when(mockThemeService.getTheme(themeId: 'light')).thenReturn(theme);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pThemeService.overrideWithValue(mockThemeService),
          prefsChangeNotifierProvider.overrideWithValue(prefs),
          ...overrides,
        ],
        child: MaterialApp(
          theme: buildTheme(),
          routes: {
            HomeView.routeName: (_) => const Scaffold(body: Text('home route')),
          },
          home: CreatePinView(biometrics: biometrics),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> tapDigit(WidgetTester tester, String digit) async {
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == digit,
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
  }

  Future<void> enterPin(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tapDigit(tester, digit);
    }
  }

  Future<void> submitCurrentPin(WidgetTester tester) async {
    await tester.tap(find.byType(SubmitKey));
    await tester.pump();
  }

  testWidgets('matching PIN persists through fake secure storage seam', (
    tester,
  ) async {
    final prefs = MockPrefs();
    final biometrics = SpyBiometrics();
    final platformOverrides = await createPlatformTestOverrides();

    stubPrefs(prefs);

    await pumpCreatePinView(
      tester,
      prefs: prefs,
      biometrics: biometrics,
      overrides: platformOverrides.overrides,
    );

    expect(find.text('Create a PIN'), findsOneWidget);

    await enterPin(tester, '1234');
    await submitCurrentPin(tester);
    await tester.pumpAndSettle();

    expect(find.text('Confirm PIN'), findsOneWidget);

    await enterPin(tester, '1234');
    await submitCurrentPin(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(await platformOverrides.secureStorage.read(key: kPinKey), '1234');
    expect(platformOverrides.secureStorage.writes, 1);
    expect(biometrics.calls, 0);

    verify(prefs.useBiometrics = false).called(1);
    verify(prefs.hasPin = true).called(1);
    expect(find.text('home route'), findsOneWidget);
  });

  testWidgets('short PIN submission is blocked before confirmation page', (
    tester,
  ) async {
    final prefs = MockPrefs();
    final biometrics = SpyBiometrics();
    final platformOverrides = await createPlatformTestOverrides();

    stubPrefs(prefs);

    await pumpCreatePinView(
      tester,
      prefs: prefs,
      biometrics: biometrics,
      overrides: platformOverrides.overrides,
    );

    await enterPin(tester, '123');
    await submitCurrentPin(tester);
    await tester.pumpAndSettle();

    expect(find.text('Create a PIN'), findsOneWidget);
    expect(find.text('Confirm PIN'), findsNothing);
    expect(await platformOverrides.secureStorage.read(key: kPinKey), isNull);
    expect(platformOverrides.secureStorage.writes, 0);
    expect(biometrics.calls, 0);

    verifyNever(prefs.useBiometrics = false);
    verifyNever(prefs.hasPin = true);
  });

  testWidgets('mismatched confirmation resets flow without storage writes', (
    tester,
  ) async {
    final prefs = MockPrefs();
    final biometrics = SpyBiometrics();
    final platformOverrides = await createPlatformTestOverrides();

    stubPrefs(prefs);

    await pumpCreatePinView(
      tester,
      prefs: prefs,
      biometrics: biometrics,
      overrides: platformOverrides.overrides,
    );

    await enterPin(tester, '1234');
    await submitCurrentPin(tester);
    await tester.pumpAndSettle();

    expect(find.text('Confirm PIN'), findsOneWidget);

    await enterPin(tester, '9876');
    await submitCurrentPin(tester);
    await tester.pumpAndSettle();

    expect(find.text('Create a PIN'), findsOneWidget);
    expect(find.text('Confirm PIN'), findsNothing);
    expect(await platformOverrides.secureStorage.read(key: kPinKey), isNull);
    expect(platformOverrides.secureStorage.writes, 0);
    expect(biometrics.calls, 0);

    verifyNever(prefs.useBiometrics = false);
    verifyNever(prefs.hasPin = true);
  });
}
