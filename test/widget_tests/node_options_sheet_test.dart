import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/widgets/node_options_sheet.dart';

import '../sample_data/theme_json.dart';
import 'node_options_sheet_test.mocks.dart';

@GenerateMocks([Wallets, Prefs, NodeService, TorService])
void main() {
  testWidgets("Load Node Options widget", (tester) async {
    final mockWallets = MockWallets();
    final mockPrefs = MockPrefs();
    final mockNodeService = MockNodeService();

    when(mockNodeService.getNodeById(id: "node id"))
        .thenAnswer((realInvocation) => NodeModel(
              host: "127.0.0.1",
              port: 2000,
              name: "Some other name",
              id: "node id",
              useSSL: true,
              enabled: true,
              coinName: "Bitcoin",
              isFailover: false,
              isDown: false,
              torEnabled: true,
              clearnetEnabled: true,
            ));

    when(mockNodeService.getPrimaryNodeFor(
            currency: Bitcoin(CryptoCurrencyNetwork.main)))
        .thenAnswer((realInvocation) => NodeModel(
            host: "127.0.0.1",
            port: 2000,
            name: "Some other name",
            id: "node id",
            useSSL: true,
            enabled: true,
            coinName: "Bitcoin",
            isFailover: false,
            torEnabled: true,
            clearnetEnabled: true,
            isDown: false));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(mockWallets),
          prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
          nodeServiceChangeNotifierProvider.overrideWithValue(mockNodeService)
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(
                  json: lightThemeJsonMap,
                ),
              ),
            ],
          ),
          home: NodeOptionsSheet(
              nodeId: "node id",
              coin: Bitcoin(CryptoCurrencyNetwork.main),
              popBackToRoute: ""),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text("Node options"), findsOneWidget);
    expect(find.text("Some other name"), findsOneWidget);
    expect(find.text("Connected"), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(2));
    expect(find.text("Details"), findsOneWidget);
    expect(find.text("Connect"), findsOneWidget);

    verify(mockNodeService.getPrimaryNodeFor(
            currency: Bitcoin(CryptoCurrencyNetwork.main)))
        .called(1);
    verify(mockNodeService.getNodeById(id: "node id")).called(1);
    verify(mockNodeService.addListener(any)).called(1);
    verifyNoMoreInteractions(mockNodeService);
  });

  testWidgets("Details tap", (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final mockWallets = MockWallets();
    final mockPrefs = MockPrefs();
    final mockNodeService = MockNodeService();
    final mockTorService = MockTorService();

    when(mockNodeService.getNodeById(id: "node id")).thenAnswer(
      (_) => NodeModel(
        host: "127.0.0.1",
        port: 2000,
        name: "Stack Default",
        id: "node id",
        useSSL: true,
        enabled: true,
        coinName: "Bitcoin",
        isFailover: false,
        isDown: false,
        torEnabled: true,
        clearnetEnabled: true,
      ),
    );

    when(mockNodeService.getPrimaryNodeFor(
            currency: Bitcoin(CryptoCurrencyNetwork.main)))
        .thenAnswer(
      (_) => NodeModel(
        host: "127.0.0.1",
        port: 2000,
        name: "Stack Default",
        id: "some node id",
        useSSL: true,
        enabled: true,
        coinName: "Bitcoin",
        isFailover: false,
        isDown: false,
        torEnabled: true,
        clearnetEnabled: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(mockWallets),
          prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
          nodeServiceChangeNotifierProvider.overrideWithValue(mockNodeService),
          pTorService.overrideWithValue(mockTorService),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(
                  json: lightThemeJsonMap,
                ),
              ),
            ],
          ),
          onGenerateRoute: (settings) {
            if (settings.name == '/nodeDetails') {
              return MaterialPageRoute(builder: (_) => Scaffold());
            }
            return null;
          },
          home: NodeOptionsSheet(
            nodeId: "node id",
            coin: Bitcoin(CryptoCurrencyNetwork.main),
            popBackToRoute: "coinNodes",
          ),
        ),
      ),
    );

    await tester.tap(find.text("Details"));
    await tester.pumpAndSettle();

    final currentRoute = navigatorKey.currentState?.overlay?.context;
    expect(currentRoute, isNotNull);
  });

  testWidgets("Connect tap", (tester) async {
    final mockWallets = MockWallets();
    final mockPrefs = MockPrefs();
    final mockNodeService = MockNodeService();
    final mockTorService = MockTorService();

    when(mockNodeService.getNodeById(id: "node id")).thenAnswer(
      (_) => NodeModel(
        host: "127.0.0.1",
        port: 2000,
        name: "Stack Default",
        id: "node id",
        useSSL: true,
        enabled: true,
        coinName: "Bitcoin",
        isFailover: false,
        isDown: false,
        torEnabled: true,
        clearnetEnabled: true,
      ),
    );

    when(mockNodeService.getPrimaryNodeFor(
            currency: Bitcoin(CryptoCurrencyNetwork.main)))
        .thenAnswer(
      (_) => NodeModel(
        host: "127.0.0.1",
        port: 2000,
        name: "Some other node name",
        id: "some node id",
        useSSL: true,
        enabled: true,
        coinName: "Bitcoin",
        isFailover: false,
        isDown: false,
        torEnabled: true,
        clearnetEnabled: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(mockWallets),
          prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
          nodeServiceChangeNotifierProvider.overrideWithValue(mockNodeService),
          pTorService.overrideWithValue(mockTorService),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(
                  json: lightThemeJsonMap,
                ),
              ),
            ],
          ),
          home: NodeOptionsSheet(
            nodeId: "node id",
            coin: Bitcoin(CryptoCurrencyNetwork.main),
            popBackToRoute: "",
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text("Node options"), findsOneWidget);
    expect(find.text("Disconnected"), findsOneWidget);

    await tester.tap(find.text("Connect"));
    await tester.pumpAndSettle();
  });
}
