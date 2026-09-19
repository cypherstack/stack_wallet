import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/pinpad_views/lock_screen_view.dart';
import 'package:stackwallet/providers/global/duress_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/biometrics.dart';
import 'package:stackwallet/widgets/custom_pin_put/pin_keyboard.dart';

import '../sample_data/theme_json.dart';
import '../widget_tests/custom_loading_overlay_test.mocks.dart';
import '../widget_tests/node_options_sheet_test.mocks.dart';
import '../widget_tests/support/platform_test_overrides.dart';

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
    when(prefs.isInitialized).thenReturn(true);
    when(prefs.randomizePIN).thenReturn(false);
    when(prefs.autoPin).thenReturn(false);
    when(prefs.useBiometrics).thenReturn(false);
    when(prefs.biometricsDuress).thenReturn(false);
    when(prefs.lastUnlocked).thenReturn(0);
  }

  Future<ProviderContainer> pumpLockscreenView(
    WidgetTester tester, {
    required MockPrefs prefs,
    required SpyBiometrics biometrics,
    required List<Override> overrides,
    required bool isDuress,
    VoidCallback? onSuccess,
  }) async {
    final mockThemeService = MockThemeService();
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);

    when(mockThemeService.getTheme(themeId: 'light')).thenReturn(theme);

    final container = ProviderContainer(
      overrides: [
        pThemeService.overrideWithValue(mockThemeService),
        prefsChangeNotifierProvider.overrideWithValue(prefs),
        ...overrides,
      ],
    );

    addTearDown(container.dispose);
    container.read(pDuress.notifier).state = isDuress;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildTheme(),
          routes: {
            '/unlocked': (_) => const Scaffold(body: Text('unlocked route')),
          },
          home: LockscreenView(
            routeOnSuccess: '/unlocked',
            biometricsAuthenticationTitle: 'Unlock wallet',
            biometricsLocalizedReason: 'Unlock Stack Wallet',
            biometricsCancelButtonString: 'Cancel',
            biometrics: biometrics,
            onSuccess: onSuccess,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tapDigit(WidgetTester tester, String digit) async {
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == digit,
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
  }

  Future<void> enterAndSubmitPin(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tapDigit(tester, digit);
    }

    await tester.tap(find.byType(SubmitKey));
    await tester.pump();
  }

  testWidgets('valid standard PIN unlocks through fake storage seam', (
    tester,
  ) async {
    final prefs = MockPrefs();
    final biometrics = SpyBiometrics();
    final platformOverrides = await createPlatformTestOverrides(
      secureStorageEntries: {kPinKey: '1234', kDuressPinKey: '9876'},
    );
    var onSuccessCalls = 0;

    stubPrefs(prefs);

    await pumpLockscreenView(
      tester,
      prefs: prefs,
      biometrics: biometrics,
      overrides: platformOverrides.overrides,
      isDuress: false,
      onSuccess: () => onSuccessCalls += 1,
    );

    expect(find.text('Enter PIN'), findsOneWidget);
    expect(
      platformOverrides.secureStorage.writtenKeys,
      containsAll(<String>[kPinKey, kDuressPinKey]),
    );

    await enterAndSubmitPin(tester, '1234');
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(platformOverrides.secureStorage.readKeys, <String>[kPinKey]);
    expect(platformOverrides.secureStorage.reads, 1);
    expect(onSuccessCalls, 1);
    expect(biometrics.calls, 0);
    expect(find.text('unlocked route'), findsOneWidget);

    verify(prefs.lastUnlocked = any).called(1);
  });

  testWidgets('duress mode unlocks with the duress PIN only', (tester) async {
    final prefs = MockPrefs();
    final biometrics = SpyBiometrics();
    final platformOverrides = await createPlatformTestOverrides(
      secureStorageEntries: {kPinKey: '1234', kDuressPinKey: '9876'},
    );
    var onSuccessCalls = 0;

    stubPrefs(prefs);

    final container = await pumpLockscreenView(
      tester,
      prefs: prefs,
      biometrics: biometrics,
      overrides: platformOverrides.overrides,
      isDuress: true,
      onSuccess: () => onSuccessCalls += 1,
    );

    await enterAndSubmitPin(tester, '9876');
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(platformOverrides.secureStorage.readKeys, <String>[kDuressPinKey]);
    expect(platformOverrides.secureStorage.reads, 1);
    expect(container.read(pDuress), isTrue);
    expect(onSuccessCalls, 1);
    expect(biometrics.calls, 0);
    expect(find.text('unlocked route'), findsOneWidget);

    verify(prefs.lastUnlocked = any).called(1);
  });

  testWidgets('duress mode rejects the standard PIN without unlocking', (
    tester,
  ) async {
    final prefs = MockPrefs();
    final biometrics = SpyBiometrics();
    final platformOverrides = await createPlatformTestOverrides(
      secureStorageEntries: {kPinKey: '1234', kDuressPinKey: '9876'},
    );
    var onSuccessCalls = 0;

    stubPrefs(prefs);

    final container = await pumpLockscreenView(
      tester,
      prefs: prefs,
      biometrics: biometrics,
      overrides: platformOverrides.overrides,
      isDuress: true,
      onSuccess: () => onSuccessCalls += 1,
    );

    await enterAndSubmitPin(tester, '1234');
    await tester.pump(const Duration(milliseconds: 900));

    expect(platformOverrides.secureStorage.readKeys, <String>[kDuressPinKey]);
    expect(platformOverrides.secureStorage.reads, 1);
    expect(container.read(pDuress), isTrue);
    expect(onSuccessCalls, 0);
    expect(biometrics.calls, 0);
    expect(find.text('Enter PIN'), findsOneWidget);
    expect(find.text('unlocked route'), findsNothing);

    verifyNever(prefs.lastUnlocked = any);
  });
}
