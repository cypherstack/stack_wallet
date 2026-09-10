//ON
import 'dart:async';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart' as xwf;

import '../../providers/progress_report/xelis_table_progress_provider.dart';
import '../../utilities/logger.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
//END_ON
import '../interfaces/lib_xelis_interface.dart';

LibXelisInterface get libXelis => _getInterface();

//OFF
LibXelisInterface _getInterface() => throw StateError('XEL not enabled');
//END_OFF
//ON
final _interface = _LibXelisInterfaceImpl();
LibXelisInterface _getInterface() => _interface;

extension on OpaqueXelisWallet {
  xwf.XelisWallet get actual => get<xwf.XelisWallet>();
}

final class _LibXelisInterfaceImpl extends LibXelisInterface {
  StreamSubscription<xwf.XelisLogEntry>? _logs;
  StreamSubscription<xwf.ProgressReport>? _progress;
  final _progressEvents = StreamController<XelisTableProgressState>.broadcast();
  XelisTableProgressState _lastProgress = const XelisTableProgressState();

  @override
  String get xelisAsset => sdk.xelisAsset;

  @override
  Future<void> initRustLib() async {
    await xwf.XelisWalletFlutter.initialize();
    await xwf.XelisWalletFlutter.initializeConfiguration();
    await xwf.XelisWalletFlutter.initializeCryptoProvider();
    _progress ??= xwf.XelisWalletFlutter.createProgressReportStream().listen((
      report,
    ) {
      _lastProgress = XelisTableProgressState(
        tableProgress: report.progress,
        currentStep: XelisTableGenerationStep.fromString(report.step),
      );
      _progressEvents.add(_lastProgress);
    }, onError: _progressEvents.addError);
  }

  @override
  Future<void> setupRustLogger() => xwf.XelisWalletFlutter.initializeRustLogger(
    scope: xwf.XelisNativeLogScope.standard,
  );

  @override
  void startListeningToRustLogs() {
    _logs ??= xwf.XelisWalletFlutter.createRustLogStream().listen(
      (entry) => Logging.instance.log(switch (entry.level) {
        xwf.XelisLogLevel.error => Level.error,
        xwf.XelisLogLevel.warn => Level.warning,
        xwf.XelisLogLevel.info => Level.info,
        xwf.XelisLogLevel.debug => Level.debug,
        xwf.XelisLogLevel.trace => Level.trace,
      }, '[Xelis] ${entry.message}'),
      onError: (Object error, StackTrace stack) => Logging.instance.e(
        'Xelis log stream failed',
        error: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Stream<XelisTableProgressState> createProgressReportStream() async* {
    yield _lastProgress;
    yield* _progressEvents.stream;
  }

  @override
  bool isAddressValid({
    required String address,
    required CryptoCurrencyNetwork network,
  }) => xwf.XelisWalletFlutter.isAddressValid(
    address: address,
    network: _network(network),
  );

  @override
  bool validateSeedWord(String word) {
    final engine = xwf.XelisWalletFlutter.createSeedSearchEngine(
      language: xwf.SeedLanguage.english,
    );
    try {
      return word.isNotEmpty && engine.findInvalidWords(words: [word]).isEmpty;
    } finally {
      engine.dispose();
    }
  }

  @override
  Future<XelisEventSubscription> subscribeRuntimeEvents(
    OpaqueXelisWallet wallet,
  ) async {
    final subscription = await wallet.actual.subscribeRuntimeEvents();
    return XelisEventSubscription(
      cancel: subscription.cancel,
      events: subscription.events.map(
        (frame) => switch (frame.event) {
          xwf.XelisWalletOnline() => const Online(),
          xwf.XelisWalletOffline() => const Offline(),
          xwf.XelisWalletTopoheightChanged(:final topoheight) => NewTopoheight(
            topoheight,
          ),
          xwf.XelisWalletHistorySynced(:final topoheight) => HistorySynced(
            topoheight,
          ),
          xwf.XelisWalletRescanStarted(:final startTopoheight) => Rescan(
            startTopoheight,
          ),
          xwf.XelisWalletSyncIssue(:final failure) => XelisSyncIssue(failure),
          xwf.XelisWalletEventStreamDegraded(:final failure) =>
            XelisStateInvalidated(failure: failure),
          xwf.XelisWalletEventStreamClosed(:final failure) =>
            XelisChannelClosed(failure, isRuntime: true),
        },
      ),
    );
  }

  @override
  Future<XelisEventSubscription> subscribeBusinessEvents(
    OpaqueXelisWallet wallet,
  ) async {
    final subscription = await wallet.actual.subscribeBusinessEvents();
    return XelisEventSubscription(
      cancel: subscription.cancel,
      events: subscription.events.map(
        (frame) => switch (frame.event) {
          xwf.XelisWalletNewTransaction(:final transaction) => NewTransaction(
            _confirmed(transaction),
          ),
          xwf.XelisWalletNewPendingTransaction(:final transaction) =>
            NewTransaction(_pending(transaction)),
          xwf.XelisWalletBalanceChanged(:final asset, :final balance) =>
            BalanceChanged(asset, balance),
          xwf.XelisWalletNewAsset() ||
          xwf.XelisWalletAssetTracked() ||
          xwf.XelisWalletAssetUntracked() => const XelisStateInvalidated(),
          xwf.XelisWalletBusinessEventStreamDegraded(:final failure) =>
            XelisStateInvalidated(failure: failure),
          xwf.XelisWalletBusinessEventStreamClosed(:final failure) =>
            XelisChannelClosed(failure, isRuntime: false),
        },
      ),
    );
  }

  @override
  Future<void> onlineMode(
    OpaqueXelisWallet wallet, {
    required String daemonAddress,
  }) => wallet.actual.setOnline(daemonAddress: daemonAddress);

  @override
  Future<void> offlineMode(OpaqueXelisWallet wallet) =>
      wallet.actual.setOffline();

  @override
  Future<void> closeWallet(OpaqueXelisWallet wallet) async {
    try {
      await wallet.actual.close();
    } finally {
      wallet.actual.dispose();
    }
  }

  @override
  Future<void> updateTables({
    required String precomputedTablesPath,
    required bool stack_l1Low,
  }) => xwf.XelisWalletFlutter.updatePrecomputedTables(
    path: precomputedTablesPath,
    type: _tableType(stack_l1Low),
  );

  @override
  Future<bool> hasTables({
    required String precomputedTablesPath,
    required bool stack_l1Low,
  }) => xwf.XelisWalletFlutter.hasPrecomputedTables(
    path: precomputedTablesPath,
    type: _tableType(stack_l1Low),
  );

  @override
  Future<String> getSeed(OpaqueXelisWallet wallet) => wallet.actual.getSeed();

  @override
  Future<OpaqueXelisWallet> createXelisWallet(
    String walletId, {
    required String name,
    required String directory,
    required String password,
    required CryptoCurrencyNetwork network,
    String? seed,
    String? privateKey,
    String? precomputedTablesPath,
    bool? stack_l1Low,
  }) async {
    if (privateKey != null)
      throw UnsupportedError('Stack Xelis uses mnemonic recovery');
    final walletPath = _walletPath(walletId, name, directory);
    final wallet = seed == null
        ? await xwf.XelisWalletFlutter.createWallet(
            walletPath: walletPath,
            password: password,
            network: _network(network),
            precomputedTablesPath: precomputedTablesPath,
            precomputedTableType: _tableType(stack_l1Low ?? true),
          )
        : await xwf.XelisWalletFlutter.recoverWalletFromSeed(
            walletPath: walletPath,
            password: password,
            seed: seed,
            network: _network(network),
            precomputedTablesPath: precomputedTablesPath,
            precomputedTableType: _tableType(stack_l1Low ?? true),
          );
    return OpaqueXelisWallet(wallet);
  }

  @override
  Future<OpaqueXelisWallet> openXelisWallet(
    String walletId, {
    required String name,
    required String directory,
    required String password,
    required CryptoCurrencyNetwork network,
    String? precomputedTablesPath,
    bool? stack_l1Low,
  }) async => OpaqueXelisWallet(
    await xwf.XelisWalletFlutter.openWallet(
      walletPath: _walletPath(walletId, name, directory),
      password: password,
      network: _network(network),
      precomputedTablesPath: precomputedTablesPath,
      precomputedTableType: _tableType(stack_l1Low ?? true),
    ),
  );

  @override
  String getAddress(OpaqueXelisWallet wallet) => wallet.actual.address;

  @override
  Future<XelisDaemonSnapshot> getDaemonInfo(OpaqueXelisWallet wallet) async {
    final info = await wallet.actual.getDaemonInfo();
    return XelisDaemonSnapshot(
      topoheight: info.topoheight,
      stableTopoheight: info.stableTopoheight,
      prunedTopoheight: info.prunedTopoheight,
    );
  }

  @override
  Future<bool> isOnline(OpaqueXelisWallet wallet) => wallet.actual.isOnline();
  @override
  Future<bool> isSyncing(OpaqueXelisWallet wallet) => wallet.actual.isSyncing();
  @override
  Future<void> rescan(OpaqueXelisWallet wallet, {required BigInt topoheight}) =>
      wallet.actual.rescan(topoheight: topoheight);
  @override
  Future<BigInt> getXelisBalanceRaw(OpaqueXelisWallet wallet) =>
      wallet.actual.getXelisBalance();

  @override
  Future<List<TransactionEntryWrapper>> allHistory(
    OpaqueXelisWallet wallet, {
    BigInt? minTopoheight,
  }) async {
    final pending = await wallet.actual.pendingTransactions();
    final confirmed = await wallet.actual.history(
      filter: xwf.XelisWalletHistoryFilter(
        page: BigInt.one,
        minTopoheight: minTopoheight,
      ),
    );
    // Confirmed state wins if the native wallet transitions during these reads.
    final byHash = {for (final tx in pending) tx.hash: _pending(tx)};
    for (final tx in confirmed) {
      byHash[tx.hash] = _confirmed(tx);
    }
    return byHash.values.toList();
  }

  @override
  Future<BigInt> estimateFees(
    OpaqueXelisWallet wallet, {
    required List<XelisTransfer> transfers,
  }) => wallet.actual.estimateTransferFees(
    transfers: transfers.map(_transfer).toList(),
  );

  @override
  Future<XelisPreparedTransaction> prepareTransfers(
    OpaqueXelisWallet wallet, {
    required List<XelisTransfer> transfers,
  }) async => _prepared(
    await wallet.actual.prepareTransfers(
      transfers: transfers.map(_transfer).toList(),
    ),
  );

  @override
  Future<XelisPreparedTransaction> prepareTransferAll(
    OpaqueXelisWallet wallet, {
    required String destination,
  }) async => _prepared(
    await wallet.actual.prepareTransferAll(
      destination: destination,
      asset: xelisAsset,
    ),
  );

  @override
  Future<void> discardPreparedTransaction(
    OpaqueXelisWallet wallet, {
    required XelisPreparedTransaction transaction,
  }) => wallet.actual.discardPreparedTransaction(
    transaction: transaction.handle<xwf.XelisWalletPreparedTransaction>(),
  );

  @override
  Future<XelisBroadcastOutcome> broadcastTransaction(
    OpaqueXelisWallet wallet, {
    required XelisPreparedTransaction transaction,
  }) async => switch (await wallet.actual.broadcastPreparedTransaction(
    transaction: transaction.handle<xwf.XelisWalletPreparedTransaction>(),
  )) {
    xwf.XelisWalletBroadcastSubmitted() => const XelisBroadcastOutcome(
      XelisBroadcastDisposition.submitted,
    ),
    xwf.XelisWalletBroadcastRetryable(:final failure) => XelisBroadcastOutcome(
      XelisBroadcastDisposition.retryable,
      failure: failure,
    ),
    xwf.XelisWalletBroadcastRejected(:final failure) => XelisBroadcastOutcome(
      XelisBroadcastDisposition.rejected,
      failure: failure,
    ),
    xwf.XelisWalletBroadcastLocalFailure(:final failure) =>
      XelisBroadcastOutcome(
        XelisBroadcastDisposition.localFailure,
        failure: failure,
      ),
    xwf.XelisWalletBroadcastSubmittedNeedsResync(:final failure) =>
      XelisBroadcastOutcome(
        XelisBroadcastDisposition.submittedNeedsResync,
        failure: failure,
      ),
  };

  @override
  Future<bool> testDaemonConnection(
    String endPoint,
    bool useSSL,
    CryptoCurrencyNetwork network,
  ) async {
    final daemon = sdk.DaemonClient(
      endPoint: endPoint,
      secureWebSocket: useSSL,
      timeout: 5000,
    );
    try {
      daemon.connect();
      final info = await daemon.getInfo();
      return info.network.name == _network(network).name;
    } on sdk.RpcException {
      return false;
    } finally {
      daemon.disconnect();
    }
  }
}

xwf.XelisNetwork _network(CryptoCurrencyNetwork network) => switch (network) {
  CryptoCurrencyNetwork.main => xwf.XelisNetwork.mainnet,
  CryptoCurrencyNetwork.test => xwf.XelisNetwork.testnet,
  CryptoCurrencyNetwork.stage => xwf.XelisNetwork.stagenet,
  _ => throw ArgumentError('Unsupported Xelis network'),
};

xwf.XelisPrecomputedTableType _tableType(bool low) => low
    ? const xwf.XelisPrecomputedTableType.l1Low()
    : const xwf.XelisPrecomputedTableType.l1Full();

String _walletPath(String walletId, String name, String directory) {
  if (walletId != name ||
      !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(name) ||
      name.toLowerCase() == 'table' ||
      path.isAbsolute(name)) {
    throw ArgumentError('Invalid Xelis wallet identifier');
  }
  return path.join(directory, name);
}

xwf.XelisWalletTransferRequest _transfer(XelisTransfer transfer) =>
    xwf.XelisWalletTransferRequest(
      destination: transfer.destination,
      asset: transfer.asset,
      amountAtomic: transfer.amountAtomic,
    );

XelisPreparedTransaction _prepared(
  xwf.XelisWalletPreparedTransaction transaction,
) {
  final details = transaction.details;
  if (details is! xwf.XelisWalletPreparedTransfers)
    throw StateError('Expected a Xelis transfer');
  return XelisPreparedTransaction(
    handle: transaction,
    hash: transaction.hash,
    feeAtomic: transaction.feeAtomic,
    transfers: details.transfers
        .map(
          (transfer) => XelisPreparedTransfer(
            destination: transfer.destination,
            amountAtomic: transfer.amountAtomic,
            asset: transfer.asset,
            hasExtraData: transfer.hasExtraData,
          ),
        )
        .toList(),
  );
}

TransactionEntryWrapper _confirmed(xwf.XelisWalletTransactionEntry tx) =>
    TransactionEntryWrapper(
      tx,
      entryType: _entry(tx.entry),
      hash: tx.hash,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        xelisStorageInt(tx.timestampMillis),
        isUtc: true,
      ),
      topoheight: tx.topoheight,
    );

TransactionEntryWrapper _pending(xwf.XelisWalletPendingTransaction tx) =>
    TransactionEntryWrapper(
      tx,
      entryType: _entry(tx.entry),
      hash: tx.hash,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        xelisStorageInt(tx.timestampMillis),
        isUtc: true,
      ),
      topoheight: null,
    );

EntryWrapper _entry(
  xwf.XelisWalletTransactionEntryData entry,
) => switch (entry) {
  xwf.XelisWalletCoinbaseEntry(:final reward) => CoinbaseEntryWrapper(
    reward: reward,
  ),
  xwf.XelisWalletBurnEntry(:final amount, :final fee, :final asset) =>
    BurnEntryWrapper(amount: amount, fee: fee, asset: asset),
  xwf.XelisWalletIncomingEntry(:final from, :final transfers) =>
    IncomingEntryWrapper(
      from: from,
      transfers: transfers
          .map((e) => (amount: e.amount, asset: e.asset, extraData: null))
          .toList(),
    ),
  xwf.XelisWalletOutgoingEntry(:final nonce, :final fee, :final transfers) =>
    OutgoingEntryWrapper(
      nonce: nonce,
      fee: fee,
      transfers: transfers
          .map(
            (e) => (
              destination: e.destination,
              amount: e.amount,
              asset: e.asset,
              extraData: null,
            ),
          )
          .toList(),
    ),
  xwf.XelisWalletMultisigEntry(:final fee, :final nonce) =>
    XelisActionEntryWrapper(
      kind: 'multisig',
      spent: BigInt.zero,
      received: BigInt.zero,
      fee: fee,
      nonce: nonce,
    ),
  xwf.XelisWalletOutgoingBlobEntry(:final fee, :final nonce) =>
    XelisActionEntryWrapper(
      kind: 'blob',
      spent: BigInt.zero,
      received: BigInt.zero,
      fee: fee,
      nonce: nonce,
    ),
  xwf.XelisWalletIncomingContractEntry(:final transfers) =>
    XelisActionEntryWrapper(
      kind: 'incoming_contract',
      spent: BigInt.zero,
      received: transfers
          .expand((group) => group.transfers)
          .where((e) => e.asset == sdk.xelisAsset)
          .fold(BigInt.zero, (sum, e) => sum + e.amount),
      fee: BigInt.zero,
    ),
  xwf.XelisWalletInvokeContractEntry(
    :final deposits,
    :final received,
    :final fee,
    :final maxGas,
    :final nonce,
  ) =>
    XelisActionEntryWrapper(
      kind: 'invoke_contract',
      spent: _xelAmounts(deposits) + maxGas,
      received: _xelAmounts(received.expand((group) => group.transfers)),
      fee: fee,
      nonce: nonce,
    ),
  xwf.XelisWalletDeployContractEntry(:final fee, :final nonce, :final invoke) =>
    XelisActionEntryWrapper(
      kind: 'deploy_contract',
      // Pinned core db59b5c: BURN_PER_CONTRACT = COIN_VALUE (1 XEL).
      spent:
          BigInt.from(100000000) +
          (invoke == null
              ? BigInt.zero
              : _xelAmounts(invoke.deposits) + invoke.maxGas),
      received: BigInt.zero,
      fee: fee,
      nonce: nonce,
    ),
  // A received blob moves no XEL and Stack has no messaging UI.
  xwf.XelisWalletIncomingBlobEntry() => UnknownEntryWrapper(),
};

BigInt _xelAmounts(Iterable<xwf.XelisWalletAssetAmount> amounts) => amounts
    .where((item) => item.asset == sdk.xelisAsset)
    .fold(BigInt.zero, (sum, item) => sum + item.amount);
//END_ON
