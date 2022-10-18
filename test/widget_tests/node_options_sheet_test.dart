import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/widgets/node_options_sheet.dart';
import 'package:tuple/tuple.dart';

import 'node_options_sheet_test.mocks.dart';

@GenerateMocks([Wallets, Prefs, NodeService])
void main() {
  testWidgets("Load Node Options widget", (tester) async {
    final mockWallets = MockWallets();
    final mockPrefs = MockPrefs();
    final mockNodeService = MockNodeService();

    when(mockNodeService.getNodeById(id: "node id")).thenAnswer(
        (realInvocation) => NodeModel(
            host: "127.0.0.1",
            port: 2000,
            name: "Stack Default",
            id: "node id",
            useSSL: true,
            enabled: true,
            coinName: "Bitcoin",
            isFailover: false,
            isDown: false));

    when(mockNodeService.getPrimaryNodeFor(coin: Coin.bitcoin)).thenAnswer(
        (realInvocation) => NodeModel(
            host: "127.0.0.1",
            port: 2000,
            name: "Stack Default",
            id: "node id",
            useSSL: true,
            enabled: true,
            coinName: "Bitcoin",
            isFailover: false,
            isDown: false));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsChangeNotifierProvider.overrideWithValue(mockWallets),
          prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
          nodeServiceChangeNotifierProvider.overrideWithValue(mockNodeService)
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                LightColors(),
              ),
            ],
          ),
          home: const NodeOptionsSheet(
              nodeId: "node id", coin: Coin.bitcoin, popBackToRoute: ""),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text("Node options"), findsOneWidget);
    expect(find.text("Stack Default"), findsOneWidget);
    expect(find.text("Connected"), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(2));
    expect(find.text("Details"), findsOneWidget);
    expect(find.text("Connect"), findsOneWidget);

    verify(mockNodeService.getPrimaryNodeFor(coin: Coin.bitcoin)).called(1);
    verify(mockNodeService.getNodeById(id: "node id")).called(1);
    verify(mockNodeService.addListener(any)).called(1);
    verifyNoMoreInteractions(mockNodeService);
  });

  testWidgets("Details tap", (tester) async {
    final mockWallets = MockWallets();
    final mockPrefs = MockPrefs();
    final mockNodeService = MockNodeService();
    final navigator = mockingjay.MockNavigator();

    when(mockNodeService.getNodeById(id: "node id")).thenAnswer(
        (realInvocation) => NodeModel(
            host: "127.0.0.1",
            port: 2000,
            name: "Stack Default",
            id: "node id",
            useSSL: true,
            enabled: true,
            coinName: "Bitcoin",
            isFailover: false,
            isDown: false));

    when(mockNodeService.getPrimaryNodeFor(coin: Coin.bitcoin)).thenAnswer(
        (realInvocation) => NodeModel(
            host: "127.0.0.1",
            port: 2000,
            name: "Stack Default",
            id: "node id",
            useSSL: true,
            enabled: true,
            coinName: "Bitcoin",
            isFailover: false,
            isDown: false));

    mockingjay
        .when(() => navigator.pushNamed("/nodeDetails",
            arguments: const Tuple3(Coin.bitcoin, "node id", "coinNodes")))
        .thenAnswer((_) async => {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsChangeNotifierProvider.overrideWithValue(mockWallets),
          prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
          nodeServiceChangeNotifierProvider.overrideWithValue(mockNodeService)
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(LightColors()),
            ],
          ),
          home: mockingjay.MockNavigatorProvider(
              navigator: navigator,
              child: const NodeOptionsSheet(
                  nodeId: "node id",
                  coin: Coin.bitcoin,
                  popBackToRoute: "coinNodes")),
        ),
      ),
    );

    await tester.tap(find.text("Details"));
    await tester.pumpAndSettle();

    mockingjay.verify(() => navigator.pop()).called(1);
    mockingjay
        .verify(() => navigator.pushNamed("/nodeDetails",
            arguments: const Tuple3(Coin.bitcoin, "node id", "coinNodes")))
        .called(1);
  });

  testWidgets("Connect tap", (tester) async {
    final mockWallets = MockWallets();
    final mockPrefs = MockPrefs();
    final mockNodeService = MockNodeService();

    when(mockNodeService.getNodeById(id: "node id")).thenAnswer(
        (realInvocation) => NodeModel(
            host: "127.0.0.1",
            port: 2000,
            name: "Stack Default",
            id: "node id",
            useSSL: true,
            enabled: true,
            coinName: "Bitcoin",
            isFailover: false,
            isDown: false));

    when(mockNodeService.getPrimaryNodeFor(coin: Coin.bitcoin)).thenAnswer(
        (realInvocation) => NodeModel(
            host: "127.0.0.1",
            port: 2000,
            name: "Some other node name",
            id: "some node id",
            useSSL: true,
            enabled: true,
            coinName: "Bitcoin",
            isFailover: false,
            isDown: false));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsChangeNotifierProvider.overrideWithValue(mockWallets),
          prefsChangeNotifierProvider.overrideWithValue(mockPrefs),
          nodeServiceChangeNotifierProvider.overrideWithValue(mockNodeService)
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                LightColors(),
              ),
            ],
          ),
          home: const NodeOptionsSheet(
              nodeId: "node id", coin: Coin.bitcoin, popBackToRoute: ""),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text("Node options"), findsOneWidget);
    // expect(find.text("Stack Default"), findsOneWidget);
    expect(find.text("Disconnected"), findsOneWidget);

    await tester.tap(find.text("Connect"));
    await tester.pumpAndSettle();
  });
}
