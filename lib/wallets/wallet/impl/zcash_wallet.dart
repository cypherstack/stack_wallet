import 'package:isar_community/isar.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../utilities/amount/amount.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_wallet.dart';

class ZcashWallet extends Bip39Wallet<Zcash> {
  ZcashWallet(CryptoCurrencyNetwork network) : super(Zcash(network));

  @override
  FilterOperation? get changeAddressFilterOperation => null;

  @override
  FilterOperation get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  @override
  Future<void> init({bool? isRestore}) async {
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
    await super.init();
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
  Future<void> updateNode() async => _unsupported();

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
  Future<bool> pingCheck() async => false;
}
