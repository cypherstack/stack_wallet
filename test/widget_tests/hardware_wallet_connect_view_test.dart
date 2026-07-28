import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/hardware_wallet/hardware_wallet_connect_view.dart';
import 'package:stackwallet/providers/hardware/hardware_wallet_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/wallets/hardware/hardware_session_state.dart';

import '../sample_data/theme_json.dart';
import 'desktop/desktop_scaffold_test.mocks.dart';

void main() {
  late MockThemeService mockThemeService;
  late StackTheme stackTheme;

  setUp(() {
    mockThemeService = MockThemeService();
    stackTheme = StackTheme.fromJson(json: lightThemeJsonMap);
    when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
      (_) => stackTheme,
    );
  });

  Widget buildTestWidget({
    HardwareSessionState initialState = HardwareSessionState.idle,
  }) {
    return ProviderScope(
      overrides: [
        pThemeService.overrideWithValue(mockThemeService),
        hardwareSessionStateProvider.overrideWithProvider(
          StateProvider<HardwareSessionState>((_) => initialState),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(stackTheme),
          ],
        ),
        home: const HardwareWalletConnectView(),
      ),
    );
  }

  group('HardwareWalletConnectView', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(HardwareWalletConnectView), findsOneWidget);
    });

    testWidgets('shows family selection cards', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ledger'), findsOneWidget);
      expect(find.text('Trezor'), findsOneWidget);
      expect(find.text('Foundation'), findsOneWidget);
    });

    testWidgets('Foundation shows Coming Soon badge', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Coming Soon'), findsOneWidget);
    });

    testWidgets('shows idle state text when no family selected', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Select a device family to begin'),
        findsOneWidget,
      );
    });

    testWidgets('shows scanning state', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialState: HardwareSessionState.scanning,
      ));
      await tester.pump();

      expect(find.text('Scanning...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows timeout state with help text', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialState: HardwareSessionState.timeout,
      ));
      await tester.pump();

      expect(find.text('No devices found'), findsOneWidget);
      expect(
        find.text(
          'Check that your device is unlocked and connected via USB',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows Scan for devices button in idle state', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Scan for devices'), findsOneWidget);
    });

    testWidgets('shows Retry button in timeout state', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialState: HardwareSessionState.timeout,
      ));
      await tester.pump();

      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
