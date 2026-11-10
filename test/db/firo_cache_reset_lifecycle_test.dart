import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/db/sqlite/firo_cache.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/models/electrumx_response/spark_models.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_wallet_features.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/more_features/more_features_dialog.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

import '../sample_data/theme_json.dart';

class _Wallet extends Mock implements Wallet {
  @override
  CryptoCurrency get cryptoCurrency => Firo(CryptoCurrencyNetwork.main);
}

class _Wallets extends Mock implements Wallets {
  @override
  Wallet getWallet(String walletId) => _Wallet();
}

class _Client extends Mock implements ElectrumXClient {
  final started = Completer<void>();
  final response = Completer<SparkAnonymitySetMeta>();

  @override
  Future<SparkAnonymitySetMeta> getSparkAnonymitySetMeta({
    String? requestID,
    required int coinGroupId,
  }) {
    started.complete();
    return response.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUpAll(() async {
    GoogleFonts.inter(fontWeight: FontWeight.w500);
    GoogleFonts.inter(fontWeight: FontWeight.w600);
    await GoogleFonts.pendingFonts();
    directory = await Directory.systemTemp.createTemp('firo-reset-dialog-');
    StackFileSystem.setDesktopOverrideDir(directory.path);
    await FiroCacheCoordinator.init();
  });
  tearDownAll(() async {
    await FiroCacheCoordinator.close();
    await directory.delete(recursive: true);
  });

  testWidgets('closing the dialog during an immediate reset is safe', (
    tester,
  ) async {
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    final container = ProviderContainer(
      overrides: [
        pWallets.overrideWithValue(_Wallets()),
        themeProvider.overrideWithValue(StateController(theme)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => MoreFeaturesDialog(
                    walletId: 'firo',
                    options: [(WalletFeature.clearSparkCache, '', () {})],
                  ),
                ),
                child: const Text('Open features'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open features'));
    await tester.pumpAndSettle();

    late _Client client;
    late Future<void> stopped;
    await tester.runAsync(() async {
      client = _Client();
      final fetch =
          FiroCacheCoordinator.runFetchAndUpdateSparkAnonSetCacheForGroupId(
            1,
            client,
            CryptoCurrencyNetwork.main,
            null,
          );
      stopped = expectLater(fetch, throwsA(isA<FiroCacheResetException>()));
      await client.started.future;
    });
    // File operations may still be in progress when the dialog is dismissed.
    final context = tester.element(find.byType(MoreFeaturesDialog));
    await tester.runAsync(() async {
      await tester.tap(find.text('Reset Spark electrumx cache'));
      Navigator.of(context).pop();
      await stopped;
      expect(
        await FiroCacheCoordinator.getUsedCoinTagsCount(
          CryptoCurrencyNetwork.main,
        ).timeout(const Duration(seconds: 3)),
        0,
      );
      expect(client.response.isCompleted, isFalse);
      client.response.complete(
        SparkAnonymitySetMeta(
          coinGroupId: 1,
          blockHash: 'block',
          setHash: 'set',
          size: 0,
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(find.byType(MoreFeaturesDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
