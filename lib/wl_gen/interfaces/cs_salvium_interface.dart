import '../../models/input.dart';
import 'cs_monero_interface.dart';

export '../generated/cs_salvium_interface_impl.dart';

abstract class CsSalviumInterface {
  void setUseCsSalviumLoggerInternal(bool enable);

  // tx prio forwarding
  int getTxPriorityHigh();
  int getTxPriorityMedium();
  int getTxPriorityNormal();

  bool walletInstanceExists(String walletId);

  bool walletExists(String path);

  Future<int> estimateFee(int rate, BigInt amount, {required String walletId});

  Future<void> loadWallet(
    String walletId, {

    required String path,
    required String password,
  });

  String getAddress(
    String walletId, {
    int accountIndex = 0,
    int addressIndex = 0,
  });

  Future<void> getCreatedWallet({
    required String path,
    required String password,
    required int wordCount,
    required String seedOffset,
    required final void Function(int refreshFromBlockHeight, String seed)
    onCreated,
  });

  Future<void> getRestoredWallet({
    required String walletId,

    required String path,
    required String password,
    required String mnemonic,
    required String seedOffset,
    int height = 0,
  });

  Future<void> getRestoredFromViewKeyWallet({
    required String walletId,

    required String path,
    required String password,
    required String address,
    required String privateViewKey,
    int height = 0,
  });

  String getTxKey(String walletId, String txid);

  Future<void> save(String walletId);

  String getPublicViewKey(String walletId);
  String getPrivateViewKey(String walletId);
  String getPublicSpendKey(String walletId);
  String getPrivateSpendKey(String walletId);

  Future<bool> isSynced(String walletId);
  void startSyncing(String walletId);
  void stopSyncing(String walletId);

  void startAutoSaving(String walletId);
  void stopAutoSaving(String walletId);

  bool hasListeners(String walletId);
  void addListener(String walletId, CsWalletListener listener);
  void startListeners(String walletId);
  void stopListeners(String walletId);

  Future<bool> rescanBlockchain(String walletId);
  Future<bool> isConnectedToDaemon(String walletId);

  int getRefreshFromBlockHeight(String walletId);
  void setRefreshFromBlockHeight(String walletId, int height);

  Future<void> connect(
    String walletId, {
    required String daemonAddress,
    required bool trusted,
    String? daemonUsername,
    String? daemonPassword,
    bool useSSL = false,
    bool isLightWallet = false,
    String? socksProxyAddress,
  });

  Future<List<String>> getAllTxids(String walletId, {bool refresh = false});

  BigInt? getBalance(String walletId, {int accountIndex = 0});
  BigInt? getUnlockedBalance(String walletId, {int accountIndex = 0});

  Future<List<CsTransaction>> getAllTxs(
    String walletId, {
    bool refresh = false,
  });

  Future<List<CsTransaction>> getTxs(
    String walletId, {
    required Set<String> txids,
    bool refresh = false,
  });

  Future<CsPendingTransaction> createTx(
    String walletId, {
    required CsRecipient output,
    required int priority,
    required bool sweep,
    List<StandardInput>? preferredInputs,
    required int accountIndex,
    required int minConfirms,
    required int currentHeight,
  });

  Future<CsPendingTransaction> createTxMultiDest(
    String walletId, {
    required List<CsRecipient> outputs,
    required int priority,
    required bool sweep,
    List<StandardInput>? preferredInputs,
    required int accountIndex,
    required int minConfirms,
    required int currentHeight,
  });

  Future<void> commitTx(String walletId, CsPendingTransaction tx);

  Future<List<CsOutput>> getOutputs(
    String walletId, {
    bool refresh = false,
    bool includeSpent = false,
  });

  Future<void> freezeOutput(String walletId, String keyImage);
  Future<void> thawOutput(String walletId, String keyImage);

  List<String> getSalviumWordList(String language);

  int getHeightByDate(DateTime date);

  bool validateAddress(String address, int network);
}
