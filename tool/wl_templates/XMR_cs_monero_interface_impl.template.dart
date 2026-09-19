//ON
import 'package:cs_monero/cs_monero.dart' as lib_monero;
import 'package:cs_monero/src/deprecated/get_height_by_date.dart'
    as cs_monero_deprecated;
import 'package:cs_monero/src/ffi_bindings/monero_wallet_bindings.dart'
    as xmr_wallet_ffi;

//END_ON
import '../../models/input.dart';
import '../interfaces/cs_monero_interface.dart';
import '../interfaces/cs_salvium_interface.dart' show WrappedWallet;

CsMoneroInterface get csMonero => _getInterface();

//OFF
CsMoneroInterface _getInterface() => throw Exception("XMR not enabled!");

//END_OFF
//ON
CsMoneroInterface _getInterface() => const _CsMoneroInterfaceImpl();

class _CsMoneroInterfaceImpl extends CsMoneroInterface {
  const _CsMoneroInterfaceImpl();

  @override
  void setUseCsMoneroLoggerInternal(bool enable) =>
      lib_monero.Logging.useLogger = enable;

  @override
  bool walletExists(String path) => lib_monero.MoneroWallet.isWalletExist(path);

  @override
  Future<int> estimateFee(
    int rate,
    BigInt amount, {
    required WrappedWallet wallet,
  }) {
    lib_monero.TransactionPriority priority;
    switch (rate) {
      case 1:
        priority = lib_monero.TransactionPriority.low;
        break;
      case 2:
        priority = lib_monero.TransactionPriority.medium;
        break;
      case 3:
        priority = lib_monero.TransactionPriority.high;
        break;
      case 4:
        priority = lib_monero.TransactionPriority.last;
        break;
      case 0:
      default:
        priority = lib_monero.TransactionPriority.normal;
        break;
    }

    return wallet.get<lib_monero.Wallet>().estimateFee(
      priority,
      amount.toInt(),
    );
  }

  @override
  Future<WrappedWallet> loadWallet(
    String walletId, {
    required String path,
    required String password,
    int network = 0, // default to mainnet
  }) async {
    return WrappedWallet(
      await lib_monero.MoneroWallet.loadWallet(
        path: path,
        password: password,
        networkType: lib_monero.Network.values.firstWhere(
          (e) => e.value == network,
        ),
      ),
    );
  }

  @override
  int getTxPriorityHigh() => lib_monero.TransactionPriority.high.value;

  @override
  int getTxPriorityMedium() => lib_monero.TransactionPriority.medium.value;

  @override
  int getTxPriorityNormal() => lib_monero.TransactionPriority.normal.value;

  @override
  Future<String> getAddress(
    WrappedWallet wallet, {
    int accountIndex = 0,
    int addressIndex = 0,
  }) async => (await wallet.get<lib_monero.Wallet>().getAddress(
    accountIndex: accountIndex,
    addressIndex: addressIndex,
  )).value;

  @override
  Future<WrappedWallet> getCreatedWallet({
    required String path,
    required String password,
    required int wordCount,
    required String seedOffset,
    int network = 0, // default to mainnet
  }) async {
    final type = switch (wordCount) {
      16 => lib_monero.MoneroSeedType.sixteen,
      25 => lib_monero.MoneroSeedType.twentyFive,
      _ => throw Exception("Invalid mnemonic word count: $wordCount"),
    };

    final wallet = await lib_monero.MoneroWallet.create(
      path: path,
      password: password,
      seedType: type,
      seedOffset: seedOffset,
      networkType: lib_monero.Network.values.firstWhere(
        (e) => e.value == network,
      ),
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
    int network = 0, // default to mainnet
    int height = 0,
  }) async {
    return WrappedWallet(
      await lib_monero.MoneroWallet.restoreWalletFromSeed(
        path: path,
        password: password,
        seed: mnemonic,
        restoreHeight: height,
        seedOffset: seedOffset,
        networkType: lib_monero.Network.values.firstWhere(
          (e) => e.value == network,
        ),
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
    int network = 0, // default to mainnet
    int height = 0,
  }) async {
    return WrappedWallet(
      await lib_monero.MoneroWallet.createViewOnlyWallet(
        path: path,
        password: password,
        address: address,
        viewKey: privateViewKey,
        restoreHeight: height,
        networkType: lib_monero.Network.values.firstWhere(
          (e) => e.value == network,
        ),
      ),
    );
  }

  @override
  Future<String> getTxKey(WrappedWallet wallet, String txid) =>
      wallet.get<lib_monero.Wallet>().getTxKey(txid);

  @override
  Future<void> save(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().save();

  @override
  Future<String> getPublicViewKey(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().getPublicViewKey();

  @override
  Future<String> getPrivateViewKey(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().getPrivateViewKey();

  @override
  Future<String> getPublicSpendKey(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().getPublicSpendKey();

  @override
  Future<String> getPrivateSpendKey(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().getPrivateSpendKey();

  @override
  Future<bool> isSynced(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().isSynced();

  @override
  Future<void> startSyncing(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().startSyncing();

  @override
  Future<void> stopSyncing(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().stopSyncing();

  @override
  void startAutoSaving(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().startAutoSaving();

  @override
  void stopAutoSaving(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().stopAutoSaving();

  @override
  bool hasListeners(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().getListeners().isNotEmpty;

  @override
  void addListener(WrappedWallet wallet, CsWalletListener listener) =>
      wallet.get<lib_monero.Wallet>().addListener(
        lib_monero.WalletListener(
          onSyncingUpdate: listener.onSyncingUpdate,
          onNewBlock: listener.onNewBlock,
          onBalancesChanged: listener.onBalancesChanged,
          onError: listener.onError,
        ),
      );

  @override
  Future<void> startListeners(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().startListeners();

  @override
  Future<void> stopListeners(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().stopListeners();

  @override
  Future<int> getRefreshFromBlockHeight(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().getRefreshFromBlockHeight();

  @override
  Future<void> setRefreshFromBlockHeight(WrappedWallet wallet, int height) =>
      wallet.get<lib_monero.Wallet>().setRefreshFromBlockHeight(height);

  @override
  Future<void> rescanBlockchain(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().rescanBlockchain();

  @override
  Future<bool> isConnectedToDaemon(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().isConnectedToDaemon();

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
    await wallet.get<lib_monero.Wallet>().connect(
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
  }) => wallet.get<lib_monero.Wallet>().getAllTxids(refresh: refresh);

  @override
  Future<BigInt> getBalance(WrappedWallet wallet, {int accountIndex = 0}) =>
      wallet.get<lib_monero.Wallet>().getBalance(accountIndex: accountIndex);

  @override
  Future<BigInt> getUnlockedBalance(
    WrappedWallet wallet, {
    int accountIndex = 0,
  }) => wallet.get<lib_monero.Wallet>().getUnlockedBalance(
    accountIndex: accountIndex,
  );

  @override
  Future<List<CsTransaction>> getAllTxs(
    WrappedWallet wallet, {
    bool refresh = false,
  }) async {
    final transactions = await wallet.get<lib_monero.Wallet>().getAllTxs(
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
    final transactions = await wallet.get<lib_monero.Wallet>().getTxs(
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
    final pending = await wallet.get<lib_monero.Wallet>().createTx(
      output: lib_monero.Recipient(
        address: output.address,
        amount: output.amount,
      ),
      paymentId: "",
      sweep: sweep,
      priority: lib_monero.TransactionPriority.values.firstWhere(
        (e) => e.value == priority,
      ),
      preferredInputs: preferredInputs
          ?.map(
            (e) => lib_monero.Output(
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
    final pending = await wallet.get<lib_monero.Wallet>().createTxMultiDest(
      outputs: outputs
          .map(
            (e) => lib_monero.Recipient(address: e.address, amount: e.amount),
          )
          .toList(),
      paymentId: "",
      sweep: sweep,
      priority: lib_monero.TransactionPriority.values.firstWhere(
        (e) => e.value == priority,
      ),
      preferredInputs: preferredInputs
          ?.map(
            (e) => lib_monero.Output(
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
      .get<lib_monero.Wallet>()
      .commitTx(tx.value as lib_monero.PendingTransaction);

  @override
  Future<List<CsOutput>> getOutputs(
    WrappedWallet wallet, {
    bool refresh = false,
    bool includeSpent = false,
  }) async {
    final outputs = await wallet.get<lib_monero.Wallet>().getOutputs(
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
      wallet.get<lib_monero.Wallet>().freezeOutput(keyImage);

  @override
  Future<void> thawOutput(WrappedWallet wallet, String keyImage) =>
      wallet.get<lib_monero.Wallet>().thawOutput(keyImage);

  @override
  List<String> getMoneroWordList(String language) =>
      lib_monero.getMoneroWordList(language);

  @override
  int getHeightByDate(DateTime date) =>
      cs_monero_deprecated.getMoneroHeightByDate(date: date);

  @override
  bool validateAddress(String address, int network) =>
      xmr_wallet_ffi.validateAddress(address, network);

  @override
  Future<String> getSeed(WrappedWallet wallet) =>
      wallet.get<lib_monero.Wallet>().getSeed();

  @override
  Future<void> close(WrappedWallet wallet, {bool save = false}) =>
      wallet.get<lib_monero.Wallet>().close(save: save);
}

//END_ON
