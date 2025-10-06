import '../../models/input.dart';

export '../generated/cs_monero_interface_impl.dart';

abstract class CsMoneroInterface {
  void setUseCsMoneroLoggerInternal(bool enable);

  // tx prio forwarding
  int getTxPriorityHigh();
  int getTxPriorityMedium();
  int getTxPriorityNormal();

  bool walletInstanceExists(String walletId);

  bool walletExists(String path, {required CsCoin csCoin});

  Future<int> estimateFee(int rate, BigInt amount, {required String walletId});

  Future<void> loadWallet(
    String walletId, {
    required CsCoin csCoin,
    required String path,
    required String password,
  });

  String getAddress(
    String walletId, {
    int accountIndex = 0,
    int addressIndex = 0,
  });

  Future<void> getCreatedWallet({
    required CsCoin csCoin,
    required String path,
    required String password,
    required int wordCount,
    required String seedOffset,
    required final void Function(int refreshFromBlockHeight, String seed)
    onCreated,
  });

  Future<void> getRestoredWallet({
    required String walletId,
    required CsCoin csCoin,
    required String path,
    required String password,
    required String mnemonic,
    required String seedOffset,
    int height = 0,
  });

  Future<void> getRestoredFromViewKeyWallet({
    required String walletId,
    required CsCoin csCoin,
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

  List<String> getMoneroWordList(String language);
  List<String> getWowneroWordList(String language, int seedLength);

  int getHeightByDate(DateTime date, {required CsCoin csCoin});

  bool validateAddress(String address, int network, {required CsCoin csCoin});
}

enum CsCoin { monero, wownero }

// forwarding class
final class CsWalletListener {
  CsWalletListener({
    this.onSyncingUpdate,
    this.onNewBlock,
    this.onBalancesChanged,
    this.onError,
  });

  /// Called when the wallet sync progress is updated.
  ///
  /// Parameters:
  /// - [syncHeight]: The current syncing height of the wallet.
  /// - [nodeHeight]: The height of the blockchain on the connected node.
  /// - [message]: An optional message that may provide additional context.
  final void Function({
    required int syncHeight,
    required int nodeHeight,
    String? message,
  })?
  onSyncingUpdate;

  /// Called when the daemon’s chain height changes, indicating new blocks.
  ///
  /// Parameters:
  /// - [height]: The new height of the blockchain.
  final void Function(int height)? onNewBlock;

  /// Called when the wallet balance or unlocked balance updates.
  ///
  /// Parameters:
  /// - [newBalance]: The updated total wallet balance in atomic units.
  /// - [newUnlockedBalance]: The updated unlocked balance in atomic units.
  final void Function({
    required BigInt newBalance,
    required BigInt newUnlockedBalance,
  })?
  onBalancesChanged;

  /// Called when an error occurs during synchronization/polling.
  ///
  /// Parameters:
  /// - [error]: The error object describing what went wrong.
  /// - [stackTrace]: The stack trace at the point where the error occurred.
  final void Function(Object? error, StackTrace? stackTrace)? onError;
}

// stupid
final class CsPendingTransaction {
  /// should only ever be lib_monero.PendingTransaction but we can't strongly
  /// type that because we cannot conditionally import in dart so now we have
  /// this hack yay
  final Object value;

  // stupid duplicates
  final BigInt amount, fee;

  // stupid duplicate
  final String txid;

  const CsPendingTransaction(this.value, this.amount, this.fee, this.txid);
}

// forwarding class
final class CsTransaction {
  CsTransaction({
    required this.displayLabel,
    required this.description,
    required this.fee,
    required this.confirmations,
    required this.blockHeight,
    required this.accountIndex,
    required this.addressIndexes,
    required this.paymentId,
    required this.amount,
    required this.isSpend,
    required this.hash,
    required this.key,
    required this.timeStamp,
    required this.minConfirms,
  }) {
    if (fee.isNegative) throw Exception("negative fee");
    if (confirmations.isNegative) throw Exception("negative confirmations");
    if (accountIndex.isNegative) throw Exception("negative accountIndex");
    if (amount.isNegative) throw Exception("negative amount");
  }

  /// A label to display for the transaction, providing a human-readable identifier.
  final String displayLabel;

  /// A description of the transaction, providing additional context or details.
  final String description;

  /// The transaction fee in atomic units.
  final BigInt fee;

  /// The number of confirmations this transaction has received.
  final int confirmations;

  /// The block height at which this transaction was included.
  final int blockHeight;

  /// A set of indexes corresponding to addresses associated with this transaction.
  final Set<int> addressIndexes;

  /// The index of the account associated with this transaction.
  final int accountIndex;

  /// An optional payment identifier, used to associate this transaction with a payment.
  final String paymentId;

  /// The amount of funds transferred in this transaction, represented in atomic units.
  final BigInt amount;

  /// Flag indicating whether this transaction is a spend transaction.
  final bool isSpend;

  /// The timestamp of when this transaction was created or recorded.
  final DateTime timeStamp;

  /// The unique hash of this transaction (txid).
  final String hash;

  /// A key used to prove a transaction was made and relayed and to verify its details.
  final String key;

  /// The minimum number of confirmations required for this transaction.
  final int minConfirms;

  /// Flag indicating whether the transaction is confirmed.
  bool get isConfirmed => !isPending;

  /// Flag indicating whether the transaction is pending (i.e., not yet confirmed).
  bool get isPending => confirmations < minConfirms;
}

// forwarding class
final class CsRecipient {
  final String address;
  final BigInt amount;

  CsRecipient(this.address, this.amount);
}

// forwarding class
final class CsOutput {
  /// Creates an [CsOutput] with the specified Monero transaction details. NOTE:
  /// No validation of any properties (besides a negative [value] or [vout],
  /// and a non empty [keyImage]) occurs here.
  ///
  /// [address] is the receiving Monero address.
  /// [hash] is the transaction hash of the output.
  /// [keyImage] is the unique identifier of the output.
  /// [value] represents the amount of Monero in atomic units.
  /// [isFrozen] indicates if the output is currently frozen.
  /// [isUnlocked] shows if the output is available for spending.
  /// [height] is the blockchain height at which the output was created.
  /// [spentHeight] is the blockchain height at which the output was spent,
  /// or `null` if it is unspent.
  /// [vout] represents the output index within the transaction.
  /// [spent] indicates if the output has been spent.
  /// [coinbase] identifies if the output is from a coinbase transaction.
  CsOutput({
    required this.address,
    required this.hash,
    required this.keyImage,
    required this.value,
    required this.isFrozen,
    required this.isUnlocked,
    required this.height,
    required this.spentHeight,
    required this.vout,
    required this.spent,
    required this.coinbase,
  }) : assert(!value.isNegative && !vout.isNegative && keyImage.isNotEmpty);

  /// The receiving Monero address.
  final String address;

  /// The hash of the transaction in which this output was created.
  final String hash;

  /// The value of the output, in atomic units.
  final BigInt value;

  /// A unique identifier for this output.
  /// See https://monero.stackexchange.com/questions/2883/what-is-a-key-image
  final String keyImage;

  /// Whether this output is frozen, preventing it from being spent.
  final bool isFrozen;

  /// Whether this output is unlocked and available for spending.
  final bool isUnlocked;

  /// The blockchain height where this output was created.
  final int height;

  /// The blockchain height where this output was spent, or `null` if unspent.
  final int? spentHeight;

  /// The output index within the transaction.
  final int vout;

  /// Whether this output has already been spent.
  final bool spent;

  /// Whether this output originates from a coinbase transaction.
  final bool coinbase;

  /// Returns a copy of this [Output] instance, with the [isFrozen] status
  /// updated.
  CsOutput copyWithFrozen(bool isFrozen) => CsOutput(
    address: address,
    hash: hash,
    keyImage: keyImage,
    value: value,
    isFrozen: isFrozen,
    isUnlocked: isUnlocked,
    height: height,
    spentHeight: spentHeight,
    vout: vout,
    spent: spent,
    coinbase: coinbase,
  );
}
