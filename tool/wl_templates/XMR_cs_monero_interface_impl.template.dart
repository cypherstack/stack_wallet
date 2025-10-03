//ON
import 'package:cs_monero/cs_monero.dart' as lib_monero;

//END_ON
import '../../models/input.dart';
import '../interfaces/cs_monero_interface.dart';

CsMoneroInterface get csMonero => _getInterface();

//OFF
CsMoneroInterface _getInterface() => throw Exception("XMR/WOW not enabled!");

//END_OFF
//ON
CsMoneroInterface _getInterface() => _CsMoneroInterfaceImpl();

class _CsMoneroInterfaceImpl extends CsMoneroInterface {
  final Map<String, lib_monero.Wallet> _wallets = {};

  @override
  void setUseCsMoneroLoggerInternal(bool enable) =>
      lib_monero.Logging.useLogger = enable;

  @override
  bool walletInstanceExists(String walletId) => _wallets[walletId] != null;

  @override
  bool walletExists(String path, {required CsCoin csCoin}) => switch (csCoin) {
    CsCoin.monero => lib_monero.MoneroWallet.isWalletExist(path),
    CsCoin.wownero => lib_monero.WowneroWallet.isWalletExist(path),
  };

  @override
  Future<int> estimateFee(int rate, BigInt amount, {required String walletId}) {
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

    return _wallets[walletId]!.estimateFee(priority, amount.toInt());
  }

  @override
  Future<void> loadWallet(
    String walletId, {
    required CsCoin csCoin,
    required String path,
    required String password,
  }) async {
    switch (csCoin) {
      case CsCoin.monero:
        _wallets[walletId] = await lib_monero.MoneroWallet.loadWallet(
          path: path,
          password: password,
        );
        break;

      case CsCoin.wownero:
        _wallets[walletId] = await lib_monero.WowneroWallet.loadWallet(
          path: path,
          password: password,
        );
        break;
    }
  }

  @override
  int getTxPriorityHigh() => lib_monero.TransactionPriority.high.value;

  @override
  int getTxPriorityMedium() => lib_monero.TransactionPriority.medium.value;

  @override
  int getTxPriorityNormal() => lib_monero.TransactionPriority.normal.value;

  @override
  String getAddress(
    String walletId, {
    int accountIndex = 0,
    int addressIndex = 0,
  }) => _wallets[walletId]!
      .getAddress(accountIndex: accountIndex, addressIndex: addressIndex)
      .value;

  @override
  Future<void> getCreatedWallet({
    required CsCoin csCoin,
    required String path,
    required String password,
    required int wordCount,
    required String seedOffset,
    required final void Function(int refreshFromBlockHeight, String seed)
    onCreated,
  }) async {
    final lib_monero.Wallet wallet;

    switch (csCoin) {
      case CsCoin.monero:
        final type = switch (wordCount) {
          16 => lib_monero.MoneroSeedType.sixteen,
          25 => lib_monero.MoneroSeedType.twentyFive,
          _ => throw Exception("Invalid mnemonic word count: $wordCount"),
        };

        wallet = await lib_monero.MoneroWallet.create(
          path: path,
          password: password,
          seedType: type,
          seedOffset: seedOffset,
        );
        break;

      case CsCoin.wownero:
        final type = switch (wordCount) {
          16 => lib_monero.WowneroSeedType.sixteen,
          25 => lib_monero.WowneroSeedType.twentyFive,
          _ => throw Exception("Invalid mnemonic word count: $wordCount"),
        };

        wallet = await lib_monero.WowneroWallet.create(
          path: path,
          password: password,
          seedType: type,
          seedOffset: seedOffset,
        );
        break;
    }

    onCreated(
      wallet.getRefreshFromBlockHeight(),
      wallet.getSeed(seedOffset: seedOffset).trim(),
    );
  }

  @override
  Future<void> getRestoredWallet({
    required String walletId,
    required CsCoin csCoin,
    required String path,
    required String password,
    required String mnemonic,
    required String seedOffset,
    int height = 0,
  }) async {
    _wallets[walletId] = switch (csCoin) {
      CsCoin.monero =>
        _wallets[walletId] =
            await lib_monero.MoneroWallet.restoreWalletFromSeed(
              path: path,
              password: password,
              seed: mnemonic,
              restoreHeight: height,
              seedOffset: seedOffset,
            ),

      CsCoin.wownero =>
        _wallets[walletId] =
            await lib_monero.WowneroWallet.restoreWalletFromSeed(
              path: path,
              password: password,
              seed: mnemonic,
              restoreHeight: height,
              seedOffset: seedOffset,
            ),
    };
  }

  @override
  Future<void> getRestoredFromViewKeyWallet({
    required String walletId,
    required CsCoin csCoin,
    required String path,
    required String password,
    required String address,
    required String privateViewKey,
    int height = 0,
  }) async {
    _wallets[walletId] = switch (csCoin) {
      CsCoin.monero => await lib_monero.MoneroWallet.createViewOnlyWallet(
        path: path,
        password: password,
        address: address,
        viewKey: privateViewKey,
        restoreHeight: height,
      ),

      CsCoin.wownero => await lib_monero.WowneroWallet.createViewOnlyWallet(
        path: path,
        password: password,
        address: address,
        viewKey: privateViewKey,
        restoreHeight: height,
      ),
    };
  }

  @override
  String getTxKey(String walletId, String txid) =>
      _wallets[walletId]!.getTxKey(txid);

  @override
  Future<void> save(String walletId) => _wallets[walletId]!.save();

  @override
  String getPublicViewKey(String walletId) =>
      _wallets[walletId]!.getPublicViewKey();

  @override
  String getPrivateViewKey(String walletId) =>
      _wallets[walletId]!.getPrivateViewKey();

  @override
  String getPublicSpendKey(String walletId) =>
      _wallets[walletId]!.getPublicSpendKey();

  @override
  String getPrivateSpendKey(String walletId) =>
      _wallets[walletId]!.getPrivateSpendKey();

  @override
  Future<bool> isSynced(String walletId) =>
      _wallets[walletId]?.isSynced() ?? Future.value(false);

  @override
  void startSyncing(String walletId) => _wallets[walletId]?.startSyncing();

  @override
  void stopSyncing(String walletId) => _wallets[walletId]?.stopSyncing();

  @override
  void startAutoSaving(String walletId) =>
      _wallets[walletId]?.startAutoSaving();

  @override
  void stopAutoSaving(String walletId) => _wallets[walletId]?.stopAutoSaving();

  @override
  bool hasListeners(String walletId) =>
      _wallets[walletId]!.getListeners().isNotEmpty;

  @override
  void addListener(String walletId, CsMoneroWalletListener listener) =>
      _wallets[walletId]?.addListener(
        lib_monero.WalletListener(
          onSyncingUpdate: listener.onSyncingUpdate,
          onNewBlock: listener.onNewBlock,
          onBalancesChanged: listener.onBalancesChanged,
          onError: listener.onError,
        ),
      );

  @override
  void startListeners(String walletId) => _wallets[walletId]?.startListeners();

  @override
  void stopListeners(String walletId) => _wallets[walletId]?.stopListeners();

  @override
  int getRefreshFromBlockHeight(String walletId) =>
      _wallets[walletId]!.getRefreshFromBlockHeight();

  @override
  void setRefreshFromBlockHeight(String walletId, int height) =>
      _wallets[walletId]!.setRefreshFromBlockHeight(height);

  @override
  Future<bool> rescanBlockchain(String walletId) =>
      _wallets[walletId]?.rescanBlockchain() ?? Future.value(false);

  @override
  Future<bool> isConnectedToDaemon(String walletId) =>
      _wallets[walletId]?.isConnectedToDaemon() ?? Future.value(false);

  @override
  Future<void> connect(
    String walletId, {
    required String daemonAddress,
    required bool trusted,
    String? daemonUsername,
    String? daemonPassword,
    bool useSSL = false,
    bool isLightWallet = false,
    String? socksProxyAddress,
  }) async {
    await _wallets[walletId]?.connect(
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
  Future<List<String>> getAllTxids(String walletId, {bool refresh = false}) =>
      _wallets[walletId]!.getAllTxids(refresh: refresh);

  @override
  BigInt? getBalance(String walletId, {int accountIndex = 0}) =>
      _wallets[walletId]?.getBalance(accountIndex: accountIndex);

  @override
  BigInt? getUnlockedBalance(String walletId, {int accountIndex = 0}) =>
      _wallets[walletId]?.getUnlockedBalance(accountIndex: accountIndex);

  @override
  Future<List<CsTransaction>> getAllTxs(
    String walletId, {
    bool refresh = false,
  }) async {
    final transactions = await _wallets[walletId]?.getAllTxs(refresh: refresh);
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
          ),
        )
        .toList();
  }

  @override
  Future<List<CsTransaction>> getTxs(
    String walletId, {
    required Set<String> txids,
    bool refresh = false,
  }) async {
    final transactions = await _wallets[walletId]?.getTxs(
      txids: txids,
      refresh: refresh,
    );
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
          ),
        )
        .toList();
  }

  @override
  Future<CsPendingTransaction> createTx(
    String walletId, {
    required CsRecipient output,
    required int priority,
    required bool sweep,
    List<StandardInput>? preferredInputs,
    required int accountIndex,
    required int minConfirms,
    required int currentHeight,
  }) async {
    final pending = await _wallets[walletId]!.createTx(
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
    String walletId, {
    required List<CsRecipient> outputs,
    required int priority,
    required bool sweep,
    List<StandardInput>? preferredInputs,
    required int accountIndex,
    required int minConfirms,
    required int currentHeight,
  }) async {
    final pending = await _wallets[walletId]!.createTxMultiDest(
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
  Future<void> commitTx(String walletId, CsPendingTransaction tx) =>
      _wallets[walletId]!.commitTx(tx.value as lib_monero.PendingTransaction);

  @override
  Future<List<CsOutput>> getOutputs(
    String walletId, {
    bool refresh = false,
    bool includeSpent = false,
  }) async {
    final outputs = await _wallets[walletId]?.getOutputs(
      includeSpent: includeSpent,
      refresh: refresh,
    );

    if (outputs == null) return [];

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
  Future<void> freezeOutput(String walletId, String keyImage) =>
      _wallets[walletId]!.freezeOutput(keyImage);

  @override
  Future<void> thawOutput(String walletId, String keyImage) =>
      _wallets[walletId]!.thawOutput(keyImage);

  @override
  List<String> getMoneroWordList(String language) =>
      lib_monero.getMoneroWordList(language);

  @override
  List<String> getWowneroWordList(String language, int seedLength) =>
      lib_monero.getWowneroWordList(language, seedWordsLength: seedLength);
}

//END_ON
