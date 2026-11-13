import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as path;
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/stack_file_system.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_wallet.dart';
import '../intermediate/zcash_account_session.dart';
import '../intermediate/zcash_wallet_state.dart';
import '../intermediate/zcash_wallet_state_controller.dart';

typedef ZcashAccountSessionFactory = ZcashAccountSession Function(
  CryptoCurrencyNetwork network,
);

class ZcashWallet extends Bip39Wallet<Zcash> {
  ZcashWallet(CryptoCurrencyNetwork network) : super(Zcash(network));

  ZcashAccountSessionFactory _accountSessionFactory = (network) =>
      ZcashAccountSession(network: network);
  ZcashAccountSession? _accountSession;
  ZcashWalletStateController? _stateController;
  String? _ufvk;
  String? _accountFingerprint;

  @override
  int get isarTransactionVersion => 2;

  int get accountSessionGeneration => _accountSession?.generation ?? 0;

  void configureAccountSessionFactory(ZcashAccountSessionFactory factory) {
    if (_accountSession != null) {
      throw StateError('The Zcash account session is already initialized');
    }
    _accountSessionFactory = factory;
  }

  @override
  FilterOperation? get changeAddressFilterOperation => null;

  @override
  FilterOperation get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  @override
  Future<void> init({bool? isRestore}) async {
    zcash.requireProductionWalletNativeCapabilities(zcash.nativeCapabilities());
    final seed = zcash.nativeMnemonicToSeed(
      await getMnemonic(),
      passphrase: await getMnemonicPassphrase(),
    );
    final derived = await zcash.deriveAddress(
      seedHex: seed.seedHex,
      network: cryptoCurrency.nativeNetwork,
    );
    final metadata = zcash.deriveNativeAccountMetadata(
      seedHex: seed.seedHex,
      network: cryptoCurrency.nativeNetwork,
    );
    _ufvk = metadata.ufvk;
    _accountFingerprint = sha256
        .convert(
          utf8.encode(
            '${cryptoCurrency.nativeNetwork.ffiLabel}|${metadata.ufvk}',
          ),
        )
        .toString();
    final existing = await getCurrentReceivingAddress();
    final cached = info.cachedReceivingAddress;
    if ((existing != null && existing.value != derived.ua) ||
        (cached.isNotEmpty && cached != derived.ua)) {
      throw StateError('Zcash wallet address does not match the saved wallet');
    }
    final receiverRows = _receiverRows(derived);
    final persisted = await mainDB.getAddresses(walletId).findAll();
    for (final expected in receiverRows) {
      final sameSlot = persisted.where(
        (address) =>
            address.type == expected.type &&
            address.subType == expected.subType &&
            address.derivationIndex == expected.derivationIndex,
      );
      if (sameSlot.isNotEmpty &&
          sameSlot.every((address) => address.value != expected.value)) {
        throw StateError(
          'Zcash wallet receiver does not match the saved wallet',
        );
      }
    }
    await mainDB.updateOrPutAddresses(receiverRows);
    var nodeReady = false;
    try {
      if (nodeService.getPrimaryNodeFor(currency: cryptoCurrency) != null) {
        await updateNode();
        nodeReady = true;
      }
      await super.init();
    } catch (_) {
      if (nodeReady) await _closeAccountSession();
      rethrow;
    }
  }

  @override
  Future<void> checkSaveInitialReceivingAddress() async {}

  Never _unsupported() => throw UnsupportedError(
    'Zcash chain operations are not part of the wallet identity slice',
  );

  @override
  Future<TxData> prepareSend({required TxData txData}) async => _unsupported();

  @override
  Future<TxData> confirmSend({required TxData txData}) async => _unsupported();

  @override
  Future<void> recover({required bool isRescan}) async => _unsupported();

  @override
  Future<void> updateNode() async {
    final node = nodeService.getPrimaryNodeFor(currency: cryptoCurrency);
    if (node == null) {
      throw StateError(
        'Zcash requires an explicitly configured primary lightwalletd node',
      );
    }
    final session = _accountSession ??= _accountSessionFactory(
      cryptoCurrency.network,
    );
    await session.replaceNode(node);
    _stateController = null;
    await _initializeStateController(session);
  }

  @override
  Future<void> updateTransactions() async {
    final snapshot = await _requireStateController().refresh();
    await mainDB.updateOrPutTransactionV2s(
      ZcashStackStateMapper(walletId: walletId).transactions(snapshot.history),
    );
  }

  @override
  Future<void> updateBalance() async {
    final snapshot = await _requireStateController().refresh();
    await info.updateBalance(
      newBalance: ZcashStackStateMapper(walletId: walletId)
          .balance(snapshot.balance),
      isar: mainDB.isar,
    );
  }

  @override
  Future<bool> updateUTXOs() async => false;

  @override
  Future<void> updateChainHeight() async {
    final snapshot = await _requireStateController().refresh();
    await info.updateCachedChainHeight(
      newHeight: snapshot.chainHeight,
      isar: mainDB.isar,
    );
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async =>
      _unsupported();

  @override
  Future<FeeObject> get fees async => _unsupported();

  @override
  Future<bool> pingCheck() async => await _accountSession?.ping() ?? false;

  @override
  Future<void> exit() async {
    await _closeAccountSession();
    await super.exit();
  }

  Future<void> _closeAccountSession() async {
    _stateController = null;
    final session = _accountSession;
    _accountSession = null;
    await session?.close();
  }

  ZcashWalletStateController _requireStateController() {
    final controller = _stateController;
    if (controller == null) {
      throw StateError(
        'Zcash sync requires an explicit lightwalletd node and a validated '
        'positive restore height',
      );
    }
    return controller;
  }

  Future<void> _initializeStateController(ZcashAccountSession session) async {
    final client = session.syncClient;
    if (client == null) return;
    final ufvk = _ufvk;
    final fingerprint = _accountFingerprint;
    if (ufvk == null || fingerprint == null) {
      throw StateError('Zcash account identity is not initialized');
    }
    final birthdayHeight = info.restoreHeight;
    if (birthdayHeight < 1) {
      throw StateError(
        'Zcash requires a validated positive restore height before syncing',
      );
    }
    final root = await StackFileSystem.applicationRootDirectory();
    final network = cryptoCurrency.nativeNetwork.ffiLabel;
    final source = _ZcashSessionSyncDataSource(client);
    _stateController = await ZcashWalletStateController.open(
      store: ZcashEncryptedWalletStateStore(
        path: path.join(root.path, 'zcash', '$walletId.state'),
        walletId: walletId,
        network: network,
        accountFingerprint: fingerprint,
        secureStorage: secureStorageInterface,
      ),
      accountFingerprint: fingerprint,
      network: network,
      birthdayHeight: birthdayHeight,
      loadBirthdayTreeState: source.getTreeState,
      scanExecutor: ZcashNativeIsolateScanExecutor(
        ufvk: ufvk,
        network: network,
      ),
      openSync: (state, executor) => openZcashSyncSession(
        state: state,
        source: source,
        scanExecutor: executor,
        network: network,
      ),
    );
  }

  List<Address> _receiverRows(zcash.UnifiedAddressSet derived) {
    final values = <(String, AddressType)>[
      (derived.ua, AddressType.zcashUnified),
      if (derived.saplingAddress case final address?)
        (address, AddressType.zcashSapling),
      if (derived.transparentAddress case final address?)
        (
          address,
          cryptoCurrency.getAddressType(address) ??
              (throw StateError(
                'Derived Zcash transparent receiver has no address type',
              )),
        ),
    ];
    return [
      for (final (value, type) in values)
        Address(
          walletId: walletId,
          value: value,
          publicKey: const [],
          derivationIndex: 0,
          derivationPath: null,
          type: type,
          subType: AddressSubType.receiving,
        ),
    ];
  }
}

class _ZcashSessionSyncDataSource implements ZcashSyncDataSource {
  const _ZcashSessionSyncDataSource(this.client);

  final ZcashLightwalletdSyncClient client;

  @override
  Future<String?> getBlockHash(int height) => client.getBlockHash(height);

  @override
  Future<zcash.ZcashLightwalletdScanSource> getBlockRange(int start, int end) =>
      client.getBlockRange(start, end);

  @override
  Future<int> getTipHeight() => client.getTipHeight();

  @override
  Future<zcash.TreeState> getTreeState(int height) =>
      client.getTreeState(height);
}
