import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/node_details_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/enums/sync_type_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/test_node_connection.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/widgets/node_card.dart';
import 'package:stackwallet/widgets/node_options_sheet.dart';

import '../sample_data/theme_json.dart';
import '../utilities/tls_test_server.dart';

class _Nodes extends NodeService {
  _Nodes(this.node, FakeSecureStorage secureStore)
    : super(secureStorageInterface: secureStore);
  NodeModel node;
  NodeModel? primary;
  int saves = 0;
  String? savedPassword;
  final events = <String>[];
  @override
  NodeModel? getNodeById({required String id}) => node.id == id ? node : null;
  @override
  List<NodeModel> getNodesFor(CryptoCurrency coin) => [node];
  @override
  NodeModel? getPrimaryNodeFor({required CryptoCurrency currency}) =>
      primary ?? node;
  @override
  Future<void> save(NodeModel node, String? password, bool notify) async {
    this.node = node;
    saves++;
    savedPassword = password;
    events.add('save:${node.trustedCertificatePem != null}');
    if (notify) notifyListeners();
  }

  @override
  Future<void> setPrimaryNodeFor({
    required CryptoCurrency coin,
    required NodeModel node,
    bool shouldNotifyListeners = false,
  }) async {
    this.node = node.copyWith(
      loginName: node.loginName,
      trusted: node.trusted,
      isPrimary: true,
    );
    primary = null;
    events.add('primary:${node.trustedCertificatePem != null}');
    if (shouldNotifyListeners) notifyListeners();
  }
}

class _Wallets extends Fake implements Wallets {
  @override
  List<Wallet> get wallets => [];
}

class _Prefs extends Mock implements Prefs {
  @override
  bool get useTor => false;
  @override
  SyncingType get syncType => SyncingType.allWalletsOnStartup;
}

void main() {
  final coin = Bitcoin(CryptoCurrencyNetwork.main);
  late _Nodes nodes;
  late FakeSecureStorage secureStore;
  late String pem;
  late String? testedHost;
  late String? testedCertificate;
  late String? testedPassword;

  setUp(() {
    pem = TlsElectrumServer.certificate('node_a');
    testedHost = null;
    testedCertificate = null;
    testedPassword = null;
    secureStore = FakeSecureStorage();
    nodes = _Nodes(
      NodeModel(
        host: 'node.example',
        port: 50002,
        name: 'Node',
        id: 'custom-node',
        useSSL: true,
        enabled: true,
        coinName: coin.identifier,
        isFailover: false,
        isDown: false,
        torEnabled: true,
        clearnetEnabled: true,
        isPrimary: false,
      ),
      secureStore,
    );
    Util.layoutPlatform = FakePlatform(operatingSystem: 'macos');
  });
  tearDown(() => Util.layoutPlatform = const LocalPlatform());

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nodeServiceChangeNotifierProvider.overrideWithValue(nodes),
          secureStoreProvider.overrideWithValue(secureStore),
          prefsChangeNotifierProvider.overrideWithValue(_Prefs()),
          pWallets.overrideWithValue(_Wallets()),
          testNodeConnectionProvider.overrideWithValue(({
            required context,
            required nodeFormData,
            required cryptoCurrency,
            onSuccess,
          }) async {
            testedHost = nodeFormData.host;
            testedCertificate = nodeFormData.trustedCertificatePem;
            testedPassword = nodeFormData.password;
            nodeFormData.trustedCertificatePem = pem;
            onSuccess?.call(nodeFormData);
            return true;
          }),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(json: lightThemeJsonMap),
              ),
            ],
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(0.8)),
            child: child!,
          ),
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget details({CryptoCurrency? coin}) => NodeDetailsView(
    coin: coin ?? Bitcoin(CryptoCurrencyNetwork.main),
    nodeId: nodes.node.id,
    popRouteName: '/',
  );

  NodeModel otherPrimary() => NodeModel(
    host: 'other.example',
    port: 50002,
    name: 'Other',
    id: 'other-node',
    useSSL: true,
    enabled: true,
    coinName: coin.identifier,
    isFailover: false,
    isDown: false,
    torEnabled: true,
    clearnetEnabled: true,
    isPrimary: true,
  );

  testWidgets('testing an existing node saves its approved certificate', (
    tester,
  ) async {
    await pump(tester, details());
    await tester.tap(find.text('Test connection'));
    await tester.pumpAndSettle();
    expect(nodes.saves, 1);
    expect(nodes.node.trustedCertificatePem, pem);
    expect(testedHost, 'node.example');
    expect(find.textContaining('Trusted TLS certificate'), findsOneWidget);
  });

  testWidgets(
    'desktop editing tests the edited endpoint and stages trust until Save',
    (tester) async {
      await pump(tester, details());
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'edited.example');
      await tester.tap(find.text('Test connection'));
      await tester.pumpAndSettle();
      expect(testedHost, 'edited.example');
      expect(nodes.saves, 0);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(nodes.node.host, 'edited.example');
      expect(nodes.node.trustedCertificatePem, pem);
    },
  );

  testWidgets('desktop editing tests and saves with the stored password', (
    tester,
  ) async {
    await secureStore.write(key: '${nodes.node.id}_nodePW', value: 'pw');
    await pump(tester, details(coin: Monero(CryptoCurrencyNetwork.main)));
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test connection'));
    await tester.pumpAndSettle();
    expect(testedPassword, 'pw');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(nodes.saves, 1);
    expect(nodes.savedPassword, 'pw');
  });

  testWidgets('Connect from node options saves approval before switching', (
    tester,
  ) async {
    nodes.primary = otherPrimary();
    await pump(
      tester,
      NodeOptionsSheet(nodeId: nodes.node.id, coin: coin, popBackToRoute: '/'),
    );
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(testedCertificate, null);
    expect(nodes.events, ['save:true', 'primary:true']);
    expect(nodes.node.trustedCertificatePem, pem);
    expect(nodes.node.isPrimary, true);
  });

  testWidgets('Connect from the node card keeps an existing approval', (
    tester,
  ) async {
    nodes.node = nodes.node.copyWith(
      loginName: null,
      trusted: null,
      trustedCertificatePem: pem,
    );
    nodes.primary = otherPrimary();
    await pump(
      tester,
      NodeCard(nodeId: nodes.node.id, coin: coin, popBackToRoute: '/'),
    );
    await tester.tap(find.text('Node'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connect', findRichText: true));
    await tester.pumpAndSettle();
    expect(testedCertificate, pem);
    expect(nodes.events, ['primary:true']);
    expect(nodes.node.trustedCertificatePem, pem);
    expect(nodes.node.isPrimary, true);
  });

  testWidgets('add/edit Save writes approval into the node model', (
    tester,
  ) async {
    await pump(
      tester,
      AddEditNodeView(
        viewType: AddEditNodeViewType.edit,
        coin: coin,
        nodeId: nodes.node.id,
        routeOnSuccessOrDelete: '/',
      ),
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(nodes.saves, 1);
    expect(nodes.node.trustedCertificatePem, pem);
  });

  testWidgets(
    'Forget certificate revokes approval when desktop edits are saved',
    (tester) async {
      nodes.node = nodes.node.copyWith(
        loginName: null,
        trusted: false,
        trustedCertificatePem: pem,
      );
      await pump(tester, details());
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forget certificate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(nodes.node.trustedCertificatePem, null);
      expect(find.textContaining('Trusted TLS certificate'), findsNothing);
    },
  );
}
