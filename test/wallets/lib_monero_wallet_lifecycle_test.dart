// Wallet-level lifecycle tests for the Monero family. The native cs_monero
// layer is faked so no native libraries are needed; everything above it —
// LibMoneroWallet, the lifecycle coordinator, the Tor listeners and a real
// Isar for mainDB — is the production code.

import 'dart:io';

import 'package:compat/compat.dart' as lib_monero_compat;
import 'package:cs_monero/cs_monero.dart' as cs;
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/monero_wallet.dart';
import 'package:stackwallet/wl_gen/interfaces/cs_salvium_interface.dart'
    show WrappedWallet;

import '../util/isar_test_core.dart';

class FakeCsWallet implements cs.Wallet {
  FakeCsWallet(this.calls);

  final List<String> calls;
  final List<cs.WalletListener> _listeners = [];

  @override
  void addListener(cs.WalletListener listener) => _listeners.add(listener);

  @override
  void removeListener(cs.WalletListener listener) =>
      _listeners.remove(listener);

  @override
  List<cs.WalletListener> getListeners() => List.unmodifiable(_listeners);

  @override
  Future<void> startListeners() async => calls.add("startListeners");

  @override
  Future<void> stopListeners() async => calls.add("stopListeners");

  @override
  void startAutoSaving() => calls.add("startAutoSaving");

  @override
  void stopAutoSaving() => calls.add("stopAutoSaving");

  @override
  Future<void> startSyncing({
    Duration interval = const Duration(seconds: 20),
  }) async => calls.add("startSyncing");

  @override
  Future<void> stopSyncing() async => calls.add("stopSyncing");

  @override
  Future<void> save() async => calls.add("save");

  @override
  bool isClosed() => false;

  @override
  Future<bool> connect({
    required String daemonAddress,
    required bool trusted,
    String? daemonUsername,
    String? daemonPassword,
    bool useSSL = false,
    bool isLightWallet = false,
    String? socksProxyAddress,
  }) async {
    calls.add("connect:$daemonAddress:${socksProxyAddress ?? "clearnet"}");
    return true;
  }

  @override
  Future<List<cs.Output>> getOutputs({
    bool includeSpent = false,
    bool refresh = false,
  }) async {
    calls.add("getOutputs");
    return [];
  }

  @override
  Future<BigInt> getBalance({int accountIndex = 0}) async => BigInt.zero;

  @override
  Future<BigInt> getUnlockedBalance({int accountIndex = 0}) async =>
      BigInt.zero;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError("FakeCsWallet: ${invocation.memberName}");
}

class FakeSecureStorage implements SecureStorageInterface {
  final Map<String, String?> _store = {};

  @override
  dynamic get store => null;

  @override
  Future<String?> read({
    required String key,
    iOptions,
    aOptions,
    lOptions,
    webOptions,
    mOptions,
    wOptions,
  }) async {
    if (key.endsWith("_nodePW")) return null;
    return _store[key] ?? "password";
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    iOptions,
    aOptions,
    lOptions,
    webOptions,
    mOptions,
    wOptions,
  }) async {
    _store[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError("FakeSecureStorage: ${invocation.memberName}");
}

NodeModel makeNode({required bool torEnabled, required bool clearnetEnabled}) =>
    NodeModel(
      host: "https://node.example",
      port: 18081,
      name: "test",
      id: "test-node",
      useSSL: true,
      enabled: true,
      coinName: "monero",
      isFailover: false,
      isDown: false,
      torEnabled: torEnabled,
      clearnetEnabled: clearnetEnabled,
      isPrimary: true,
      trusted: true,
    );

const kAddress =
    "4AdUndXHHZ6cfufTMvppY6JwXNouMBzSkbLYfpAV5Usx3skxNgYeYTRj5UzqtReoS44qo9"
    "mtmXCqY45DJ852K5Jv2684Rge";

class TestMoneroWallet extends MoneroWallet {
  TestMoneroWallet(this._id, this.node) : super(CryptoCurrencyNetwork.main) {
    _info = WalletInfo(
      walletId: _id,
      name: "test wallet",
      mainAddressType: AddressType.cryptonote,
      coinName: "monero",
      cachedReceivingAddress: kAddress,
    );
  }

  final String _id;
  NodeModel node;
  late final WalletInfo _info;
  final calls = <String>[];
  late final fakeNative = FakeCsWallet(calls);
  int updateNodeCalls = 0;

  int get connectCount => calls.where((e) => e.startsWith("connect:")).length;

  @override
  String get walletId => _id;

  @override
  WalletInfo get info => _info;

  @override
  NodeModel getCurrentNode() => node;

  @override
  Future<String> pathForWallet({
    required String name,
    required lib_monero_compat.WalletType type,
  }) async => "/nonexistent/$name";

  @override
  Future<WrappedWallet> loadWallet({
    required String path,
    required String password,
  }) async {
    calls.add("loadWallet");
    return WrappedWallet(fakeNative);
  }

  @override
  Future<Address?> getCurrentReceivingAddress() async => Address(
    walletId: _id,
    derivationIndex: 0,
    derivationPath: null,
    value: kAddress,
    publicKey: [],
    type: AddressType.cryptonote,
    subType: AddressSubType.receiving,
  );

  @override
  Future<void> refresh() async {}

  @override
  Future<void> updateNode() {
    updateNodeCalls++;
    return super.updateNode();
  }
}

Future<void> pump([int ms = 60]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

Future<void> waitFor(bool Function() condition, {int timeoutMs = 5000}) async {
  final stopwatch = Stopwatch()..start();
  while (!condition()) {
    if (stopwatch.elapsedMilliseconds > timeoutMs) {
      fail("timed out waiting for condition");
    }
    await pump(5);
  }
}

void fireTorPreferenceChanged(bool enabled) => GlobalEventBus.instance.fire(
  TorPreferenceChangedEvent(
    status: enabled ? TorStatus.enabled : TorStatus.disabled,
    message: "test",
  ),
);

void main() {
  late Directory tempDir;
  late Isar isar;
  var walletCount = 0;

  setUpAll(() async {
    await initializeIsarCoreForTests();
    tempDir = await Directory.systemTemp.createTemp("monero-lifecycle-test-");
    isar = await Isar.open(
      [
        UTXOSchema,
        AddressSchema,
        TransactionSchema,
        TransactionV2Schema,
        WalletInfoSchema,
      ],
      directory: tempDir.path,
      inspector: false,
      name: "monero-lifecycle-test",
    );
    await MainDB.instance.initMainDB(mock: isar);
  });

  tearDownAll(() async {
    await isar.close(deleteFromDisk: true);
    await tempDir.delete(recursive: true);
  });

  final wallets = <TestMoneroWallet>[];

  tearDown(() async {
    // A failing test must not leave event bus listeners attached.
    for (final wallet in wallets) {
      await wallet.exit();
    }
    wallets.clear();
  });

  TestMoneroWallet makeWallet({bool torOnlyNode = false}) {
    final wallet = TestMoneroWallet(
      "wallet-${walletCount++}",
      makeNode(torEnabled: true, clearnetEnabled: !torOnlyNode),
    );
    wallet.mainDB = MainDB.instance;
    wallet.secureStorageInterface = FakeSecureStorage();
    wallet.prefs = Prefs.instance; // useTor defaults to false
    wallets.add(wallet);
    return wallet;
  }

  test(
    "a wallet that was never opened ignores Tor preference changes",
    () async {
      // useTor is false and the node is Tor only, so a node update here would
      // throw the TOR/clearnet mismatch out of the event bus listener.
      final wallet = makeWallet(torOnlyNode: true);

      fireTorPreferenceChanged(true);
      await pump(200);

      expect(wallet.updateNodeCalls, 0);
      expect(wallet.calls, isEmpty);
    },
  );

  test(
    "reopening after a Tor preference change reconnects the native wallet",
    () async {
      final wallet = makeWallet();
      await wallet.open();
      expect(
        wallet.calls,
        containsAllInOrder([
          "loadWallet",
          "connect:node.example:18081:clearnet",
          "startSyncing",
        ]),
      );

      await wallet.exit();
      wallet.calls.clear();

      // The preference flips while the wallet is exited but still loaded, so no
      // listener is attached to react to it.
      fireTorPreferenceChanged(true);
      await pump(200);
      expect(wallet.connectCount, 0);

      await wallet.open();
      expect(
        wallet.connectCount,
        1,
        reason: "the reopened wallet must not keep its stale daemon session",
      );
    },
  );

  test(
    "reopening after a failed open reconnects to the corrected node",
    () async {
      final wallet = makeWallet(torOnlyNode: true);

      await expectLater(
        wallet.open(),
        throwsA(predicate((e) => "$e".contains("mismatch"))),
      );
      expect(wallet.connectCount, 0);

      // The node management UI calls updateNode() on every wallet of the
      // coin; this one is closed, so the update is rejected and the reopen
      // has to cover it.
      wallet.node = makeNode(torEnabled: true, clearnetEnabled: true);
      await wallet.updateNode();
      expect(wallet.connectCount, 0);

      await wallet.open();
      expect(wallet.connectCount, 1);
    },
  );

  test("concurrent open() calls load and connect exactly once", () async {
    final wallet = makeWallet();

    await Future.wait([wallet.open(), wallet.open(), wallet.open()]);

    expect(wallet.calls.where((e) => e == "loadWallet").length, 1);
    expect(wallet.connectCount, 1);
  });

  test("exit() requested during open() rejects later node updates", () async {
    final wallet = makeWallet();

    final open = wallet.open();
    final exit = wallet.exit();
    await Future.wait([open, exit]);
    wallet.calls.clear();

    await wallet.updateNode();
    expect(
      wallet.connectCount,
      0,
      reason: "exit() was requested after open(); the wallet is not in use",
    );
  });

  test("a Tor preference change while open reconnects immediately", () async {
    final wallet = makeWallet();
    await wallet.open();
    expect(wallet.connectCount, 1);

    fireTorPreferenceChanged(true);
    await waitFor(() => wallet.connectCount == 2);

    expect(wallet.updateNodeCalls, 1);
  });
}
