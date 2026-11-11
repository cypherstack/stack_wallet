import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level;
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/electrumx_rpc/client_manager.dart';
import 'package:stackwallet/electrumx_rpc/draining_electrum_client.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/node_details_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/connection_check/electrum_connection_check.dart';
import 'package:stackwallet/utilities/enums/sync_type_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/test_node_connection.dart';
import 'package:stackwallet/utilities/tor_plain_net_option_enum.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/node_card.dart';
import 'package:stackwallet/widgets/node_options_sheet.dart';
import 'package:stream_channel/stream_channel.dart';

import '../sample_data/theme_json.dart';
import '../utilities/tls_test_server.dart';

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
  late CryptoCurrency coin;
  late NodeService nodes;
  late FakeSecureStorage storage;
  late String pem;
  late Directory logs;
  String? testedHost, testedCertificate;
  Completer<void>? testGate;
  int tests = 0;
  NodeModel node() => nodes.getNodeById(id: 'custom-node')!;
  NodeModel makeNode(String id, {bool primary = false}) => NodeModel(
    host: id == 'custom-node' ? 'node.example' : 'other.example',
    port: 50002,
    name: id == 'custom-node' ? 'Node' : 'Other',
    id: id,
    useSSL: true,
    enabled: true,
    coinName: coin.identifier,
    isFailover: false,
    isDown: false,
    torEnabled: true,
    clearnetEnabled: true,
    isPrimary: primary,
  );

  setUpAll(() async {
    logs = await Directory.systemTemp.createTemp('minimal_tls_widgets');
    await Logging.instance.initialize(logs.path, level: Level.off);
  });
  tearDownAll(() => logs.delete(recursive: true));
  setUp(() async {
    coin = Bitcoin(CryptoCurrencyNetwork.main);
    DB.instance.hive.init(logs.path);
    if (!DB.instance.hive.isAdapterRegistered(12)) {
      DB.instance.hive.registerAdapter(NodeModelAdapter());
    }
    final box = await DB.instance.hive.openBox<NodeModel>(
      DB.boxNameNodeModels,
      bytes: Uint8List(0),
    );
    await box.put('custom-node', makeNode('custom-node'));
    await box.put('other-node', makeNode('other-node', primary: true));
    storage = FakeSecureStorage();
    nodes = NodeService(secureStorageInterface: storage);
    pem = TlsElectrumServer.certificate('node_a');
    testedHost = testedCertificate = null;
    testGate = null;
    tests = 0;
    Util.layoutPlatform = FakePlatform(operatingSystem: 'macos');
  });
  tearDown(() async {
    await ClientManager.sharedInstance.closeAll();
    await DB.instance.hive.close();
    Util.layoutPlatform = const LocalPlatform();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    TestNodeConnectionCallback? testConnection,
  }) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nodeServiceChangeNotifierProvider.overrideWithValue(nodes),
          secureStoreProvider.overrideWithValue(storage),
          prefsChangeNotifierProvider.overrideWithValue(_Prefs()),
          pWallets.overrideWithValue(_Wallets()),
          testNodeConnectionProvider.overrideWithValue(
            testConnection ??
                ({
                  required context,
                  required nodeFormData,
                  required cryptoCurrency,
                  onSuccess,
                }) async {
                  if (!nodes.prepareCertificateTest(nodeFormData)) return false;
                  testedHost = nodeFormData.host;
                  testedCertificate = nodeFormData.trustedCertificatePem;
                  tests++;
                  await testGate?.future;
                  nodeFormData.trustedCertificatePem = pem;
                  onSuccess?.call(nodeFormData);
                  return true;
                },
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(.8)),
            child: child!,
          ),
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget details() =>
      NodeDetailsView(coin: coin, nodeId: 'custom-node', popRouteName: '/');
  Future<void> approveStored() async {
    final opened = node();
    await nodes.saveTrustedCertificate(
      opened,
      NodeFormData.fromNode(opened)..trustedCertificatePem = pem,
    );
  }

  testWidgets(
    'Details Test saves approval without rewriting the node password',
    (tester) async {
      await storage.write(key: 'custom-node_nodePW', value: 'secret');
      await pump(tester, details());
      final writes = storage.writes;
      final deletes = storage.deletes;
      await tester.tap(find.text('Test connection'));
      await tester.pumpAndSettle();
      expect(node().trustedCertificatePem, pem);
      expect(testedHost, 'node.example');
      expect(storage.writes, writes);
      expect(storage.deletes, deletes);
      expect(find.textContaining('Trusted TLS certificate'), findsOneWidget);
    },
  );

  testWidgets('desktop Test stages an edited endpoint approval until Save', (
    tester,
  ) async {
    await pump(tester, details());
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'edited.example');
    await tester.tap(find.text('Test connection'));
    await tester.pumpAndSettle();
    expect(testedHost, 'edited.example');
    expect(node().host, 'node.example');
    expect(node().trustedCertificatePem, null);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(node().host, 'edited.example');
    expect(node().trustedCertificatePem, pem);
  });

  testWidgets(
    'desktop Save uses its own form after another view refreshes the provider',
    (tester) async {
      await pump(tester, details());
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test connection'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NodeDetailsView)),
      );
      container.refresh(nodeFormDataProvider)
        ..host = 'different.example'
        ..port = 60002
        ..useSSL = true
        ..trustedCertificatePem = TlsElectrumServer.certificate('node_b');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(node().host, 'node.example');
      expect(node().trustedCertificatePem, pem);
    },
  );

  testWidgets('repeated desktop edits keep the saved RPC password', (
    tester,
  ) async {
    coin = Ethereum(CryptoCurrencyNetwork.main);
    await nodes.save(makeNode('custom-node'), 'secret', false);
    await pump(tester, details());
    Finder field(String text) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller?.text == text,
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(field('secret'), 'changed-secret');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(await storage.read(key: 'custom-node_nodePW'), 'changed-secret');
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(field('changed-secret'), findsOneWidget);
    await tester.enterText(field('Node'), 'Renamed');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(node().name, 'Renamed');
    expect(await storage.read(key: 'custom-node_nodePW'), 'changed-secret');
  });

  testWidgets('options Connect commits approval and primary together', (
    tester,
  ) async {
    await pump(
      tester,
      NodeOptionsSheet(nodeId: 'custom-node', coin: coin, popBackToRoute: '/'),
    );
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(testedCertificate, null);
    expect(node().trustedCertificatePem, pem);
    expect(node().isPrimary, true);
    expect(nodes.getNodeById(id: 'other-node')!.isPrimary, false);
  });

  testWidgets('a node change closes connections still finishing requests', (
    tester,
  ) async {
    // A failed-over connection is still waiting on a request. No wallet of
    // this coin is loaded, so only the node change itself can close it.
    final channel = StreamChannelController<dynamic>();
    final draining = ManagedElectrumClient(
      channel.local,
      'node.example',
      50002,
      true,
      null,
      requestTimeout: null,
    );
    final manager = ClientManager.sharedInstance;
    late final Future<Object?> pending;
    // The client's plumbing needs the real event loop, not the fake clock.
    await tester.runAsync(() async {
      await manager.addClient(
        draining,
        cryptoCurrency: coin,
        netType: TorPlainNetworkOption.both,
      );
      pending = draining
          .requestWithTimeout('probe')
          .then<Object?>((_) => null, onError: (Object error) => error);
      await manager.retireClient(cryptoCurrency: coin, client: draining);
    });
    expect(draining.peer.isClosed, false);

    await pump(
      tester,
      NodeOptionsSheet(nodeId: 'custom-node', coin: coin, popBackToRoute: '/'),
    );
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(draining.peer.isClosed, true);
    expect(await tester.runAsync(() => pending), isA<StateError>());
    await tester.runAsync(() => channel.foreign.sink.close());
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('node card Connect carries an already approved certificate', (
    tester,
  ) async {
    await approveStored();
    await pump(
      tester,
      NodeCard(nodeId: 'custom-node', coin: coin, popBackToRoute: '/'),
    );
    await tester.tap(find.text('Node'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connect', findRichText: true));
    await tester.pumpAndSettle();
    expect(testedCertificate, pem);
    expect(node().trustedCertificatePem, pem);
    expect(node().isPrimary, true);
  });

  testWidgets('add/edit Save includes the tested certificate', (tester) async {
    await pump(
      tester,
      AddEditNodeView(
        viewType: AddEditNodeViewType.edit,
        coin: coin,
        nodeId: 'custom-node',
        routeOnSuccessOrDelete: '/',
      ),
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(node().trustedCertificatePem, pem);
  });

  testWidgets(
    'Forget in read-only Details is an immediate certificate-only write',
    (tester) async {
      await approveStored();
      await storage.write(key: 'custom-node_nodePW', value: 'secret');
      await pump(tester, details());
      final writes = storage.writes;
      final deletes = storage.deletes;
      await tester.tap(find.text('Forget certificate'));
      await tester.pumpAndSettle();
      expect(node().trustedCertificatePem, null);
      expect(node().host, 'node.example');
      expect(storage.writes, writes);
      expect(storage.deletes, deletes);
    },
  );

  testWidgets('an editing Forget is staged until Save', (tester) async {
    await approveStored();
    await pump(tester, details());
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forget certificate'));
    await tester.pumpAndSettle();
    expect(node().trustedCertificatePem, pem);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(node().trustedCertificatePem, null);
  });

  testWidgets('desktop Save cannot overtake a running Test', (tester) async {
    await pump(tester, details());
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    testGate = Completer<void>();
    final save = tester
        .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'Save'))
        .onPressed!;
    await tester.tap(find.text('Test connection'));
    await tester.pump();
    save();
    await tester.pump();
    expect(tests, 1);
    expect(node().trustedCertificatePem, null);
    expect(
      tester
          .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'Save'))
          .onPressed,
      null,
    );
    testGate!.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(node().trustedCertificatePem, pem);
  });

  testWidgets(
    'node replaced during Test keeps its endpoint and certificate together',
    (tester) async {
      await approveStored();
      final started = Completer<void>();
      final release = Completer<void>();
      await pump(
        tester,
        details(),
        testConnection:
            ({
              required context,
              required nodeFormData,
              required cryptoCurrency,
              onSuccess,
            }) => testElectrumNodeConnection(
              nodeFormData,
              isActive: () => context.mounted,
              requestTrust: (_, _, _) async => false,
              onSuccess: onSuccess,
              testConnection:
                  ({
                    required host,
                    required port,
                    required useSSL,
                    trustedCertificatePem,
                  }) async {
                    started.complete();
                    await release.future;
                    return const ElectrumConnectionResult(success: false);
                  },
            ),
      );
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test connection'));
      await tester.pump();
      await tester.pump();
      expect(started.isCompleted, true);

      final before = node();
      final replacement = before.copyWith(
        host: 'replacement.example',
        port: 60002,
        loginName: before.loginName,
        trusted: before.trusted,
        trustedCertificatePem: TlsElectrumServer.certificate('node_b'),
      );
      await nodes.save(replacement, null, true);
      await tester.pump();
      await tester.pump();

      final widget = tester.widget<NodeForm>(find.byType(NodeForm));
      final form = widget.data!;
      expect(widget.busy, true);
      expect(form.source, same(replacement));
      expect(form.host, replacement.host);
      expect(form.port, replacement.port);
      expect(form.useSSL, replacement.useSSL);
      expect(form.trustedCertificatePem, replacement.trustedCertificatePem);
      expect(
        tester.widgetList<TextField>(find.byType(TextField)),
        everyElement(
          isA<TextField>().having((field) => field.readOnly, 'readOnly', true),
        ),
      );

      release.complete();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(node().host, replacement.host);
      expect(node().port, replacement.port);
      expect(node().trustedCertificatePem, replacement.trustedCertificatePem);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a readonly test cannot undo an intervening empty Forget', (
    tester,
  ) async {
    await pump(tester, details());
    testGate = Completer<void>();
    await tester.tap(find.text('Test connection'));
    await tester.pump();
    await nodes.forgetTrustedCertificate(node());
    testGate!.complete();
    await tester.pumpAndSettle();
    expect(node().trustedCertificatePem, null);
  });

  testWidgets('Connect ignores a node changed during its test', (tester) async {
    await pump(
      tester,
      NodeOptionsSheet(nodeId: 'custom-node', coin: coin, popBackToRoute: '/'),
    );
    testGate = Completer<void>();
    await tester.tap(find.text('Connect'));
    await tester.pump();
    final before = node();
    await DB.instance.put<NodeModel>(
      boxName: DB.boxNameNodeModels,
      key: before.id,
      value: before.copyWith(
        host: 'new.example',
        loginName: null,
        trusted: null,
      ),
    );
    testGate!.complete();
    await tester.pumpAndSettle();
    expect(node().isPrimary, false);
    expect(node().trustedCertificatePem, null);
  });
}
