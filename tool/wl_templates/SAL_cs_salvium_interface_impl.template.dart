//ON
import 'package:cs_salvium/cs_salvium.dart' as lib_salvium;
import 'package:cs_salvium/src/deprecated/get_height_by_date.dart'
    as cs_salvium_deprecated;
import 'package:cs_salvium/src/ffi_bindings/salvium_wallet_bindings.dart'
    as sal_wallet_ffi;

//END_ON
import '../../models/input.dart';
import '../interfaces/cs_monero_interface.dart';
import '../interfaces/cs_salvium_interface.dart';

CsSalviumInterface get csSalvium => _getInterface();

//OFF
CsSalviumInterface _getInterface() => throw Exception("XMR/WOW not enabled!");

//END_OFF
//ON
CsSalviumInterface _getInterface() => _CsSalviumInterfaceImpl();

extension _WrappedWalletExt on WrappedWallet {
  lib_salvium.SalviumWallet get actual => get();
}

class _CsSalviumInterfaceImpl extends CsSalviumInterface {
  @override
  void setUseCsSalviumLoggerInternal(bool enable) =>
      lib_salvium.Logging.useLogger = enable;

  @override
  bool walletExists(String path) =>
      lib_salvium.SalviumWallet.isWalletExist(path);

  @override
  Future<int> estimateFee(
    int rate,
    BigInt amount, {
    required WrappedWallet wallet,
  }) {
    lib_salvium.TransactionPriority priority;
    switch (rate) {
      case 1:
        priority = lib_salvium.TransactionPriority.low;
        break;
      case 2:
        priority = lib_salvium.TransactionPriority.medium;
        break;
      case 3:
        priority = lib_salvium.TransactionPriority.high;
        break;
      case 4:
        priority = lib_salvium.TransactionPriority.last;
        break;
      case 0:
      default:
        priority = lib_salvium.TransactionPriority.normal;
        break;
    }

    return wallet.actual.estimateFee(priority, amount.toInt());
  }

  @override
  Future<WrappedWallet> loadWallet(
    String walletId, {
    required String path,
    required String password,
  }) async {
    final wallet = await lib_salvium.SalviumWallet.loadWallet(
      path: path,
      password: password,
    );
    return WrappedWallet(wallet);
  }

  @override
  int getTxPriorityHigh() => lib_salvium.TransactionPriority.high.value;

  @override
  int getTxPriorityMedium() => lib_salvium.TransactionPriority.medium.value;

  @override
  int getTxPriorityNormal() => lib_salvium.TransactionPriority.normal.value;

  @override
  String getAddress(
    WrappedWallet wallet, {
    int accountIndex = 0,
    int addressIndex = 0,
  }) => wallet.actual
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
      16 => lib_salvium.SalviumSeedType.sixteen,
      25 => lib_salvium.SalviumSeedType.twentyFive,
      _ => throw Exception("Invalid mnemonic word count: $wordCount"),
    };

    final wallet = await lib_salvium.SalviumWallet.create(
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
    final wallet = await lib_salvium.SalviumWallet.restoreWalletFromSeed(
      path: path,
      password: password,
      seed: mnemonic,
      restoreHeight: height,
      seedOffset: seedOffset,
    );

    return WrappedWallet(wallet);
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
    final wallet = await lib_salvium.SalviumWallet.createViewOnlyWallet(
      path: path,
      password: password,
      address: address,
      viewKey: privateViewKey,
      restoreHeight: height,
    );

    return WrappedWallet(wallet);
  }

  @override
  String getTxKey(WrappedWallet wallet, String txid) =>
      wallet.actual.getTxKey(txid);

  @override
  Future<void> save(WrappedWallet wallet) => wallet.actual.save();

  @override
  String getPublicViewKey(WrappedWallet wallet) =>
      wallet.actual.getPublicViewKey();

  @override
  String getPrivateViewKey(WrappedWallet wallet) =>
      wallet.actual.getPrivateViewKey();

  @override
  String getPublicSpendKey(WrappedWallet wallet) =>
      wallet.actual.getPublicSpendKey();

  @override
  String getPrivateSpendKey(WrappedWallet wallet) =>
      wallet.actual.getPrivateSpendKey();

  @override
  Future<bool> isSynced(WrappedWallet wallet) =>
      wallet.actual.isSynced() ?? Future.value(false);

  @override
  void startSyncing(WrappedWallet wallet) => wallet.actual.startSyncing();

  @override
  void stopSyncing(WrappedWallet wallet) => wallet.actual.stopSyncing();

  @override
  void startAutoSaving(WrappedWallet wallet) => wallet.actual.startAutoSaving();

  @override
  void stopAutoSaving(WrappedWallet wallet) => wallet.actual.stopAutoSaving();

  @override
  bool hasListeners(WrappedWallet wallet) =>
      wallet.actual.getListeners().isNotEmpty;

  @override
  void addListener(WrappedWallet wallet, CsWalletListener listener) =>
      wallet.actual.addListener(
        lib_salvium.WalletListener(
          onSyncingUpdate: listener.onSyncingUpdate,
          onNewBlock: listener.onNewBlock,
          onBalancesChanged: listener.onBalancesChanged,
          onError: listener.onError,
        ),
      );

  @override
  void startListeners(WrappedWallet wallet) => wallet.actual.startListeners();

  @override
  void stopListeners(WrappedWallet wallet) => wallet.actual.stopListeners();

  @override
  int getRefreshFromBlockHeight(WrappedWallet wallet) =>
      wallet.actual.getRefreshFromBlockHeight();

  @override
  void setRefreshFromBlockHeight(WrappedWallet wallet, int height) =>
      wallet.actual.setRefreshFromBlockHeight(height);

  @override
  Future<bool> rescanBlockchain(WrappedWallet wallet) =>
      wallet.actual.rescanBlockchain() ?? Future.value(false);

  @override
  Future<bool> isConnectedToDaemon(WrappedWallet wallet) =>
      wallet.actual.isConnectedToDaemon() ?? Future.value(false);

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
    await wallet.actual.connect(
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
  }) => wallet.actual.getAllTxids(refresh: refresh);

  @override
  BigInt? getBalance(WrappedWallet wallet, {int accountIndex = 0}) =>
      wallet.actual.getBalance(accountIndex: accountIndex);

  @override
  BigInt? getUnlockedBalance(WrappedWallet wallet, {int accountIndex = 0}) =>
      wallet.actual.getUnlockedBalance(accountIndex: accountIndex);

  @override
  Future<List<CsTransaction>> getAllTxs(
    WrappedWallet wallet, {
    bool refresh = false,
  }) async {
    final transactions = await wallet.actual.getAllTxs(refresh: refresh);
    if (transactions == null) return [];
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
            salviumData: (asset: e.asset, type: e.type),
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
    final transactions = await wallet.actual.getTxs(
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
            salviumData: (asset: e.asset, type: e.type),
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
    final pending = await wallet.actual.createTx(
      output: lib_salvium.Recipient(
        address: output.address,
        amount: output.amount,
      ),
      paymentId: "",
      sweep: sweep,
      priority: lib_salvium.TransactionPriority.values.firstWhere(
        (e) => e.value == priority,
      ),
      preferredInputs: preferredInputs
          ?.map(
            (e) => lib_salvium.Output(
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
  Future<CsPendingTransaction> createStakeTx(
    WrappedWallet wallet, {
    required CsRecipient output,
    required int priority,
    List<StandardInput>? preferredInputs,
    required int accountIndex,
    required int minConfirms,
    required int currentHeight,
  }) async {
    final pending = await wallet.actual.createStakeTx(
      output: lib_salvium.Recipient(
        address: output.address,
        amount: output.amount,
      ),
      paymentId: "",
      priority: lib_salvium.TransactionPriority.values.firstWhere(
        (e) => e.value == priority,
      ),
      preferredInputs: preferredInputs
          ?.map(
            (e) => lib_salvium.Output(
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
    final pending = await wallet.actual.createTxMultiDest(
      outputs: outputs
          .map(
            (e) => lib_salvium.Recipient(address: e.address, amount: e.amount),
          )
          .toList(),
      paymentId: "",
      sweep: sweep,
      priority: lib_salvium.TransactionPriority.values.firstWhere(
        (e) => e.value == priority,
      ),
      preferredInputs: preferredInputs
          ?.map(
            (e) => lib_salvium.Output(
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
  Future<void> commitTx(WrappedWallet wallet, CsPendingTransaction tx) =>
      wallet.actual.commitTx(tx.value as lib_salvium.PendingTransaction);

  @override
  Future<List<CsOutput>> getOutputs(
    WrappedWallet wallet, {
    bool refresh = false,
    bool includeSpent = false,
  }) async {
    final outputs = await wallet.actual.getOutputs(
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
      wallet.actual.freezeOutput(keyImage);

  @override
  Future<void> thawOutput(WrappedWallet wallet, String keyImage) =>
      wallet.actual.thawOutput(keyImage);

  @override
  List<String> getSalviumWordList(String language) =>
      lib_salvium.getSalviumWordList(language);

  @override
  int getHeightByDate(DateTime date) =>
      cs_salvium_deprecated.getSalviumHeightByDate(date: date);

  @override
  bool validateAddress(String address, int network) =>
      sal_wallet_ffi.validateAddress(address, network);

  @override
  String getSeed(WrappedWallet wallet) => wallet.actual.getSeed();
}

//END_ON
