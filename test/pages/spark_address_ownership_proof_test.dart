import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/db/drift/database.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/signing/signing_view.dart';
import 'package:stackwallet/pages/signing/sub_widgets/sign_message_tab.dart';
import 'package:stackwallet/pages/signing/sub_widgets/verify_message_tab.dart';
import 'package:stackwallet/pages/spark_names/sub_widgets/spark_name_details.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart'
    show IconCopyButton;
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/db/drift_provider.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/firo_wallet.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/dialogs/s_dialog.dart';

import '../sample_data/theme_json.dart';

class _ProofWallet extends FiroWallet {
  _ProofWallet() : super(CryptoCurrencyNetwork.main);
  String? signedMessage;
  bool viewOnly = false;
  @override
  bool get isViewOnly => viewOnly;
  @override
  Future<String> createSparkAddressOwnershipProof({
    required String address,
    required String message,
  }) async {
    signedMessage = message;
    return 'ab' * 130;
  }
}

class _Wallets extends Mock implements Wallets {
  final wallet = _ProofWallet();
  @override
  FiroWallet getWallet(String walletId) => wallet;
}

class _LabelDB extends Mock implements MainDB {
  @override
  AddressLabel? getAddressLabelSync(String walletId, String address) => null;
}

void main() {
  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('spark-proof-ui-');
    StackFileSystem.setDesktopOverrideDir(directory.path);
    addTearDown(() => directory.delete(recursive: true));
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => directory.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final font = FontLoader('Inter_500');
    font.addFont(rootBundle.load('google_fonts/Inter-Medium.ttf'));
    await font.load();
  });

  for (final desktop in [false, true]) {
    testWidgets(
      '${desktop ? "desktop" : "mobile"} proof layout and exact message',
      (tester) async {
        final oldWidth = Util.screenWidth;
        Util.screenWidth = desktop ? 1000 : 390;
        addTearDown(() => Util.screenWidth = oldWidth);
        await tester.binding.setSurfaceSize(
          Size(desktop ? 1000 : 390, desktop ? 600 : 844),
        );
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final wallets = _Wallets();
        final view = SparkAddressOwnershipProofView(
          walletId: 'test',
          address: 'sm1${'a' * 141}',
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              pWallets.overrideWithValue(wallets),
              themeProvider.overrideWithValue(
                StateController(StackTheme.fromJson(json: lightThemeJsonMap)),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(
                extensions: [
                  StackColors.fromStackColorTheme(
                    StackTheme.fromJson(json: lightThemeJsonMap),
                  ),
                ],
              ),
              onGenerateRoute: RouteGenerator.generateRoute,
              home: desktop
                  ? SDialog(child: view)
                  : Builder(
                      builder: (context) => Scaffold(
                        body: TextButton(
                          onPressed: () => Navigator.of(context).pushNamed(
                            SparkAddressOwnershipProofView.routeName,
                            arguments: (
                              walletId: view.walletId,
                              address: view.address,
                            ),
                          ),
                          child: const Text('Open proof'),
                        ),
                      ),
                    ),
            ),
          ),
        );
        if (!desktop) {
          await tester.tap(find.text('Open proof'));
          await tester.pumpAndSettle();
        }
        expect(find.byType(AppBar), desktop ? findsNothing : findsOneWidget);
        expect(
          find.byType(DesktopDialogCloseButton),
          desktop ? findsOneWidget : findsNothing,
        );
        final field = find.byType(TextField);
        expect(
          tester.widget<TextField>(field).smartDashesType,
          SmartDashesType.disabled,
        );
        expect(
          tester.widget<TextField>(field).smartQuotesType,
          SmartQuotesType.disabled,
        );
        await tester.enterText(field, ' \n\t');
        await tester.pump();
        expect(
          tester.widget<PrimaryButton>(find.byType(PrimaryButton)).enabled,
          isFalse,
        );
        const message = ' challenge\n ';
        await tester.enterText(field, message);
        await tester.pump();
        await tester.ensureVisible(find.text('Create proof'));
        await tester.tap(find.text('Create proof'));
        await tester.pumpAndSettle();
        expect(wallets.wallet.signedMessage, message);
        expect(
          find.byType(IconCopyButton),
          desktop ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(SimpleCopyButton),
          desktop ? findsNothing : findsOneWidget,
        );
        await tester.enterText(field, 'changed');
        await tester.pump();
        expect(find.text('ab' * 130), findsNothing);
        expect(tester.takeException(), isNull);
        if (!desktop) {
          await tester.tap(find.byType(AppBarBackButton));
          await tester.pumpAndSettle();
          expect(find.text('Open proof'), findsOneWidget);
          expect(find.byType(SparkAddressOwnershipProofView), findsNothing);
        }
      },
    );
  }

  for (final ipad in [false, true]) {
    testWidgets('ownership action layout on ${ipad ? "iPad" : "small phone"}', (
      tester,
    ) async {
      final oldWidth = Util.screenWidth;
      final oldIpad = Util.isIpad;
      Util.screenWidth = ipad ? 1024 : 320;
      Util.isIpad = ipad;
      addTearDown(() {
        Util.screenWidth = oldWidth;
        Util.isIpad = oldIpad;
      });
      final size = Size(ipad ? 1024 : 320, ipad ? 768 : 568);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final walletId = 'proof-layout-$ipad';
      final db = (await tester.runAsync(() async {
        final db = Drift.get(walletId);
        await db.customSelect('SELECT 1').get();
        return db;
      }))!;
      addTearDown(db.close);
      try {
        final theme = StackTheme.fromJson(json: lightThemeJsonMap);
        final view = SparkNameDetailsView(
          walletId: walletId,
          name: SparkName(
            name: 'example',
            address: 'sm1${'a' * 141}',
            validUntil: 10000,
          ),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              pWallets.overrideWithValue(_Wallets()),
              mainDBProvider.overrideWithValue(_LabelDB()),
              pDrift(walletId).overrideWithValue(db),
              pWalletChainHeight(walletId).overrideWithValue(0),
              themeProvider.overrideWithValue(StateController(theme)),
            ],
            child: MaterialApp(
              theme: ThemeData(
                extensions: [StackColors.fromStackColorTheme(theme)],
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(minimumSize: const Size(46, 48)),
                ),
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: size,
                  textScaler: TextScaler.linear(ipad ? 1 : 1.5),
                ),
                child: child!,
              ),
              onGenerateRoute: RouteGenerator.generateRoute,
              home: ipad ? SDialog(child: view) : view,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final action = find.text('Prove address ownership');
        await tester.ensureVisible(action);
        expect(tester.takeException(), isNull);
        await tester.tap(action);
        await tester.pumpAndSettle();
        if (ipad) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 350);
          await tester.pumpAndSettle();
        }
        await tester.enterText(find.byType(TextField), 'challenge');
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Create proof'));
        expect(
          tester.getRect(find.text('Create proof')).bottom,
          lessThanOrEqualTo(size.height - (ipad ? 350 : 0)),
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('view-only wallet exposes verification without signing', (
    tester,
  ) async {
    final wallets = _Wallets();
    wallets.wallet.viewOnly = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(wallets),
          themeProvider.overrideWithValue(
            StateController(StackTheme.fromJson(json: lightThemeJsonMap)),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(json: lightThemeJsonMap),
              ),
            ],
          ),
          home: const Scaffold(body: SigningView(walletId: 'test')),
        ),
      ),
    );
    expect(find.byType(VerifyMessageForm), findsOneWidget);
    expect(find.byType(SignMessageForm), findsNothing);
    expect(find.text('Sign message'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
