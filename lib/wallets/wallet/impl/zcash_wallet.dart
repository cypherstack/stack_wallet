import 'package:isar_community/isar.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../utilities/amount/amount.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_wallet.dart';
import '../intermediate/zcash_account_session.dart';

typedef ZcashAccountSessionFactory = ZcashAccountSession Function(
  CryptoCurrencyNetwork network,
);

class ZcashWallet extends Bip39Wallet<Zcash> {
  ZcashWallet(CryptoCurrencyNetwork network) : super(Zcash(network));

  ZcashAccountSessionFactory _accountSessionFactory = (network) =>
      ZcashAccountSession(network: network);
  ZcashAccountSession? _accountSession;

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
    final existing = await getCurrentReceivingAddress();
    final cached = info.cachedReceivingAddress;
    if ((existing != null && existing.value != derived.ua) ||
        (cached.isNotEmpty && cached != derived.ua)) {
      throw StateError('Zcash wallet address does not match the saved wallet');
    }
    if (existing == null) {
      await mainDB.updateOrPutAddresses([
        Address(
          walletId: walletId,
          value: derived.ua,
          publicKey: const [],
          derivationIndex: 0,
          derivationPath: null,
          type: AddressType.zcashUnified,
          subType: AddressSubType.receiving,
        ),
      ]);
    }
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
  }

  @override
  Future<void> updateTransactions() async => _unsupported();

  @override
  Future<void> updateBalance() async => _unsupported();

  @override
  Future<bool> updateUTXOs() async => _unsupported();

  @override
  Future<void> updateChainHeight() async => _unsupported();

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
    final session = _accountSession;
    _accountSession = null;
    await session?.close();
  }
}
