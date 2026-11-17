import 'dart:convert';
import 'dart:io';

import 'package:grin_native/grin_native.dart';
import 'package:grin_native/testing.dart';
import 'package:path/path.dart' as p;

/// What [TestChainApi.updateNetwork] was asked to apply.
typedef NetworkUpdate = ({
  String nodeUrl,
  String? apiSecret,
  String? socksProxy,
  bool networkEnabled,
});

GrinException _grinError(int code, String message, [Object? details]) =>
    GrinException.fromJson(
      code,
      jsonEncode({'code': code, 'message': message, 'details': details}),
    );

/// A [GrinWalletBackend] whose wallets live on one in-process test chain.
///
/// GrinWallet passes its own network (mainnet in this app config) and node
/// URL. Both are replaced here: every wallet runs on automated testing, the
/// only chain the harness mines, and node calls go to the chain itself.
/// Needs the native library built with the test_utils user-define.
class TestChainBackend implements GrinWalletBackend {
  TestChainBackend(this.chainDir);

  final String chainDir;
  static const network = GrinNetwork.automatedTesting;
  static const _native = GrinNativeBackend();

  /// Calls made through this backend and its wallets, in order.
  final List<String> calls = [];

  /// Open wallets by wallet directory.
  final Map<String, TestChainApi> _apis = {};

  /// When true, the next scan on any wallet ends the way a scan cancelled
  /// before its first batch does.
  bool cancelNextScan = false;

  /// The open wallet in [walletDir].
  TestChainApi apiFor(String walletDir) {
    final api = _apis[p.normalize(walletDir)];
    if (api == null || api.isClosed) {
      throw StateError('No open test chain wallet in $walletDir');
    }
    return api;
  }

  /// Mines [count] blocks to the wallet in [walletDir] and returns the new
  /// chain height.
  Future<int> mine(String walletDir, int count) =>
      GrinTestChain.mineBlocks(apiFor(walletDir).inner, count);

  Future<TestChainApi> _attach({
    required GrinWalletConfig config,
    required String password,
    String? mnemonic,
    bool isNewWallet = false,
  }) async {
    final dir = p.normalize(config.walletDir);
    final client = await GrinTestChain.createWallet(
      chainDir: chainDir,
      walletDir: dir,
      // The wallet id: unique per chain, and stable so a reopen re-attaches.
      clientId: p.basename(dir),
      network: network,
      mnemonic: mnemonic,
      password: password,
      isNewWallet: isNewWallet,
    );
    final api = TestChainApi(client, this);
    _apis[dir] = api;
    return api;
  }

  bool _hasSeed(String walletDir) =>
      File(p.join(walletDir, 'wallet_data', 'wallet.seed')).existsSync();

  @override
  Future<GrinWalletApi> create({
    required GrinWalletConfig config,
    String? mnemonic,
    required String password,
    bool isNewWallet = false,
  }) async {
    calls.add('create:${p.basename(config.walletDir)}:new=$isNewWallet');
    // The harness opens an existing wallet instead; keep create's contract.
    if (_hasSeed(config.walletDir)) {
      throw _grinError(6, 'wallet exists', {'wallet_dir': config.walletDir});
    }
    return _attach(
      config: config,
      password: password,
      mnemonic: mnemonic,
      isNewWallet: isNewWallet,
    );
  }

  @override
  Future<GrinWalletApi> open({
    required GrinWalletConfig config,
    required String password,
  }) async {
    calls.add('open:${p.basename(config.walletDir)}');
    if (!_hasSeed(config.walletDir)) {
      throw _grinError(4, 'wallet not found', {'wallet_dir': config.walletDir});
    }
    return _attach(config: config, password: password);
  }

  @override
  Future<void> delete({required String walletDir}) {
    calls.add('delete:${p.basename(walletDir)}');
    return _native.delete(walletDir: walletDir);
  }

  /// The chain tip, read through any open wallet on the chain.
  @override
  Future<GrinNodeInfo> testNodeConnection({
    required String nodeUrl,
    String? apiSecret,
    String? socksProxy,
  }) async {
    final open = _apis.values.where((api) => !api.isClosed);
    if (open.isEmpty) throw _grinError(9, 'no wallet on the test chain');
    final tip = await open.first.inner.getChainHeight();
    return GrinNodeInfo(
      nodeVersion: 'test-chain',
      blockHeaderVersion: 1,
      height: tip.height,
      hash: tip.hash,
    );
  }

  @override
  Future<String> generateMnemonic({int wordCount = 24}) =>
      _native.generateMnemonic(wordCount: wordCount);

  @override
  Future<GrinMnemonicValidation> validateMnemonic(String mnemonic) =>
      _native.validateMnemonic(mnemonic);

  @override
  Future<GrinAddressValidation> validateAddress(
    String address,
    GrinNetwork network,
  ) => _native.validateAddress(address, TestChainBackend.network);

  @override
  GrinAddressValidation validateAddressSync(
    String address,
    GrinNetwork network,
  ) => _native.validateAddressSync(address, TestChainBackend.network);

  @override
  Future<GrinSlateInfo> decodeSlatepackWithoutWallet(
    String armored,
    GrinNetwork network,
  ) => _native.decodeSlatepackWithoutWallet(armored, TestChainBackend.network);
}

/// A test chain wallet as GrinWallet sees it.
///
/// updateNetwork is recorded and not applied: the real call swaps the
/// in-process chain client for an HTTP one, and the wallet would lose the
/// chain. Everything else goes to the real wallet.
class TestChainApi implements GrinWalletApi {
  TestChainApi(this.inner, this._backend);

  final GrinWalletClient inner;
  final TestChainBackend _backend;
  final List<NetworkUpdate> networkUpdates = [];
  final List<int> scanStarts = [];

  List<String> get _calls => _backend.calls;

  @override
  String get walletDir => inner.walletDir;

  @override
  GrinNetwork get network => inner.network;

  @override
  bool get isClosed => inner.isClosed;

  @override
  Stream<GrinWalletEvent> get events => inner.events;

  @override
  Future<GrinAddressInfo> getAddress({int index = 0}) =>
      inner.getAddress(index: index);

  @override
  Future<GrinChainTip> getChainHeight() => inner.getChainHeight();

  @override
  Future<GrinBalance> getBalance({
    bool refreshFromNode = true,
    int minimumConfirmations = 10,
  }) => inner.getBalance(
    refreshFromNode: refreshFromNode,
    minimumConfirmations: minimumConfirmations,
  );

  @override
  Future<GrinScanResult> scan({
    int startHeight = 0,
    bool deleteUnconfirmed = false,
  }) async {
    _calls.add('scan:${p.basename(walletDir)}:$startHeight');
    scanStarts.add(startHeight);
    if (_backend.cancelNextScan) {
      _backend.cancelNextScan = false;
      // A chain this short is one 10,001-height batch, so a real cancel
      // cannot be timed. Report what the library reports for a cancel that
      // arrives before the first batch: nothing scanned below the start.
      final tip = (await inner.getChainHeight()).height;
      final start = startHeight < 1 ? 1 : startHeight;
      final scanned = (start - 1) < tip ? start - 1 : tip;
      throw _grinError(14, 'scan cancelled', {
        'scanned_height': scanned,
        'tip_height': tip,
      });
    }
    return inner.scan(
      startHeight: startHeight,
      deleteUnconfirmed: deleteUnconfirmed,
    );
  }

  @override
  Future<int> lastScannedHeight() => inner.lastScannedHeight();

  @override
  GrinScanProgress scanProgress() => inner.scanProgress();

  @override
  void cancelScan() => inner.cancelScan();

  @override
  Future<void> changePassword(String oldPassword, String newPassword) =>
      inner.changePassword(oldPassword, newPassword);

  @override
  Future<String> getMnemonic(String password) => inner.getMnemonic(password);

  @override
  Future<void> updateNetwork({
    required String nodeUrl,
    required String? apiSecret,
    required String? socksProxy,
    required bool networkEnabled,
  }) async {
    networkUpdates.add((
      nodeUrl: nodeUrl,
      apiSecret: apiSecret,
      socksProxy: socksProxy,
      networkEnabled: networkEnabled,
    ));
  }

  @override
  Future<GrinFeeEstimate> estimateFee({
    required BigInt amount,
    int minimumConfirmations = 10,
    bool selectionStrategyIsAll = false,
    bool amountIncludesFee = false,
  }) => inner.estimateFee(
    amount: amount,
    minimumConfirmations: minimumConfirmations,
    selectionStrategyIsAll: selectionStrategyIsAll,
    amountIncludesFee: amountIncludesFee,
  );

  @override
  Future<GrinTxList> getTransactions({bool refreshFromNode = true}) {
    if (refreshFromNode) _calls.add('refresh:${p.basename(walletDir)}');
    return inner.getTransactions(refreshFromNode: refreshFromNode);
  }

  @override
  Future<GrinSlateInfo> decodeSlatepack(
    String armored, {
    int secretIndex = 0,
  }) => inner.decodeSlatepack(armored, secretIndex: secretIndex);

  @override
  Future<GrinSlatepack> initSend(GrinSendArgs args) => inner.initSend(args);

  @override
  Future<GrinSendResult> sendHttp(GrinHttpSendArgs args) =>
      throw UnsupportedError('HTTP sends are not part of these tests');

  @override
  Future<GrinSlatepack> receiveSlatepack(String armoredS1) =>
      inner.receiveSlatepack(armoredS1);

  /// When true, the next finalize keeps the transaction without posting it,
  /// as if the broadcast had failed.
  bool skipNextBroadcast = false;

  @override
  Future<GrinFinalizeResult> finalizeSlatepack(
    String armoredS2, {
    bool broadcast = true,
    bool fluff = false,
  }) {
    final post = broadcast && !skipNextBroadcast;
    skipNextBroadcast = false;
    return inner.finalizeSlatepack(armoredS2, broadcast: post, fluff: fluff);
  }

  @override
  Future<GrinSlatepack> issueInvoice(GrinInvoiceArgs args) =>
      inner.issueInvoice(args);

  @override
  Future<GrinSlatepack> processInvoice(
    String armoredI1,
    GrinProcessInvoiceArgs args,
  ) {
    _calls.add('processInvoice:${p.basename(walletDir)}');
    return inner.processInvoice(armoredI1, args);
  }

  @override
  Future<GrinFinalizeResult> finalizeInvoice(
    String armoredI2, {
    bool broadcast = true,
    bool fluff = false,
  }) => inner.finalizeInvoice(armoredI2, broadcast: broadcast, fluff: fluff);

  @override
  Future<void> repost({int? txId, String? slateId, bool fluff = false}) {
    _calls.add('repost:${p.basename(walletDir)}');
    return inner.repost(txId: txId, slateId: slateId, fluff: fluff);
  }

  @override
  Future<void> cancelTransaction({int? txId, String? slateId}) =>
      inner.cancelTransaction(txId: txId, slateId: slateId);

  @override
  Future<GrinPaymentProof> exportPaymentProof({int? txId, String? slateId}) =>
      inner.exportPaymentProof(txId: txId, slateId: slateId);

  @override
  Future<GrinPaymentProofVerification> verifyPaymentProof(
    GrinPaymentProof proof,
  ) => inner.verifyPaymentProof(proof);

  @override
  Future<void> close() => inner.close();
}
