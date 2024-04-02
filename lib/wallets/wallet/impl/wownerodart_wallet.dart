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
import 'package:stackwallet/wallets/crypto_currency/coins/wownero.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:monero/wownero.dart' as wownero;
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/mnemonic_interface.dart';
import 'package:tuple/tuple.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stack_wallet_backup/generate_password.dart';
import 'package:flutter_libmonero/entities/secret_store_key.dart';

final wownero.WalletManager wowWmPtr =
    wownero.WalletManagerFactory_getWalletManager();

wownero.wallet? wowwPtr;
Timer? syncCheckTimer;

class WowneroDartWallet extends Wallet with MnemonicInterface {
  WowneroDartWallet(CryptoCurrencyNetwork network) : super(Wownero(network));

  @override
  FilterOperation? get changeAddressFilterOperation => null;

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    final address = await getCurrentReceivingAddress();
    if (address == null) {
      final address = Address(
        walletId: walletId,
        value: wownero.Wallet_address(wowwPtr!),
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
    wownero.PendingTransaction_commit(txData.pendingTransactionPtr!,
        filename: '', overwrite: false);
    final status =
        wownero.PendingTransaction_status(txData.pendingTransactionPtr!);
    if (status != 0) {
      throw Exception(
        wownero.PendingTransaction_errorString(txData.pendingTransactionPtr!),
      );
    }
    // TODO(mrcyjanek): Do I need to touch this variable?
    // None of the metadata changed, it just got pushed.
    return txData.copyWith(
      txid: wownero.PendingTransaction_txid(
        txData.pendingTransactionPtr!,
        " ",
      ),
    );
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    // TODO(mrcyjanek): not implemented in wownero.c/wownero.dart
    return Amount(
        rawValue: BigInt.from(1),
        fractionDigits: cryptoCurrency.fractionDigits);
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
    return (wowwPtr == null);
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    if (wowwPtr == null) {
      throw Exception("unable to prepare transaction, wallet pointer is null");
    }

    final txPtr = wownero.Wallet_createTransaction(
      wowwPtr!,
      dst_addr: txData.recipients!.first.address,
      payment_id: '',
      amount: txData.recipients!.first.amount.raw.toInt(),
      mixin_count: 0,
      // TODO(mrcyjanek): How can I get the number that I've set in fees?
      pendingTransactionPriority: 0,
      subaddr_account: 0,
    );

    final status = wownero.PendingTransaction_status(txPtr);
    if (status != 0) {
      throw Exception(
        wownero.PendingTransaction_errorString(txPtr),
      );
    }

    final tx = txData.copyWith(
        pendingTransactionPtr: txPtr,
        txHash: wownero.PendingTransaction_txid(txPtr, ' ').trim(),
        fee: Amount(
            rawValue: BigInt.from(wownero.PendingTransaction_fee(txPtr)),
            fractionDigits: cryptoCurrency.fractionDigits),
        txid: wownero.PendingTransaction_txid(txPtr, ' ').trim());
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
    final total = Amount(
        rawValue: BigInt.from(wownero.Wallet_balance(wowwPtr!, accountIndex: 0)),
        fractionDigits: cryptoCurrency.fractionDigits);
    final available = Amount(
        rawValue: BigInt.from(
            wownero.Wallet_unlockedBalance(wowwPtr!, accountIndex: 0)),
        fractionDigits: cryptoCurrency.fractionDigits);

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
    final addr = wowwPtr!.address;
    final height = await Isolate.run(() async {
      return wownero.Wallet_daemonBlockChainHeight(Pointer.fromAddress(addr));
    });
    await info.updateCachedChainHeight(
      newHeight: height,
      isar: mainDB.isar,
    );
  }

  int i = 0;
  Future<void> refreshSyncTimer() async {
    await updateChainHeight();
    final height = info.cachedChainHeight;
    if (wowwPtr == null) {
      syncCheckTimer?.cancel();
      return;
    }
    await updateTransactions();
    i++;
    if (i > 10) {
      wownero.Wallet_store(wowwPtr!);
    }
    final curHeight = wownero.Wallet_blockChainHeight(wowwPtr!);
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
    if (wownero.Wallet_synchronized(wowwPtr!) && (height - curHeight) == 0) {
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
    wownero.Wallet_rescanBlockchainAsync(wowwPtr!);
    await refreshSyncTimer();
    wownero.Wallet_startRefresh(wowwPtr!);
    return;
  }

  @override
  Future<void> refresh() async {
    wownero.Wallet_refreshAsync(wowwPtr!);
    await refreshSyncTimer();
    await super.refresh();
  }

  @override
  Future<void> updateNode() async {
    final node = getCurrentNode();
    final host = Uri.parse(node.host).host;
    final proxy = (TorService.sharedInstance.status ==
            TorConnectionStatus.connected)
        ? "${TorService.sharedInstance.getProxyInfo().host.address}:${TorService.sharedInstance.getProxyInfo().port}"
        : "";
    print("proxy: $proxy");
    wownero.Wallet_init(wowwPtr!,
        daemonAddress: "node.suchwow.xyz:34568", proxyAddress: proxy);
    wownero.Wallet_init3(wowwPtr!,
        argv0: '',
        defaultLogBaseName: 'wowneroc',
        console: true,
        logPath: '/tmp/log-wownero.txt');
    syncCheckTimer?.cancel();
    syncCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      refreshSyncTimer();
    });
    // wownero.Wallet_rescanBlockchainAsync(wowwPtr!);
    wownero.Wallet_startRefresh(wowwPtr!);
    wownero.Wallet_refreshAsync(wowwPtr!);
    print("node: $host:${node.port}");
    final addr = wowwPtr!.address;
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

  List<WowneroTransaction> getTransactionList() {
    print("getTransactionList");
    final txHistoryPtr = wownero.Wallet_history(wowwPtr!);
    wownero.TransactionHistory_refresh(txHistoryPtr);
    final txCount = wownero.TransactionHistory_count(txHistoryPtr);
    final txList = List.generate(
      txCount,
      (index) => WowneroTransaction(
        wowwPtr: wowwPtr!,
        txInfo:
            wownero.TransactionHistory_transaction(txHistoryPtr, index: index),
      ),
    );
    print("txList: ${txList.length}");
    return txList;
  }

  @override
  Future<void> init({bool? isRestore}) async {
    final walletPath = await pathForWalletDir(name: walletId);
    print("$walletPath:$walletPath");
    final walletExists = wownero.WalletManager_walletExists(wowWmPtr, walletPath);
    print("walletExists: $walletExists ; isRestore: $isRestore");
    if (!walletExists && isRestore == true) {
      if (wowwPtr != null) {
        wownero.Wallet_store(wowwPtr!);
      }

      final mnemonic = await getMnemonicAsWords();
      if ((await getMnemonicAsWords()).length == 16) {
        wowwPtr = wownero.WalletManager_createWalletFromPolyseed(
          wowWmPtr,
          path: walletPath,
          password: await keysStorage.getWalletPassword(walletName: walletId),
          mnemonic: mnemonic.join(' '),
          seedOffset: '',
          newWallet: true,
          restoreHeight: info.restoreHeight,
          kdfRounds: 1,
        );
      } else {
        wowwPtr = wownero.WalletManager_recoveryWallet(
          wowWmPtr,
          path: walletPath,
          password: await keysStorage.getWalletPassword(walletName: walletId),
          mnemonic: mnemonic.join(' '),
          restoreHeight: info.restoreHeight,
          seedOffset: '',
        );
      }
      if (wownero.Wallet_status(wowwPtr!) != 0) {
        throw Exception(wownero.Wallet_errorString(wowwPtr!));
      }

      wownero.Wallet_rescanBlockchainAsync(wowwPtr!);
      wownero.Wallet_store(wowwPtr!);
      // await updateNode();

      return;
    } else {
      final mnemonic = wownero.Wallet_createPolyseed();
      await secureStorageInterface.write(
        key: Wallet.mnemonicKey(walletId: walletId),
        value: mnemonic.trim(),
      );
      await secureStorageInterface.write(
        key: Wallet.mnemonicPassphraseKey(walletId: walletId),
        value: "",
      );
      if ((await getMnemonicAsWords()).length == 16) {
        wowwPtr = wownero.WalletManager_createWalletFromPolyseed(
          wowWmPtr,
          path: walletPath,
          password: await keysStorage.getWalletPassword(walletName: walletId),
          mnemonic: mnemonic,
          seedOffset: '',
          newWallet: true,
          restoreHeight: info.restoreHeight,
          kdfRounds: 1,
        );
      } else {
        wowwPtr = wownero.WalletManager_recoveryWallet(
          wowWmPtr,
          path: walletPath,
          password: await keysStorage.getWalletPassword(walletName: walletId),
          mnemonic: mnemonic,
          restoreHeight: info.restoreHeight,
          seedOffset: '',
        );
      }
      wowwPtr = wownero.WalletManager_openWallet(wowWmPtr,
          path: walletPath,
          password: await keysStorage.getWalletPassword(walletName: walletId));
      print(
          "status: ${wownero.Wallet_status(wowwPtr!)}: ${wownero.Wallet_errorString(wowwPtr!)}");
      print("address: ${wownero.Wallet_address(wowwPtr!)}");
      // wownero.Wallet_setRefreshFromBlockHeight(wowwPtr!, refresh_from_block_height: info.restoreHeight);
      print(
          "wownero.Wallet_getRefreshFromBlockHeight: ${wownero.Wallet_getRefreshFromBlockHeight(wowwPtr!)} (${info.restoreHeight})");
      final polyseed =
          wownero.Wallet_getPolyseed(wowwPtr!, passphrase: '').trim();
      final legacySeed = wownero.Wallet_seed(wowwPtr!, seedOffset: '').trim();
      await secureStorageInterface.write(
        key: Wallet.mnemonicKey(walletId: walletId),
        value: (polyseed.isNotEmpty) ? polyseed : legacySeed,
      );
    }

    await checkSaveInitialReceivingAddress();
    final address = await getCurrentReceivingAddress();
    if (address != null) {
      await info.updateReceivingAddress(
        newAddress: address.value,
        isar: mainDB.isar,
      );
    }
    await updateNode();
  }
}

// stolen from
// crypto_plugins/flutter_libwownero/cw_core/lib/pathForWallet.dart
Future<String> pathForWalletDir({required String name}) async {
  Directory root = await applicationRootDirectory();

  final walletsDir = Directory('${root.path}/wallets');
  final walletDire = Directory('${walletsDir.path}/wownerodart/$name');

  if (!walletDire.existsSync()) {
    walletDire.createSync(recursive: true);
  }

  return "${walletDire.path}/wownerodart_wallet";
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

class WowneroTransaction {
  wownero.wallet wowwPtr;
  final String displayLabel;
  late String subaddressLabel = getSubaddressLabel(wowwPtr, 0); // TODO: fixme
  late final String address = wownero.Wallet_address(
    wowwPtr,
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
  final wownero.TransactionInfo txInfo;
  WowneroTransaction({
    required this.wowwPtr,
    required this.txInfo,
  })  : displayLabel = wownero.TransactionInfo_label(txInfo),
        hash = wownero.TransactionInfo_hash(txInfo),
        timeStamp = DateTime.fromMillisecondsSinceEpoch(
          wownero.TransactionInfo_timestamp(txInfo) * 1000,
        ),
        isSpend = wownero.TransactionInfo_direction(txInfo) ==
            wownero.TransactionInfo_Direction.Out,
        amount = wownero.TransactionInfo_amount(txInfo),
        paymentId = wownero.TransactionInfo_paymentId(txInfo),
        accountIndex = wownero.TransactionInfo_subaddrAccount(txInfo),
        blockheight = wownero.TransactionInfo_blockHeight(txInfo),
        confirmations = wownero.TransactionInfo_confirmations(txInfo),
        fee = wownero.TransactionInfo_fee(txInfo),
        description = wownero.TransactionInfo_description(txInfo);
}

String getSubaddressLabel(wownero.wallet walletPtr, int addressIndex) {
  final label = wownero.Wallet_getSubaddressLabel(walletPtr,
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
      await saveWalletPassword(
          walletName: walletName, password: generatePassword());
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
