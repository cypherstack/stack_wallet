import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/event_bus/events/global/blocks_remaining_event.dart';
import 'package:stackwallet/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/monero.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:monero/monero.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/mnemonic_interface.dart';
import 'package:tuple/tuple.dart';
import 'package:stackwallet/exceptions/sw_exception.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stack_wallet_backup/generate_password.dart';
import 'package:flutter_libmonero/entities/secret_store_key.dart';
bool tRan = false;

final MONERO_WalletManager wmPtr = MONERO_WalletManagerFactory_getWalletManager();

MONERO_wallet? wPtr;
Timer? syncCheckTimer;

class MoneroDartWallet extends Wallet with MnemonicInterface {
  MoneroDartWallet(CryptoCurrencyNetwork network) : super(Monero(network));


  @override
  FilterOperation? get changeAddressFilterOperation => null;

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    final address = await getCurrentReceivingAddress();
    if (address == null) {
      final address = Address(
        walletId: walletId,
        value: MONERO_Wallet_address(wPtr!),
        publicKey: [],
        derivationIndex: 0,
        derivationPath: null,
        type: AddressType.cryptonote,
        subType: AddressSubType.receiving,
      );
      await mainDB.updateOrPutAddresses([address]);
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    MONERO_PendingTransaction_commit(txData.pendingTransactionPtr!, filename: '', overwrite: false);
    // TODO(mrcyjanek): Do I need to touch this variable?
    // None of the metadata changed, it just got pushed.
    return txData;
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    // TODO(mrcyjanek): not implemented in monero_c/monero.dart
    return Amount(rawValue: BigInt.from(1), fractionDigits: cryptoCurrency.fractionDigits);
  }

  @override
  Future<FeeObject> get fees async => FeeObject(
        numberOfBlocksFast: 10,
        numberOfBlocksAverage: 15,
        numberOfBlocksSlow: 20,
        fast: 3,
        medium: 2,
        slow: 1,
      );

  @override
  Future<bool> pingCheck() async {
    // TODO(mrcyjanek): proper check.
    return (wPtr == null);
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    if (wPtr == null) {
      throw Exception("unable to prepare transaction, wallet pointer is null");
    }
    final txPtr = MONERO_Wallet_createTransaction(
      wPtr!,
      dst_addr: txData.recipients!.first.address,
      payment_id: '',
      amount: txData.recipients!.first.amount.raw.toInt(),
      mixin_count: 0,
      // TODO(mrcyjanek): How can I get the number that I've set in fees?
      pendingTransactionPriority: 0,
      subaddr_account: 0,
    );
    final tx = txData.copyWith(
      pendingTransactionPtr: txPtr,
      txHash: MONERO_PendingTransaction_txid(txPtr, ' ').trim(),
      fee: Amount(rawValue: BigInt.from(MONERO_PendingTransaction_fee(txPtr)), fractionDigits: cryptoCurrency.fractionDigits),
    );
    return tx;
  }

  @override
  // TODO(mrcyjanek): Do I need this? Some currencies leave this empty
  FilterOperation? get receivingAddressFilterOperation => null;

  KeyService? _keysStorageCached;
  KeyService get keysStorage =>
      _keysStorageCached ??= KeyService(secureStorageInterface);

  @override
  Future<void> updateBalance() async {
    final total = Amount(rawValue: BigInt.from(MONERO_Wallet_balance(wPtr!, accountIndex: 0)), fractionDigits: cryptoCurrency.fractionDigits);
    final available = Amount(rawValue: BigInt.from(MONERO_Wallet_unlockedBalance(wPtr!, accountIndex: 0)), fractionDigits: cryptoCurrency.fractionDigits);
  
    final balance = Balance(
      total: total,
      spendable: available,
      blockedTotal: Amount(
        rawValue: BigInt.zero,
        fractionDigits: cryptoCurrency.fractionDigits,
      ),
      pendingSpendable: total - available,
    );

    await info.updateBalance(newBalance: balance, isar: mainDB.isar);
  }

  @override
  Future<void> updateChainHeight() async {
    final addr = wPtr!.address; 
    final height = await Isolate.run(() async {
      return MONERO_Wallet_daemonBlockChainHeight(Pointer.fromAddress(addr));
    });
    await info.updateCachedChainHeight(
      newHeight: height,
      isar: mainDB.isar,
    );
  }

  Future<void> refreshSyncTimer() async {
    await updateChainHeight();
    final height = info.cachedChainHeight;
    if (wPtr == null) {
      syncCheckTimer?.cancel();
      return;
    }
    await updateTransactions();
    MONERO_Wallet_store(wPtr!);
    final curHeight = MONERO_Wallet_blockChainHeight(wPtr!);
    GlobalEventBus.instance.fire(
      RefreshPercentChangedEvent(
        curHeight / height,
        walletId,
      ),
    );
    GlobalEventBus.instance.fire(
      BlocksRemainingEvent(
        height - curHeight,
        walletId,
      ),
    );
    if (MONERO_Wallet_synchronized(wPtr!) && (height - curHeight) == 0) {
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          cryptoCurrency.coin,
        ),
      );
    } else {
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.syncing,
          walletId,
          cryptoCurrency.coin,
        ),
      );
    }
  }
  @override
  Future<void> recover({required bool isRescan}) async {
    await refreshSyncTimer();
    MONERO_Wallet_rescanBlockchainAsync(wPtr!);
    await refreshSyncTimer();
    MONERO_Wallet_startRefresh(wPtr!);
    return;
  }

  @override
  Future<void> refresh() async {

    MONERO_Wallet_refreshAsync(wPtr!);
    await refreshSyncTimer();
    await super.refresh();
  }

  @override
  Future<void> updateNode() async {
    final node = getCurrentNode();
    final host = Uri.parse(node.host).host;
    final proxy = (TorService.sharedInstance.status == TorConnectionStatus.connected) ?
      "${TorService.sharedInstance.getProxyInfo().host.address}:${TorService.sharedInstance.getProxyInfo().port}" : "";
    print("proxy: $proxy");
    MONERO_Wallet_init(wPtr!, daemonAddress: "$host:${node.port}", proxyAddress: proxy);
    MONERO_Wallet_init3(wPtr!, argv0: '', defaultLogBaseName: 'moneroc', console: true, logPath: '/dev/shm/log.txt');
    syncCheckTimer?.cancel();
    syncCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      refreshSyncTimer();
    });
    // MONERO_Wallet_rescanBlockchainAsync(wPtr!);
    MONERO_Wallet_startRefresh(wPtr!);
    MONERO_Wallet_refreshAsync(wPtr!);
    print("node: $host:${node.port}");
    final addr = wPtr!.address;
    if (!tRan) {
    tRan = true;
    unawaited(Isolate.run(() {
      // NOTE: This is _kinda_ broken for some reason? Leaving it unfixed for now
      
      // MONERO_Wallet_daemonBlockChainHeight_runThread(Pointer.fromAddress(addr), 1000);
    }));
    }
  }

  @override
  Future<void> updateTransactions() async {
    print("updateTransactions");
    final List<Tuple2<Transaction, Address?>> txnsData = [];
    final transactions = getTransactionList();
    for (final tx in transactions) {
      Address? address;
      TransactionType type;
      if (!tx.isSpend) {
        final addressString = tx.address;
        address = await mainDB
            .getAddresses(walletId)
            .filter()
            .valueEqualTo(addressString)
            .findFirst();
      
        type = TransactionType.incoming;
      } else {
        // txn.address = "";
        type = TransactionType.outgoing;
      }

      final txn = Transaction(
        walletId: walletId,
        txid: tx.hash,
        timestamp: (tx.timeStamp.millisecondsSinceEpoch ~/ 1000),
        type: type,
        subType: TransactionSubType.none,
        amount: tx.amount,
        amountString: Amount(
          rawValue: BigInt.from(tx.amount),
          fractionDigits: cryptoCurrency.fractionDigits,
        ).toJsonString(),
        fee: tx.fee,
        height: tx.blockheight,
        isCancelled: false,
        isLelantus: false,
        slateId: null,
        otherData: null,
        nonce: null,
        inputs: [],
        outputs: [],
        numberOfMessages: null,
      );

      txnsData.add(Tuple2(txn, address));
    }
  
    await mainDB.isar.writeTxn(() async {
      await mainDB.isar.transactions
          .where()
          .walletIdEqualTo(walletId)
          .deleteAll();
      for (final data in txnsData) {
        final tx = data.item1;

        // save transaction
        await mainDB.isar.transactions.put(tx);

        if (data.item2 != null) {
          final address = await mainDB.getAddress(walletId, data.item2!.value);

          // check if address exists in db and add if it does not
          if (address == null) {
            await mainDB.isar.addresses.put(data.item2!);
          }

          // link and save address
          tx.address.value = address ?? data.item2!;
          await tx.address.save();
        }
      }
    });
  }

  @override
  Future<bool> updateUTXOs() async {
    return false;
  }

  List<MoneroTransaction> getTransactionList() {
    print("getTransactionList");
    final txHistoryPtr = MONERO_Wallet_history(wPtr!);
    MONERO_TransactionHistory_refresh(txHistoryPtr);
    final txCount = MONERO_TransactionHistory_count(txHistoryPtr);
    final txList = List.generate(
      txCount,
      (index) => MoneroTransaction(
        wPtr: wPtr!,
        txInfo: MONERO_TransactionHistory_transaction(txHistoryPtr, index: index),
      ),
    );
    print("txList: ${txList.length}");
    return txList;
  }


  @override
  Future<void> init({bool? isRestore}) async {
    final walletPath = await pathForWalletDir(name: walletId);
    print("$walletPath:$walletPath");
    final walletExists = MONERO_WalletManager_walletExists(wmPtr, walletPath);
    print("walletExists: $walletExists ; isRestore: $isRestore");
    if (!walletExists && isRestore == true) {
      if (wPtr != null) {
        MONERO_Wallet_store(wPtr!);
      }

      final mnemonic = await getMnemonicAsWords();
      if ((await getMnemonicAsWords()).length == 16) {
        wPtr = MONERO_WalletManager_createWalletFromPolyseed(
          wmPtr,
          path: walletPath,
          password: await keysStorage.getWalletPassword(walletName: walletId),
          mnemonic: mnemonic.join(' '),
          seedOffset: '',
          newWallet: true,
          restoreHeight: info.restoreHeight,
          kdfRounds: 1,
        );
      } else {
        wPtr = MONERO_WalletManager_recoveryWallet(
          wmPtr,
          path: walletPath,
          password: await keysStorage.getWalletPassword(walletName: walletId),
          mnemonic: mnemonic.join(' '),
          restoreHeight: info.restoreHeight,
          seedOffset: '',
        );
      }
      if (MONERO_Wallet_status(wPtr!) != 0) {
        throw Exception(MONERO_Wallet_errorString(wPtr!));
      }
      
      await updateNode();
      MONERO_Wallet_rescanBlockchainAsync(wPtr!);
      MONERO_Wallet_store(wPtr!);

      return;
    } else {
      final mnemonic = MONERO_Wallet_createPolyseed();
      await secureStorageInterface.write(
        key: Wallet.mnemonicKey(walletId: walletId),
        value: mnemonic.trim(),
      );
      await secureStorageInterface.write(
        key: Wallet.mnemonicPassphraseKey(walletId: walletId),
        value: "",
      );
      if ((await getMnemonicAsWords()).length == 16) {
        wPtr = MONERO_WalletManager_createWalletFromPolyseed(
          wmPtr,
          path: walletPath,
          password: await keysStorage.getWalletPassword(walletName: walletId),
          mnemonic: mnemonic,
          seedOffset: '',
          newWallet: true,
          restoreHeight: info.restoreHeight,
          kdfRounds: 1,
        );
      } else {
        wPtr = MONERO_WalletManager_recoveryWallet(
          wmPtr,
          path: walletPath,
          password: await keysStorage.getWalletPassword(walletName: walletId),
          mnemonic: mnemonic,
          restoreHeight: info.restoreHeight,
          seedOffset: '',
        );
      }
      wPtr = MONERO_WalletManager_openWallet(wmPtr, path: walletPath, password: await keysStorage.getWalletPassword(walletName: walletId));
      print("status: ${MONERO_Wallet_status(wPtr!)}: ${MONERO_Wallet_errorString(wPtr!)}");
      print("address: ${MONERO_Wallet_address(wPtr!)}");
      // MONERO_Wallet_setRefreshFromBlockHeight(wPtr!, refresh_from_block_height: info.restoreHeight);
      print("MONERO_Wallet_getRefreshFromBlockHeight: ${MONERO_Wallet_getRefreshFromBlockHeight(wPtr!)} (${info.restoreHeight})");
      final polyseed = MONERO_Wallet_getPolyseed(wPtr!,passphrase: '').trim();
      final legacySeed = MONERO_Wallet_seed(wPtr!, seedOffset: '').trim();
      await secureStorageInterface.write(
        key: Wallet.mnemonicKey(walletId: walletId),
        value: (polyseed.isNotEmpty) ? polyseed : legacySeed,
      );
      await updateNode();
    }

    await checkSaveInitialReceivingAddress();
    final address = await getCurrentReceivingAddress();
    if (address != null) {
      await info.updateReceivingAddress(
        newAddress: address.value,
        isar: mainDB.isar,
      );
    }
  }
}

// stolen from
// crypto_plugins/flutter_libmonero/cw_core/lib/pathForWallet.dart
Future<String> pathForWalletDir(
    {required String name}) async {
  Directory root = await applicationRootDirectory();

  final walletsDir = Directory('${root.path}/wallets');
  final walletDire = Directory('${walletsDir.path}/monerodart/$name');

  if (!walletDire.existsSync()) {
    walletDire.createSync(recursive: true);
  }

  return "${walletDire.path}/monerodart_wallet";
}

Future<Directory> applicationRootDirectory() async {
  Directory appDirectory;

// todo: can merge and do same as regular linux home dir?
  if (const bool.fromEnvironment("IS_ARM")) {
    appDirectory = await getApplicationDocumentsDirectory();
    appDirectory = Directory("${appDirectory.path}/.stackwallet");
  } else if (Platform.isLinux) {
    appDirectory = Directory("${Platform.environment['HOME']}/.stackwallet");
  } else if (Platform.isWindows) {
// TODO: windows root .stackwallet dir location
    throw Exception("Unsupported platform");
  } else if (Platform.isMacOS) {
    appDirectory = await getLibraryDirectory();
    appDirectory = Directory("${appDirectory.path}/stackwallet");
  } else if (Platform.isIOS) {
// todo: check if we need different behaviour here
    if (await isDesktop()) {
      appDirectory = await getLibraryDirectory();
    } else {
      appDirectory = await getLibraryDirectory();
    }
  } else if (Platform.isAndroid) {
    appDirectory = await getApplicationDocumentsDirectory();
  } else {
    throw Exception("Unsupported platform");
  }
  if (!appDirectory.existsSync()) {
    await appDirectory.create(recursive: true);
  }
  return appDirectory;
}
Future<bool> isDesktop() async {
  if (Platform.isIOS) {
    Directory libraryPath = await getLibraryDirectory();
    if (!libraryPath.path.contains("/var/mobile/")) {
      return true;
    }
  }

  return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
}

const maxConfirms = 10;

class MoneroTransaction {
  MONERO_wallet wPtr;
  final String displayLabel;
  late String subaddressLabel = getSubaddressLabel(wPtr, 0); // TODO: fixme
  late final String address = MONERO_Wallet_address(
    wPtr,
    accountIndex: 0,
    addressIndex: 0,
  );
  final String description;
  final int fee;
  final int confirmations;
  late final bool isPending = confirmations < maxConfirms;
  final int blockheight;
  final int accountIndex;
  final String paymentId;
  final int amount;
  final bool isSpend;
  late DateTime timeStamp;
  late final bool isConfirmed = !isPending;
  final String hash;

  // S finalubAddress? subAddress;
  // List<Transfer> transfers = [];
  // final int txIndex;
  final MONERO_TransactionInfo txInfo;
  MoneroTransaction({
    required this.wPtr,
    required this.txInfo,
  })  : displayLabel = MONERO_TransactionInfo_label(txInfo),
        hash = MONERO_TransactionInfo_hash(txInfo),
        timeStamp = DateTime.fromMillisecondsSinceEpoch(
          MONERO_TransactionInfo_timestamp(txInfo) * 1000,
        ),
        isSpend = MONERO_TransactionInfo_direction(txInfo) ==
            TransactionInfo_Direction.Out,
        amount = MONERO_TransactionInfo_amount(txInfo),
        paymentId = MONERO_TransactionInfo_paymentId(txInfo),
        accountIndex = MONERO_TransactionInfo_subaddrAccount(txInfo),
        blockheight = MONERO_TransactionInfo_blockHeight(txInfo),
        confirmations = MONERO_TransactionInfo_confirmations(txInfo),
        fee = MONERO_TransactionInfo_fee(txInfo),
        description = MONERO_TransactionInfo_description(txInfo);
}

String getSubaddressLabel(MONERO_wallet walletPtr, int addressIndex) {
  final label = MONERO_Wallet_getSubaddressLabel(walletPtr,
      accountIndex: 0, addressIndex: addressIndex);
  if (label == "") return "SUBADDRESS #$addressIndex";
  return label;
}

class KeyService {
  KeyService(this._secureStorage);

  final dynamic _secureStorage;

  Future<String> getWalletPassword({required String walletName}) async {
    final key = generateStoreKeyFor(
        key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
    final password = await (_secureStorage.read(key: key) as FutureOr<String?>);
    if (password == null) {
      await saveWalletPassword(walletName: walletName ,password: generatePassword());
      return getWalletPassword(walletName: walletName);
    }
    return password;
  }

  Future<void> saveWalletPassword(
      {required String walletName, required String password}) async {
    final key = generateStoreKeyFor(
        key: SecretStoreKey.moneroWalletPassword, walletName: walletName);

    await _secureStorage.write(key: key, value: password);
  }
}
