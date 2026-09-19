//ON
import 'package:cs_wownero/cs_wownero.dart' as lib_wownero;
import 'package:cs_wownero/src/deprecated/get_height_by_date.dart'
    as cs_wownero_deprecated;
import 'package:cs_wownero/src/ffi_bindings/wownero_wallet_bindings.dart'
    as wow_wallet_ffi;

//END_ON
import '../../models/input.dart';
import '../interfaces/cs_monero_interface.dart';
import '../interfaces/cs_salvium_interface.dart' show WrappedWallet;
import '../interfaces/cs_wownero_interface.dart';

CsWowneroInterface get csWownero => _getInterface();

//OFF
CsWowneroInterface _getInterface() => throw Exception("WOW not enabled!");

//END_OFF
//ON
CsWowneroInterface _getInterface() => const _CsWowneroInterfaceImpl();

class _CsWowneroInterfaceImpl extends CsWowneroInterface {
  const _CsWowneroInterfaceImpl();

  @override
  void setUseCsWowneroLoggerInternal(bool enable) =>
      lib_wownero.Logging.useLogger = enable;

  @override
  bool walletExists(String path) =>
      lib_wownero.WowneroWallet.isWalletExist(path);

  @override
  Future<int> estimateFee(
    int rate,
    BigInt amount, {
    required WrappedWallet wallet,
  }) {
    lib_wownero.TransactionPriority priority;
    switch (rate) {
      case 1:
        priority = lib_wownero.TransactionPriority.low;
        break;
      case 2:
        priority = lib_wownero.TransactionPriority.medium;
        break;
      case 3:
        priority = lib_wownero.TransactionPriority.high;
        break;
      case 4:
        priority = lib_wownero.TransactionPriority.last;
        break;
      case 0:
      default:
        priority = lib_wownero.TransactionPriority.normal;
        break;
    }

    return wallet.get<lib_wownero.Wallet>().estimateFee(
      priority,
      amount.toInt(),
    );
  }

  @override
  Future<WrappedWallet> loadWallet(
    String walletId, {
    required String path,
    required String password,
  }) async {
    return WrappedWallet(
      await lib_wownero.WowneroWallet.loadWallet(
        path: path,
        password: password,
      ),
    );
  }

  @override
  int getTxPriorityHigh() => lib_wownero.TransactionPriority.high.value;

  @override
  int getTxPriorityMedium() => lib_wownero.TransactionPriority.medium.value;

  @override
  int getTxPriorityNormal() => lib_wownero.TransactionPriority.normal.value;

  @override
  String getAddress(
    WrappedWallet wallet, {
    int accountIndex = 0,
    int addressIndex = 0,
  }) => wallet
      .get<lib_wownero.Wallet>()
      .getAddress(accountIndex: accountIndex, addressIndex: addressIndex)
      .value;

  @override
  Future<WrappedWallet> getCreatedWallet({
    required String path,
    required String password,
    required int wordCount,
    required String seedOffset,
  }) async {
    final type = switch (wordCount) {
      16 => lib_wownero.WowneroSeedType.sixteen,
      25 => lib_wownero.WowneroSeedType.twentyFive,
      _ => throw Exception("Invalid mnemonic word count: $wordCount"),
    };

    final wallet = await lib_wownero.WowneroWallet.create(
      path: path,
      password: password,
      seedType: type,
      seedOffset: seedOffset,
    );

    return WrappedWallet(wallet);
  }

  @override
  Future<WrappedWallet> getRestoredWallet({
    required String walletId,

    required String path,
    required String password,
    required String mnemonic,
    required String seedOffset,
    int height = 0,
  }) async {
    return WrappedWallet(
      await lib_wownero.WowneroWallet.restoreWalletFromSeed(
        path: path,
        password: password,
        seed: mnemonic,
        restoreHeight: height,
        seedOffset: seedOffset,
      ),
    );
  }

  @override
  Future<WrappedWallet> getRestoredFromViewKeyWallet({
    required String walletId,

    required String path,
    required String password,
    required String address,
    required String privateViewKey,
    int height = 0,
  }) async {
    return WrappedWallet(
      await lib_wownero.WowneroWallet.createViewOnlyWallet(
        path: path,
        password: password,
        address: address,
        viewKey: privateViewKey,
        restoreHeight: height,
      ),
    );
  }

  @override
  String getTxKey(WrappedWallet wallet, String txid) =>
      wallet.get<lib_wownero.Wallet>().getTxKey(txid);

  @override
  Future<void> save(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().save();

  @override
  String getPublicViewKey(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().getPublicViewKey();

  @override
  String getPrivateViewKey(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().getPrivateViewKey();

  @override
  String getPublicSpendKey(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().getPublicSpendKey();

  @override
  String getPrivateSpendKey(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().getPrivateSpendKey();

  @override
  Future<bool> isSynced(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().isSynced();

  @override
  void startSyncing(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().startSyncing();

  @override
  void stopSyncing(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().stopSyncing();

  @override
  void startAutoSaving(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().startAutoSaving();

  @override
  void stopAutoSaving(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().stopAutoSaving();

  @override
  bool hasListeners(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().getListeners().isNotEmpty;

  @override
  void addListener(WrappedWallet wallet, CsWalletListener listener) =>
      wallet.get<lib_wownero.Wallet>().addListener(
        lib_wownero.WalletListener(
          onSyncingUpdate: listener.onSyncingUpdate,
          onNewBlock: listener.onNewBlock,
          onBalancesChanged: listener.onBalancesChanged,
          onError: listener.onError,
        ),
      );

  @override
  void startListeners(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().startListeners();

  @override
  void stopListeners(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().stopListeners();

  @override
  int getRefreshFromBlockHeight(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().getRefreshFromBlockHeight();

  @override
  void setRefreshFromBlockHeight(WrappedWallet wallet, int height) =>
      wallet.get<lib_wownero.Wallet>().setRefreshFromBlockHeight(height);

  @override
  Future<bool> rescanBlockchain(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().rescanBlockchain();

  @override
  Future<bool> isConnectedToDaemon(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().isConnectedToDaemon();

  @override
  Future<void> connect(
    WrappedWallet wallet, {
    required String daemonAddress,
    required bool trusted,
    String? daemonUsername,
    String? daemonPassword,
    bool useSSL = false,
    bool isLightWallet = false,
    String? socksProxyAddress,
  }) async {
    await wallet.get<lib_wownero.Wallet>().connect(
      daemonAddress: daemonAddress,
      trusted: trusted,
      daemonUsername: daemonUsername,
      daemonPassword: daemonPassword,
      useSSL: useSSL,
      socksProxyAddress: socksProxyAddress,
      isLightWallet: isLightWallet,
    );
  }

  @override
  Future<List<String>> getAllTxids(
    WrappedWallet wallet, {
    bool refresh = false,
  }) => wallet.get<lib_wownero.Wallet>().getAllTxids(refresh: refresh);

  @override
  BigInt? getBalance(WrappedWallet wallet, {int accountIndex = 0}) =>
      wallet.get<lib_wownero.Wallet>().getBalance(accountIndex: accountIndex);

  @override
  BigInt? getUnlockedBalance(WrappedWallet wallet, {int accountIndex = 0}) =>
      wallet.get<lib_wownero.Wallet>().getUnlockedBalance(
        accountIndex: accountIndex,
      );

  @override
  Future<List<CsTransaction>> getAllTxs(
    WrappedWallet wallet, {
    bool refresh = false,
  }) async {
    final transactions = await wallet.get<lib_wownero.Wallet>().getAllTxs(
      refresh: refresh,
    );
    return transactions
        .map(
          (e) => CsTransaction(
            displayLabel: e.displayLabel,
            description: e.description,
            fee: e.fee,
            confirmations: e.confirmations,
            blockHeight: e.blockHeight,
            accountIndex: e.accountIndex,
            addressIndexes: e.addressIndexes,
            paymentId: e.paymentId,
            amount: e.amount,
            isSpend: e.isSpend,
            hash: e.hash,
            key: e.key,
            timeStamp: e.timeStamp,
            minConfirms: e.minConfirms.value,
          ),
        )
        .toList();
  }

  @override
  Future<List<CsTransaction>> getTxs(
    WrappedWallet wallet, {
    required Set<String> txids,
    bool refresh = false,
  }) async {
    final transactions = await wallet.get<lib_wownero.Wallet>().getTxs(
      txids: txids,
      refresh: refresh,
    );
    return transactions
        .map(
          (e) => CsTransaction(
            displayLabel: e.displayLabel,
            description: e.description,
            fee: e.fee,
            confirmations: e.confirmations,
            blockHeight: e.blockHeight,
            accountIndex: e.accountIndex,
            addressIndexes: e.addressIndexes,
            paymentId: e.paymentId,
            amount: e.amount,
            isSpend: e.isSpend,
            hash: e.hash,
            key: e.key,
            timeStamp: e.timeStamp,
            minConfirms: e.minConfirms.value,
          ),
        )
        .toList();
  }

  @override
  Future<CsPendingTransaction> createTx(
    WrappedWallet wallet, {
    required CsRecipient output,
    required int priority,
    required bool sweep,
    List<StandardInput>? preferredInputs,
    required int accountIndex,
    required int minConfirms,
    required int currentHeight,
  }) async {
    final pending = await wallet.get<lib_wownero.Wallet>().createTx(
      output: lib_wownero.Recipient(
        address: output.address,
        amount: output.amount,
      ),
      paymentId: "",
      sweep: sweep,
      priority: lib_wownero.TransactionPriority.values.firstWhere(
        (e) => e.value == priority,
      ),
      preferredInputs: preferredInputs
          ?.map(
            (e) => lib_wownero.Output(
              address: e.address!,
              hash: e.utxo.txid,
              keyImage: e.utxo.keyImage!,
              value: e.value,
              isFrozen: e.utxo.isBlocked,
              isUnlocked:
                  e.utxo.blockHeight != null &&
                  (currentHeight - (e.utxo.blockHeight ?? 0)) >= minConfirms,
              height: e.utxo.blockHeight ?? 0,
              vout: e.utxo.vout,
              spent: e.utxo.used ?? false,
              spentHeight: null, // doesn't matter here
              coinbase: e.utxo.isCoinbase,
            ),
          )
          .toList(),
      accountIndex: accountIndex,
    );

    return CsPendingTransaction(
      pending,
      pending.amount,
      pending.fee,
      pending.txid,
    );
  }

  @override
  Future<CsPendingTransaction> createTxMultiDest(
    WrappedWallet wallet, {
    required List<CsRecipient> outputs,
    required int priority,
    required bool sweep,
    List<StandardInput>? preferredInputs,
    required int accountIndex,
    required int minConfirms,
    required int currentHeight,
  }) async {
    final pending = await wallet.get<lib_wownero.Wallet>().createTxMultiDest(
      outputs: outputs
          .map(
            (e) => lib_wownero.Recipient(address: e.address, amount: e.amount),
          )
          .toList(),
      paymentId: "",
      sweep: sweep,
      priority: lib_wownero.TransactionPriority.values.firstWhere(
        (e) => e.value == priority,
      ),
      preferredInputs: preferredInputs
          ?.map(
            (e) => lib_wownero.Output(
              address: e.address!,
              hash: e.utxo.txid,
              keyImage: e.utxo.keyImage!,
              value: e.value,
              isFrozen: e.utxo.isBlocked,
              isUnlocked:
                  e.utxo.blockHeight != null &&
                  (currentHeight - (e.utxo.blockHeight ?? 0)) >= minConfirms,
              height: e.utxo.blockHeight ?? 0,
              vout: e.utxo.vout,
              spent: e.utxo.used ?? false,
              spentHeight: null, // doesn't matter here
              coinbase: e.utxo.isCoinbase,
            ),
          )
          .toList(),
      accountIndex: accountIndex,
    );

    return CsPendingTransaction(
      pending,
      pending.amount,
      pending.fee,
      pending.txid,
    );
  }

  @override
  Future<void> commitTx(WrappedWallet wallet, CsPendingTransaction tx) => wallet
      .get<lib_wownero.Wallet>()
      .commitTx(tx.value as lib_wownero.PendingTransaction);

  @override
  Future<List<CsOutput>> getOutputs(
    WrappedWallet wallet, {
    bool refresh = false,
    bool includeSpent = false,
  }) async {
    final outputs = await wallet.get<lib_wownero.Wallet>().getOutputs(
      includeSpent: includeSpent,
      refresh: refresh,
    );

    return outputs
        .map(
          (e) => CsOutput(
            address: e.address,
            hash: e.hash,
            keyImage: e.keyImage,
            value: e.value,
            isFrozen: e.isFrozen,
            isUnlocked: e.isUnlocked,
            height: e.height,
            spentHeight: e.spentHeight,
            vout: e.vout,
            spent: e.spent,
            coinbase: e.coinbase,
          ),
        )
        .toList();
  }

  @override
  Future<void> freezeOutput(WrappedWallet wallet, String keyImage) =>
      wallet.get<lib_wownero.Wallet>().freezeOutput(keyImage);

  @override
  Future<void> thawOutput(WrappedWallet wallet, String keyImage) =>
      wallet.get<lib_wownero.Wallet>().thawOutput(keyImage);

  @override
  List<String> getWowneroWordList(String language, int seedLength) =>
      lib_wownero.getWowneroWordList(language, seedWordsLength: seedLength);

  @override
  int getHeightByDate(DateTime date) =>
      cs_wownero_deprecated.getWowneroHeightByDate(date: date);

  @override
  bool validateAddress(String address, int network) =>
      wow_wallet_ffi.validateAddress(address, network);

  @override
  String getSeed(WrappedWallet wallet) =>
      wallet.get<lib_wownero.Wallet>().getSeed();

  @override
  Future<void> close(WrappedWallet wallet, {bool save = false}) =>
      wallet.get<lib_wownero.Wallet>().close(save: save);
}

//END_ON
