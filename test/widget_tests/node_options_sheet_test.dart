import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/node_details_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/enums/sync_type_enum.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/widgets/node_options_sheet.dart';

import '../sample_data/theme_json.dart';
import 'node_options_sheet_test.mocks.dart';
import 'support/platform_test_overrides.dart';

@GenerateMocks([Wallets, Prefs, NodeService, TorService])
void main() {
  final bitcoin = Bitcoin(CryptoCurrencyNetwork.main);

  NodeModel buildNode({required String id, required String name}) {
    return NodeModel(
      host: '127.0.0.1',
      port: 2000,
      name: name,
      id: id,
      useSSL: true,
      enabled: true,
      coinName: 'Bitcoin',
      isFailover: false,
      isDown: false,
      torEnabled: true,
      clearnetEnabled: true,
      isPrimary: true,
    );
  }

  ThemeData buildTheme() {
    return ThemeData(
      extensions: [
        StackColors.fromStackColorTheme(
          StackTheme.fromJson(json: lightThemeJsonMap),
        ),
      ],
    );
  }

  void stubCommonProviders({
    required MockWallets wallets,
    required MockPrefs prefs,
    required MockNodeService nodeService,
    required NodeModel node,
    required NodeModel primaryNode,
  }) {
    when(wallets.wallets).thenReturn([]);
    when(prefs.syncType).thenReturn(SyncingType.currentWalletOnly);
    when(nodeService.getNodeById(id: node.id)).thenAnswer((_) => node);
    when(
      nodeService.getPrimaryNodeFor(currency: bitcoin),
    ).thenAnswer((_) => primaryNode);
  }

  Future<void> pumpSubject(
    WidgetTester tester, {
    required MockWallets wallets,
    required MockPrefs prefs,
    required MockNodeService nodeService,
    required List<Override> extraOverrides,
    GlobalKey<NavigatorState>? navigatorKey,
    RouteFactory? onGenerateRoute,
    String popBackToRoute = '',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(wallets),
          prefsChangeNotifierProvider.overrideWithValue(prefs),
          nodeServiceChangeNotifierProvider.overrideWithValue(nodeService),
          ...extraOverrides,
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: buildTheme(),
          onGenerateRoute: onGenerateRoute,
          home: NodeOptionsSheet(
            nodeId: 'node id',
            coin: bitcoin,
            popBackToRoute: popBackToRoute,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('Load Node Options widget with disabled connect state', (
    tester,
  ) async {
    final mockWallets = MockWallets();
    final mockPrefs = MockPrefs();
    final mockNodeService = MockNodeService();
    final connectedNode = buildNode(id: 'node id', name: 'Some other name');

    stubCommonProviders(
      wallets: mockWallets,
      prefs: mockPrefs,
      nodeService: mockNodeService,
      node: connectedNode,
      primaryNode: connectedNode,
    );

    await pumpSubject(
      tester,
      wallets: mockWallets,
      prefs: mockPrefs,
      nodeService: mockNodeService,
      extraOverrides: const [],
    );

    expect(find.text('Node options'), findsOneWidget);
    expect(find.text('Some other name'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(2));
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Connect'))
          .onPressed,
      isNull,
    );

    verify(mockNodeService.getPrimaryNodeFor(currency: bitcoin)).called(1);
    verify(mockNodeService.getNodeById(id: 'node id')).called(1);
    verify(mockNodeService.addListener(any)).called(1);
    verifyNoMoreInteractions(mockNodeService);
  });

  testWidgets('Details tap pushes node details route', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final mockWallets = MockWallets();
    final mockPrefs = MockPrefs();
    final mockNodeService = MockNodeService();
    final node = buildNode(id: 'node id', name: 'Stack Default');
    final otherPrimary = buildNode(id: 'some node id', name: 'Stack Default');

    stubCommonProviders(
      wallets: mockWallets,
      prefs: mockPrefs,
      nodeService: mockNodeService,
      node: node,
      primaryNode: otherPrimary,
    );

    await pumpSubject(
      tester,
      wallets: mockWallets,
      prefs: mockPrefs,
      nodeService: mockNodeService,
      extraOverrides: const [],
      navigatorKey: navigatorKey,
      popBackToRoute: 'coinNodes',
      onGenerateRoute: (settings) {
        if (settings.name == NodeDetailsView.routeName) {
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('details route')),
          );
        }
        return null;
      },
    );

    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();

    expect(find.text('details route'), findsOneWidget);
    expect(navigatorKey.currentState?.canPop(), isFalse);
  });

  testWidgets('Connect tap uses fake storage and promotes node on success', (
    tester,
  ) async {
    final mockWallets = MockWallets();
    final mockPrefs = MockPrefs();
    final mockNodeService = MockNodeService();
    final node = buildNode(id: 'node id', name: 'Stack Default');
    final otherPrimary = buildNode(
      id: 'some node id',
      name: 'Some other node name',
    );
    final platformOverrides = await createPlatformTestOverrides(
      secureStorageEntries: {'node id_nodePW': 'fake-node-password'},
      connectionResult: true,
    );

    stubCommonProviders(
      wallets: mockWallets,
      prefs: mockPrefs,
      nodeService: mockNodeService,
      node: node,
      primaryNode: otherPrimary,
    );
    when(
      mockNodeService.setPrimaryNodeFor(
        coin: bitcoin,
        node: node,
        shouldNotifyListeners: true,
      ),
    ).thenAnswer((_) async {});

    await pumpSubject(
      tester,
      wallets: mockWallets,
      prefs: mockPrefs,
      nodeService: mockNodeService,
      extraOverrides: platformOverrides.overrides,
    );

    expect(find.text('Disconnected'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Connect'));
    await tester.pumpAndSettle();

    expect(platformOverrides.secureStorage.reads, 1);
    expect(platformOverrides.connectionInvocations, hasLength(1));
    expect(
      platformOverrides.connectionInvocations.single.password,
      'fake-node-password',
    );
    expect(platformOverrides.connectionInvocations.single.host, '127.0.0.1');

    verify(
      mockNodeService.setPrimaryNodeFor(
        coin: bitcoin,
        node: node,
        shouldNotifyListeners: true,
      ),
    ).called(1);
  });

  testWidgets(
    'Connect failure stays inside fake seam with missing stored password',
    (tester) async {
      final mockWallets = MockWallets();
      final mockPrefs = MockPrefs();
      final mockNodeService = MockNodeService();
      final node = buildNode(id: 'node id', name: 'Stack Default');
      final otherPrimary = buildNode(
        id: 'some node id',
        name: 'Some other node name',
      );
      final platformOverrides = await createPlatformTestOverrides(
        connectionResult: false,
      );

      stubCommonProviders(
        wallets: mockWallets,
        prefs: mockPrefs,
        nodeService: mockNodeService,
        node: node,
        primaryNode: otherPrimary,
      );

      await pumpSubject(
        tester,
        wallets: mockWallets,
        prefs: mockPrefs,
        nodeService: mockNodeService,
        extraOverrides: platformOverrides.overrides,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Connect'));
      await tester.pumpAndSettle();

      expect(platformOverrides.secureStorage.reads, 1);
      expect(platformOverrides.connectionInvocations, hasLength(1));
      expect(platformOverrides.connectionInvocations.single.password, isNull);

      verifyNever(
        mockNodeService.setPrimaryNodeFor(
          coin: bitcoin,
          node: anyNamed('node'),
          shouldNotifyListeners: anyNamed('shouldNotifyListeners'),
        ),
      );
    },
  );
}
