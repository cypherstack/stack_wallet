import '../../models/input.dart';
import 'cs_monero_interface.dart';

export '../generated/cs_salvium_interface_impl.dart';

abstract class CsSalviumInterface {
  void setUseCsSalviumLoggerInternal(bool enable);

  // tx prio forwarding
  int getTxPriorityHigh();
  int getTxPriorityMedium();
  int getTxPriorityNormal();

  bool walletExists(String path);

  Future<int> estimateFee(
    int rate,
    BigInt amount, {
    required WrappedWallet wallet,
  });

  Future<WrappedWallet> loadWallet(
    String walletId, {
    required String path,
    required String password,
  });

  String getAddress(
    WrappedWallet wallet, {
    int accountIndex = 0,
    int addressIndex = 0,
  });

  Future<WrappedWallet> getCreatedWallet({
    required String path,
    required String password,
    required int wordCount,
    required String seedOffset,
  });

  Future<WrappedWallet> getRestoredWallet({
    required String walletId,
    required String path,
    required String password,
    required String mnemonic,
    required String seedOffset,
    int height = 0,
  });

  Future<WrappedWallet> getRestoredFromViewKeyWallet({
    required String walletId,
    required String path,
    required String password,
    required String address,
    required String privateViewKey,
    int height = 0,
  });

  String getTxKey(WrappedWallet wallet, String txid);

  Future<void> save(WrappedWallet wallet);

  String getPublicViewKey(WrappedWallet wallet);
  String getPrivateViewKey(WrappedWallet wallet);
  String getPublicSpendKey(WrappedWallet wallet);
  String getPrivateSpendKey(WrappedWallet wallet);

  Future<bool> isSynced(WrappedWallet wallet);
  void startSyncing(WrappedWallet wallet);
  void stopSyncing(WrappedWallet wallet);

  void startAutoSaving(WrappedWallet wallet);
  void stopAutoSaving(WrappedWallet wallet);

  bool hasListeners(WrappedWallet wallet);
  void addListener(WrappedWallet wallet, CsWalletListener listener);
  void startListeners(WrappedWallet wallet);
  void stopListeners(WrappedWallet wallet);

  Future<bool> rescanBlockchain(WrappedWallet wallet);
  Future<bool> isConnectedToDaemon(WrappedWallet wallet);

  int getRefreshFromBlockHeight(WrappedWallet wallet);
  void setRefreshFromBlockHeight(WrappedWallet wallet, int height);

  Future<void> connect(
    WrappedWallet wallet, {
    required String daemonAddress,
    required bool trusted,
    String? daemonUsername,
    String? daemonPassword,
    bool useSSL = false,
    bool isLightWallet = false,
    String? socksProxyAddress,
  });

  Future<List<String>> getAllTxids(
    WrappedWallet wallet, {
    bool refresh = false,
  });

  BigInt? getBalance(WrappedWallet wallet, {int accountIndex = 0});
  BigInt? getUnlockedBalance(WrappedWallet wallet, {int accountIndex = 0});

  Future<List<CsTransaction>> getAllTxs(
    WrappedWallet wallet, {
    bool refresh = false,
  });

  Future<List<CsTransaction>> getTxs(
    WrappedWallet wallet, {
    required Set<String> txids,
    bool refresh = false,
  });

  Future<CsPendingTransaction> createTx(
    WrappedWallet wallet, {
    required CsRecipient output,
    required int priority,
    required bool sweep,
    List<StandardInput>? preferredInputs,
    required int accountIndex,
    required int minConfirms,
    required int currentHeight,
  });

  Future<CsPendingTransaction> createStakeTx(
    WrappedWallet wallet, {
    required CsRecipient output,
    required int priority,
    List<StandardInput>? preferredInputs,
    required int accountIndex,
    required int minConfirms,
    required int currentHeight,
  });

  Future<CsPendingTransaction> createTxMultiDest(
    WrappedWallet wallet, {
    required List<CsRecipient> outputs,
    required int priority,
    required bool sweep,
    List<StandardInput>? preferredInputs,
    required int accountIndex,
    required int minConfirms,
    required int currentHeight,
  });

  Future<void> commitTx(WrappedWallet wallet, CsPendingTransaction tx);

  Future<List<CsOutput>> getOutputs(
    WrappedWallet wallet, {
    bool refresh = false,
    bool includeSpent = false,
  });

  Future<void> freezeOutput(WrappedWallet wallet, String keyImage);
  Future<void> thawOutput(WrappedWallet wallet, String keyImage);

  List<String> getSalviumWordList(String language);

  int getHeightByDate(DateTime date);

  bool validateAddress(String address, int network);

  String getSeed(WrappedWallet wallet);
}

// lol...
class WrappedWallet {
  final Object _wallet;

  const WrappedWallet(this._wallet);

  T get<T>() => _wallet as T;
}
