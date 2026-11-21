import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grin_native/grin_native.dart';
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/address_label.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/isar/models/transaction_note.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/enums/sync_type_enum.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/spark_coin.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/grin_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

import '../../support/isar_test_utils.dart';
import '../../support/memory_secrets.dart';

export '../../support/memory_secrets.dart';

/// Text a counterparty or node could put in a library error. Tests assert it
/// never reaches user strings or logs.
const remoteText = 'REMOTE-TEXT-from-node';

GrinException grinError(int code, {Map<String, Object?>? details}) =>
    GrinException.fromJson(
      code,
      jsonEncode({'code': code, 'message': remoteText, 'details': details}),
    );

typedef NetworkUpdate = ({
  String nodeUrl,
  String? apiSecret,
  String? socksProxy,
  bool networkEnabled,
});

/// A scripted [GrinWalletApi] that records what it was asked.
class FakeGrinWalletApi implements GrinWalletApi {
  FakeGrinWalletApi({required this.walletDir, required this.network});

  @override
  final String walletDir;
  @override
  final GrinNetwork network;

  final calls = <String>[];
  final networkUpdates = <NetworkUpdate>[];
  final transactionRefreshes = <bool>[];
  final balanceRefreshes = <bool>[];
  final initSends = <GrinSendArgs>[];
  final httpSends = <GrinHttpSendArgs>[];
  final invoicePayments = <GrinProcessInvoiceArgs>[];
  final cancelled = <({int? txId, String? slateId})>[];

  String address = 'grin1ownaddress';
  GrinBalance balance = balanceOf();
  GrinTxList transactions = const GrinTxList(
    refreshedFromNode: true,
    transactions: [],
  );
  GrinFeeEstimate fee = GrinFeeEstimate(
    fee: GrinBigInts.fee,
    amount: GrinBigInts.zero,
    netAmount: GrinBigInts.zero,
    total: GrinBigInts.zero,
    inputsCount: 1,
    changeOutputs: 1,
  );
  Object? estimateError;
  Object? sendError;
  Object? scanError;
  Object? finalizeError;
  Object? invoiceError;
  Object? repostError;
  Object? verifyError;

  /// Fails a cancel by log id, or by slate id under the key -1.
  final cancelErrors = <int, Object>{};

  /// The fee initSend reports, if not the estimate's.
  BigInt? sendFee;

  /// Fails the next close once; the wallet stays open.
  Object? closeError;
  GrinSlateInfo? decoded;
  final reposts = <({int? txId, String? slateId})>[];
  int lastScanned = 0;
  int cancelScannedHeight = 0;

  Completer<GrinScanResult>? _scan;
  bool scanBlocks = false;
  GrinScanProgress progress = const GrinScanProgress(
    isScanning: false,
    cancelRequested: false,
    startHeight: 0,
    scannedHeight: 0,
    tipHeight: 0,
    progressPct: 0,
  );

  Completer<void>? closeGate;
  bool _closed = false;
  final _events = StreamController<GrinWalletEvent>.broadcast();

  bool get scanRunning => _scan != null && !_scan!.isCompleted;

  /// Ends a blocked scan successfully.
  void finishScan() =>
      _scan?.complete(const GrinScanResult(scannedHeight: 100, tipHeight: 100));

  void _check(String call) {
    if (_closed) throw StateError('closed');
    calls.add(call);
  }

  @override
  bool get isClosed => _closed;

  @override
  Stream<GrinWalletEvent> get events => _events.stream;

  @override
  Future<GrinAddressInfo> getAddress({int index = 0}) async {
    _check('getAddress');
    return GrinAddressInfo(
      slatepackAddress: address,
      onionV3Url: 'http://own.onion',
      index: index,
    );
  }

  @override
  Future<GrinChainTip> getChainHeight() async {
    _check('getChainHeight');
    return const GrinChainTip(height: 100, hash: 'tip');
  }

  @override
  Future<GrinBalance> getBalance({
    bool refreshFromNode = true,
    int minimumConfirmations = 10,
  }) async {
    _check('getBalance');
    balanceRefreshes.add(refreshFromNode);
    return balance;
  }

  @override
  Future<GrinScanResult> scan({
    int startHeight = 0,
    bool deleteUnconfirmed = false,
  }) async {
    _check('scan:$startHeight:$deleteUnconfirmed');
    if (scanError != null) throw scanError!;
    if (!scanBlocks) {
      return const GrinScanResult(scannedHeight: 100, tipHeight: 100);
    }
    final scan = _scan = Completer<GrinScanResult>();
    return scan.future;
  }

  @override
  GrinScanProgress scanProgress() {
    if (_closed) throw StateError('closed');
    return progress;
  }

  @override
  void cancelScan() {
    if (_closed) throw StateError('closed');
    calls.add('cancelScan');
    final scan = _scan;
    if (scan != null && !scan.isCompleted) {
      scan.completeError(
        grinError(14, details: {'scanned_height': cancelScannedHeight}),
      );
    }
  }

  @override
  Future<int> lastScannedHeight() async {
    _check('lastScannedHeight');
    return lastScanned;
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) =>
      throw UnimplementedError();

  @override
  Future<String> getMnemonic(String password) => throw UnimplementedError();

  @override
  Future<void> updateNetwork({
    required String nodeUrl,
    required String? apiSecret,
    required String? socksProxy,
    required bool networkEnabled,
  }) async {
    _check('updateNetwork');
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
  }) async {
    _check('estimateFee');
    if (estimateError != null) throw estimateError!;
    final net = amountIncludesFee ? amount - fee.fee : amount;
    return GrinFeeEstimate(
      fee: fee.fee,
      amount: net,
      netAmount: net,
      total: net + fee.fee,
      inputsCount: fee.inputsCount,
      changeOutputs: fee.changeOutputs,
    );
  }

  @override
  Future<GrinTxList> getTransactions({bool refreshFromNode = true}) async {
    _check('getTransactions');
    transactionRefreshes.add(refreshFromNode);
    return transactions;
  }

  @override
  Future<GrinSlateInfo> decodeSlatepack(
    String armored, {
    int secretIndex = 0,
  }) async {
    _check('decodeSlatepack');
    final info = decoded;
    if (info == null) throw grinError(11);
    return info;
  }

  @override
  Future<GrinSlatepack> initSend(GrinSendArgs args) async {
    _check('initSend');
    if (sendError != null) throw sendError!;
    initSends.add(args);
    return slatepackOf(GrinSlateState.s1, amount: args.amount, fee: sendFee);
  }

  @override
  Future<GrinSendResult> sendHttp(GrinHttpSendArgs args) async {
    _check('sendHttp');
    if (sendError != null) throw sendError!;
    httpSends.add(args);
    return GrinSendResult(
      slateId: 'slate-http',
      state: GrinSlateState.s3,
      amount: args.amount,
      fee: GrinBigInts.fee,
      kernelExcess: '08ab',
      posted: true,
    );
  }

  @override
  Future<GrinSlatepack> receiveSlatepack(String armoredS1) async {
    _check('receiveSlatepack');
    return slatepackOf(GrinSlateState.s2);
  }

  @override
  Future<GrinFinalizeResult> finalizeSlatepack(
    String armoredS2, {
    bool broadcast = true,
    bool fluff = false,
  }) async {
    _check('finalizeSlatepack');
    if (finalizeError != null) throw finalizeError!;
    return finalizedOf();
  }

  @override
  Future<GrinSlatepack> issueInvoice(GrinInvoiceArgs args) async {
    _check('issueInvoice');
    return slatepackOf(GrinSlateState.i1, amount: args.amount);
  }

  @override
  Future<GrinSlatepack> processInvoice(
    String armoredI1,
    GrinProcessInvoiceArgs args,
  ) async {
    _check('processInvoice');
    invoicePayments.add(args);
    if (invoiceError != null) throw invoiceError!;
    return slatepackOf(GrinSlateState.i2);
  }

  @override
  Future<GrinFinalizeResult> finalizeInvoice(
    String armoredI2, {
    bool broadcast = true,
    bool fluff = false,
  }) async {
    _check('finalizeInvoice');
    if (finalizeError != null) throw finalizeError!;
    return finalizedOf();
  }

  @override
  Future<void> repost({int? txId, String? slateId, bool fluff = false}) async {
    _check('repost');
    if (repostError != null) throw repostError!;
    reposts.add((txId: txId, slateId: slateId));
  }

  @override
  Future<void> cancelTransaction({int? txId, String? slateId}) async {
    _check('cancelTransaction');
    final error = cancelErrors[txId ?? -1];
    if (error != null) throw error;
    cancelled.add((txId: txId, slateId: slateId));
  }

  @override
  Future<GrinPaymentProof> exportPaymentProof({
    int? txId,
    String? slateId,
  }) async {
    _check('exportPaymentProof');
    return GrinPaymentProof.fromJson({
      'amount': 1,
      'excess': '08ab',
      'recipient_address': 'grin1recipient',
      'sender_address': address,
      'recipient_sig': 'r',
      'sender_sig': 's',
    });
  }

  @override
  Future<GrinPaymentProofVerification> verifyPaymentProof(
    GrinPaymentProof proof,
  ) async {
    _check('verifyPaymentProof');
    if (verifyError != null) throw verifyError!;
    return const GrinPaymentProofVerification(
      isSender: true,
      isRecipient: false,
    );
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    calls.add('close');
    final error = closeError;
    if (error != null) {
      closeError = null;
      throw error;
    }
    _closed = true;
    final scan = _scan;
    if (scan != null && !scan.isCompleted) scan.completeError(grinError(14));
    await closeGate?.future;
    calls.add('closed');
    await _events.close();
  }
}

abstract final class GrinBigInts {
  static final zero = BigInt.zero;
  static final fee = BigInt.from(23500000);
}

GrinBalance balanceOf({
  int spendable = 0,
  int awaitingConfirmation = 0,
  int immature = 0,
  int awaitingFinalization = 0,
  int locked = 0,
}) => GrinBalance(
  lastConfirmedHeight: 100,
  minimumConfirmations: 10,
  total: BigInt.from(spendable + awaitingConfirmation + immature),
  amountAwaitingFinalization: BigInt.from(awaitingFinalization),
  amountAwaitingConfirmation: BigInt.from(awaitingConfirmation),
  amountImmature: BigInt.from(immature),
  amountCurrentlySpendable: BigInt.from(spendable),
  amountLocked: BigInt.from(locked),
  amountReverted: BigInt.zero,
  refreshedFromNode: true,
);

GrinSlatepack slatepackOf(
  GrinSlateState state, {
  BigInt? amount,
  BigInt? fee,
}) => GrinSlatepack(
  slateId: 'slate-${state.wireName}',
  state: state,
  armoredSlatepack: 'BEGINSLATEPACK. secret ENDSLATEPACK.',
  amount: amount ?? BigInt.zero,
  fee: fee ?? GrinBigInts.fee,
  sender: 'grin1sender',
  recipients: const [],
  isEncrypted: false,
);

GrinFinalizeResult finalizedOf() => GrinFinalizeResult(
  slateId: 'slate-S3',
  state: GrinSlateState.s3,
  amount: BigInt.zero,
  fee: GrinBigInts.fee,
  kernelExcess: '08ab',
  posted: true,
  armoredSlatepack: 'BEGINSLATEPACK. final ENDSLATEPACK.',
);

GrinSlateInfo slateInfoOf(GrinSlateState state, {required int amount}) =>
    GrinSlateInfo(
      slateId: 'slate-in',
      state: state,
      amount: BigInt.from(amount),
      fee: BigInt.zero,
      kernelExcess: null,
      sender: null,
      recipients: const [],
      ttlCutoffHeight: null,
      numParticipants: 2,
      isEncrypted: false,
      slateJson: '{"secret":"slate"}',
    );

typedef CreateCall = ({
  GrinWalletConfig config,
  String? mnemonic,
  String password,
  bool isNewWallet,
});

/// A scripted [GrinWalletBackend].
class FakeGrinBackend implements GrinWalletBackend {
  final calls = <String>[];
  final creates = <CreateCall>[];
  final opens = <GrinWalletConfig>[];
  final deletes = <String>[];
  final nodeTests =
      <({String nodeUrl, String? apiSecret, String? socksProxy})>[];
  final apis = <FakeGrinWalletApi>[];

  /// Directories that hold a wallet, with its password.
  final wallets = <String, String>{};

  /// Runs before create, so a test can look at storage at that moment.
  void Function(CreateCall call)? onCreate;
  Object? createError;
  Object? deleteError;
  Object? nodeError;
  Object? decodeError;
  int nodeHeight = 4096748;

  /// New wallets' scans wait for [FakeGrinWalletApi.finishScan] or a cancel.
  bool scanBlocks = false;

  FakeGrinWalletApi get api => apis.last;

  FakeGrinWalletApi _newApi(GrinWalletConfig config) {
    final api = FakeGrinWalletApi(
      walletDir: config.walletDir,
      network: config.network,
    )..scanBlocks = scanBlocks;
    apis.add(api);
    return api;
  }

  @override
  Future<GrinWalletApi> create({
    required GrinWalletConfig config,
    String? mnemonic,
    required String password,
    bool isNewWallet = false,
  }) async {
    calls.add('create');
    final call = (
      config: config,
      mnemonic: mnemonic,
      password: password,
      isNewWallet: isNewWallet,
    );
    onCreate?.call(call);
    creates.add(call);
    final error = createError;
    if (error != null) {
      createError = null;
      throw error;
    }
    if (wallets.containsKey(config.walletDir)) throw grinError(6);
    wallets[config.walletDir] = password;
    return _newApi(config);
  }

  @override
  Future<GrinWalletApi> open({
    required GrinWalletConfig config,
    required String password,
  }) async {
    calls.add('open');
    opens.add(config);
    final stored = wallets[config.walletDir];
    if (stored == null) throw grinError(4);
    if (stored != password) throw grinError(5);
    return _newApi(config);
  }

  @override
  Future<void> delete({required String walletDir}) async {
    calls.add('delete');
    deletes.add(walletDir);
    if (deleteError != null) throw deleteError!;
    wallets.remove(walletDir);
  }

  @override
  Future<GrinNodeInfo> testNodeConnection({
    required String nodeUrl,
    String? apiSecret,
    String? socksProxy,
  }) async {
    calls.add('testNodeConnection');
    nodeTests.add((
      nodeUrl: nodeUrl,
      apiSecret: apiSecret,
      socksProxy: socksProxy,
    ));
    if (nodeError != null) throw nodeError!;
    return GrinNodeInfo(
      nodeVersion: '5.3.0',
      blockHeaderVersion: 5,
      height: nodeHeight,
      hash: 'tip',
    );
  }

  @override
  GrinAddressValidation validateAddressSync(
    String address,
    GrinNetwork network,
  ) {
    final text = address.trim();
    final prefix = network.usesTestPrefix ? 'tgrin1' : 'grin1';
    if (text.startsWith(prefix)) {
      return GrinAddressValidation(
        kind: GrinAddressKind.slatepack,
        slatepackAddress: text,
        url: 'http://x.onion',
      );
    }
    if (text.contains('.onion')) {
      return GrinAddressValidation(kind: GrinAddressKind.onion, url: text);
    }
    if (text.startsWith('http://') || text.startsWith('https://')) {
      return GrinAddressValidation(kind: GrinAddressKind.http, url: text);
    }
    throw grinError(21);
  }

  @override
  Future<GrinAddressValidation> validateAddress(
    String address,
    GrinNetwork network,
  ) async => validateAddressSync(address, network);

  @override
  Future<String> generateMnemonic({int wordCount = 24}) =>
      throw UnimplementedError();

  @override
  Future<GrinMnemonicValidation> validateMnemonic(String mnemonic) =>
      throw UnimplementedError();

  @override
  Future<GrinSlateInfo> decodeSlatepackWithoutWallet(
    String armored,
    GrinNetwork network,
  ) async {
    calls.add('decodeSlatepackWithoutWallet');
    if (decodeError != null) throw decodeError!;
    return slateInfoOf(GrinSlateState.s1, amount: 1);
  }
}

class FakeTorService extends Fake implements TorService {
  TorConnectionStatus current = TorConnectionStatus.disconnected;
  int port = 9050;

  @override
  TorConnectionStatus get status => current;

  @override
  ({InternetAddress host, int port}) getProxyInfo() {
    if (current != TorConnectionStatus.connected) {
      throw StateError('Tor not connected');
    }
    return (host: InternetAddress.loopbackIPv4, port: port);
  }
}

class GrinTestPrefs extends Fake implements Prefs {
  bool tor = false;
  bool killSwitch = true;

  @override
  bool get useTor => tor;
  @override
  bool get torKillSwitch => killSwitch;
  @override
  SyncingType get syncType => SyncingType.allWalletsOnStartup;
  @override
  List<String> get walletIdsSyncOnStartup => const [];
}

const testMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon abandon abandon abandon abandon art';

NodeModel grinNode({
  String host = 'https://grinnode.live',
  int port = 3413,
  bool tor = true,
  bool clear = true,
  String? secret,
}) => NodeModel(
  host: host,
  port: port,
  name: 'node',
  id: 'node',
  useSSL: host.startsWith('https'),
  enabled: true,
  coinName: 'grin',
  isFailover: false,
  isDown: false,
  torEnabled: tor,
  clearnetEnabled: clear,
  isPrimary: true,
  nodeApiSecret: secret,
);

/// A [GrinWallet] wired to fakes and an in-memory set of services.
class GrinTestWallet extends GrinWallet {
  bool mobileScanLifecycle = false;

  @override
  bool get cancelScanOnPause => mobileScanLifecycle;

  GrinTestWallet({
    required this.testWalletId,
    required FakeGrinBackend backend,
    required FakeTorService tor,
    required EventBus bus,
    required MemorySecrets secrets,
    required GrinTestPrefs testPrefs,
  }) : super(
         CryptoCurrencyNetwork.main,
         backend: backend,
         torService: tor,
         eventBus: bus,
       ) {
    mainDB = MainDB.instance;
    secureStorageInterface = secrets;
    prefs = testPrefs;
  }

  final String testWalletId;
  NodeModel node = grinNode();
  bool torFeature = true;

  @override
  String get walletId => testWalletId;

  @override
  NodeModel getCurrentNode() => node;

  @override
  bool get torFeatureEnabled => torFeature;
}

/// Everything a wallet test needs, made fresh per test.
class GrinHarness {
  GrinHarness._(this.walletId);

  final String walletId;
  final backend = FakeGrinBackend();
  final tor = FakeTorService();
  final bus = EventBus();
  final secrets = MemorySecrets({});
  final prefs = GrinTestPrefs();
  late final GrinTestWallet wallet = newWallet();

  GrinTestWallet newWallet() => GrinTestWallet(
    testWalletId: walletId,
    backend: backend,
    tor: tor,
    bus: bus,
    secrets: secrets,
    testPrefs: prefs,
  );

  static int _sequence = 0;

  /// A WalletInfo and mnemonic for a new wallet id.
  static Future<GrinHarness> create({
    int restoreHeight = 0,
    String? otherDataJsonString,
  }) async {
    final harness = GrinHarness._('grin-test-${_sequence++}');
    await MainDB.instance.putWalletInfo(
      WalletInfo(
        walletId: harness.walletId,
        name: 'fixture',
        mainAddressType: AddressType.mimbleWimble,
        coinName: 'grin',
        restoreHeight: restoreHeight,
        otherDataJsonString: otherDataJsonString,
      ),
    );
    harness.secrets.values[Wallet.mnemonicKey(walletId: harness.walletId)] =
        testMnemonic;
    harness.secrets.values[Wallet.mnemonicPassphraseKey(
          walletId: harness.walletId,
        )] =
        '';
    return harness;
  }

  /// Cleans up the wallet so the static owner map does not leak into the
  /// next test.
  Future<void> dispose() async {
    try {
      await wallet.exit();
    } catch (_) {}
  }
}

/// Opens an Isar for the test and points MainDB at it. Call in setUp.
Future<Isar> openTestIsar(Directory root) async {
  final isar = await Isar.open(
    [
      WalletInfoSchema,
      TransactionV2Schema,
      AddressSchema,
      TransactionSchema,
      UTXOSchema,
      SparkCoinSchema,
      AddressLabelSchema,
      TransactionNoteSchema,
    ],
    directory: root.path,
    name: 'grin-test',
    inspector: false,
  );
  await MainDB.instance.initMainDB(mock: isar);
  return isar;
}

/// One-time setup for tests that use Isar and the Grin data directory.
///
/// The data root is given to StackFileSystem as a path relative to the
/// working directory, so tests can check the wallet directory is made
/// absolute. Returns the root; delete it in tearDownAll.
Future<Directory> setUpGrinTests() async {
  final root = await Directory.systemTemp.createTemp('stack_grin_');
  StackFileSystem.setDesktopOverrideDir(p.relative(root.path));
  await initializeTestIsar();
  return root;
}

/// A Grin log entry with defaults.
GrinTxLogEntry entryOf({
  required int id,
  String? slateId = 'slate-1',
  GrinTxType type = GrinTxType.txSent,
  GrinSlateState? state = GrinSlateState.s1,
  bool confirmed = false,
  int? confirmedHeight,
  int credited = 0,
  int debited = 0,
  int? fee = 8000000,
  String? counterparty,
  String? kernelExcess,
  bool hasStoredTx = false,
  String? armored,
  int? ttl,
  GrinPaymentProofSummary? proof,
}) => GrinTxLogEntry(
  id: id,
  slateId: slateId,
  slateState: state,
  type: type,
  creationTime: DateTime.utc(2026, 11, 7),
  confirmationTime: null,
  confirmed: confirmed,
  confirmedHeight: confirmedHeight,
  numInputs: debited > 0 ? 1 : 0,
  numOutputs: credited > 0 ? 1 : 0,
  amountCredited: BigInt.from(credited),
  amountDebited: BigInt.from(debited),
  fee: fee == null ? null : BigInt.from(fee),
  ttlCutoffHeight: ttl,
  kernelExcess: kernelExcess,
  kernelLookupMinHeight: confirmed ? 1 : null,
  hasStoredTx: hasStoredTx,
  paymentProof: proof,
  counterpartyAddress: counterparty,
  armoredSlatepack: armored,
  revertedAfterSecs: null,
);

/// Waits until [check] holds, for work that finishes on Isar's thread.
Future<void> eventually(bool Function() check, {String? reason}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!check()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('timed out waiting${reason == null ? '' : ': $reason'}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
