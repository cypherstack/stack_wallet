import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_monero/api/exceptions/creation_transaction_exception.dart';
import 'package:cw_monero/monero_wallet.dart';
import 'package:cw_monero/monero_wallet_service.dart';
import 'package:cw_monero/pending_monero_transaction.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_libmonero/core/wallet_creation_service.dart';
import 'package:flutter_libmonero/monero/monero.dart' as xmr_dart;
import 'package:flutter_libmonero/view_model/send/output.dart' as monero_output;
import 'package:isar/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:tuple/tuple.dart';

import '../../../db/hive/db.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/keys/cw_key_data.dart';
import '../../../services/event_bus/events/global/tor_connection_status_changed_event.dart';
import '../../../services/event_bus/events/global/tor_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
import '../../../services/tor_service.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/fee_rate_type_enum.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../intermediate/cryptonote_wallet.dart';
import '../wallet.dart';
import '../wallet_mixin_interfaces/cw_based_interface.dart';

class MoneroWallet extends CryptonoteWallet with CwBasedInterface {
  MoneroWallet(CryptoCurrencyNetwork network) : super(Monero(network)) {
    final bus = GlobalEventBus.instance;

    // Listen for tor status changes.
    _torStatusListener = bus.on<TorConnectionStatusChangedEvent>().listen(
      (event) async {
        switch (event.newStatus) {
          case TorConnectionStatus.connecting:
            if (!_torConnectingLock.isLocked) {
              await _torConnectingLock.acquire();
            }
            _requireMutex = true;
            break;

          case TorConnectionStatus.connected:
          case TorConnectionStatus.disconnected:
            if (_torConnectingLock.isLocked) {
              _torConnectingLock.release();
            }
            _requireMutex = false;
            break;
        }
      },
    );

    // Listen for tor preference changes.
    _torPreferenceListener = bus.on<TorPreferenceChangedEvent>().listen(
      (event) async {
        await updateNode();
      },
    );
  }

  @override
  MoneroWalletBase? cwWalletBase;

  @override
  MoneroWalletService? cwWalletService;

  @override
  Address addressFor({required int index, int account = 0}) {
    final String address = (cwWalletBase as MoneroWalletBase)
        .getTransactionAddress(account, index);

    final newReceivingAddress = Address(
      walletId: walletId,
      derivationIndex: index,
      derivationPath: null,
      value: address,
      publicKey: [],
      type: AddressType.cryptonote,
      subType: AddressSubType.receiving,
    );

    return newReceivingAddress;
  }

  @override
  Future<void> open() async {
    String? password;
    try {
      password = await cwKeysStorage.getWalletPassword(walletName: walletId);
    } catch (e, s) {
      throw Exception("Password not found $e, $s");
    }

    bool wasNull = false;

    if (cwWalletBase == null) {
      wasNull = true;
      // cwWalletBaseT?.close();
      cwWalletBase ??= (await cwWalletService!.openWallet(walletId, password))
          as MoneroWalletBase;

      cwWalletBase?.onNewBlock ??= onNewBlock;
      cwWalletBase?.onNewTransaction ??= onNewTransaction;
      cwWalletBase?.syncStatusChanged ??= syncStatusChanged;

      await updateNode();
    }

    Address? currentAddress = await getCurrentReceivingAddress();
    if (currentAddress == null) {
      currentAddress = addressFor(index: 0);
      await mainDB.updateOrPutAddresses([currentAddress]);
    }
    if (info.cachedReceivingAddress != currentAddress.value) {
      await info.updateReceivingAddress(
        newAddress: currentAddress.value,
        isar: mainDB.isar,
      );
    }

    if (wasNull) {
      await cwWalletBase?.startSync();
    } else {
      cwWalletBase?.wallet.startListeners();
    }
    unawaited(refresh());

    autoSaveTimer?.cancel();
    autoSaveTimer = Timer.periodic(
      const Duration(seconds: 193),
      (_) async => await cwWalletBase?.save(),
    );
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    if (cwWalletBase == null || cwWalletBase?.syncStatus is! SyncedSyncStatus) {
      return Amount.zeroWith(
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    }

    MoneroTransactionPriority priority;
    switch (feeRate) {
      case 1:
        priority = MoneroTransactionPriority.regular;
        break;
      case 2:
        priority = MoneroTransactionPriority.medium;
        break;
      case 3:
        priority = MoneroTransactionPriority.fast;
        break;
      case 4:
        priority = MoneroTransactionPriority.fastest;
        break;
      case 0:
      default:
        priority = MoneroTransactionPriority.slow;
        break;
    }

    int approximateFee = 0;
    await estimateFeeMutex.protect(() async {
      approximateFee = cwWalletBase!.calculateEstimatedFee(
        priority,
        amount.raw.toInt(),
      );
    });

    return Amount(
      rawValue: BigInt.from(approximateFee),
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }

  @override
  Future<bool> pingCheck() async {
    return await cwWalletBase?.isConnected() ?? false;
  }

  @override
  Future<void> updateNode() async {
    final node = getCurrentNode();

    String host = Uri.parse(node.host).host;
    if (host.isEmpty) {
      host = node.host;
    }
    ({InternetAddress host, int port})? proxy;
    if (prefs.useTor) {
      proxy = TorService.sharedInstance.getProxyInfo();
    }
    if (_requireMutex) {
      await _torConnectingLock.protect(() async {
        await cwWalletBase?.connectToNode(
          node: Node(
            uri: "$host:${node.port}",
            type: WalletType.monero,
            trusted: node.trusted ?? false,
            useSSL: node.useSSL,
          ),
          socksProxyAddress:
              proxy == null ? null : "${proxy.host.address}:${proxy.port}",
        );
      });
    } else {
      await cwWalletBase?.connectToNode(
        node: Node(
          uri: "$host:${node.port}",
          type: WalletType.monero,
          trusted: node.trusted ?? false,
          useSSL: node.useSSL,
        ),
        socksProxyAddress:
            proxy == null ? null : "${proxy.host.address}:${proxy.port}",
      );
    }

    return;
  }

  @override
  Future<CWKeyData?> getKeys() async {
    final base = cwWalletBase;

    if (base == null || base.walletInfo.name != walletId) {
      return null;
    }

    return CWKeyData(
      walletId: walletId,
      publicViewKey: base.keys.publicViewKey,
      privateViewKey: base.keys.privateViewKey,
      publicSpendKey: base.keys.publicSpendKey,
      privateSpendKey: base.keys.privateSpendKey,
    );
  }

  @override
  Future<void> updateTransactions() async {
    final base = cwWalletBase;

    if (base == null || base.walletInfo.name != walletId) {
      return;
    }
    await base.updateTransactions();
    final transactions = base.transactionHistory?.transactions;

    // final cachedTransactions =
    // DB.instance.get<dynamic>(boxName: walletId, key: 'latest_tx_model')
    // as TransactionData?;
    // int latestTxnBlockHeight =
    //     DB.instance.get<dynamic>(boxName: walletId, key: "storedTxnDataHeight")
    //     as int? ??
    //         0;
    //
    // final txidsList = DB.instance
    //     .get<dynamic>(boxName: walletId, key: "cachedTxids") as List? ??
    //     [];
    //
    // final Set<String> cachedTxids = Set<String>.from(txidsList);

    // TODO: filter to skip cached + confirmed txn processing in next step
    // final unconfirmedCachedTransactions =
    //     cachedTransactions?.getAllTransactions() ?? {};
    // unconfirmedCachedTransactions
    //     .removeWhere((key, value) => value.confirmedStatus);
    //
    // if (cachedTransactions != null) {
    //   for (final tx in allTxHashes.toList(growable: false)) {
    //     final txHeight = tx["height"] as int;
    //     if (txHeight > 0 &&
    //         txHeight < latestTxnBlockHeight - MINIMUM_CONFIRMATIONS) {
    //       if (unconfirmedCachedTransactions[tx["tx_hash"] as String] == null) {
    //         allTxHashes.remove(tx);
    //       }
    //     }
    //   }
    // }

    final List<Tuple2<Transaction, Address?>> txnsData = [];

    if (transactions != null) {
      for (final tx in transactions.entries) {
        Address? address;
        TransactionType type;
        if (tx.value.direction == TransactionDirection.incoming) {
          final addressInfo = tx.value.additionalInfo;

          final addressString = cwWalletBase?.getTransactionAddress(
            addressInfo!['accountIndex'] as int,
            addressInfo['addressIndex'] as int,
          );

          if (addressString != null) {
            address = await mainDB
                .getAddresses(walletId)
                .filter()
                .valueEqualTo(addressString)
                .findFirst();
          }

          type = TransactionType.incoming;
        } else {
          // txn.address = "";
          type = TransactionType.outgoing;
        }

        final txn = Transaction(
          walletId: walletId,
          txid: tx.value.id,
          timestamp: (tx.value.date.millisecondsSinceEpoch ~/ 1000),
          type: type,
          subType: TransactionSubType.none,
          amount: tx.value.amount ?? 0,
          amountString: Amount(
            rawValue: BigInt.from(tx.value.amount ?? 0),
            fractionDigits: cryptoCurrency.fractionDigits,
          ).toJsonString(),
          fee: tx.value.fee ?? 0,
          height: tx.value.height,
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
  Future<void> init({bool? isRestore}) async {
    cwWalletService ??= xmr_dart.monero
            .createMoneroWalletService(DB.instance.moneroWalletInfoBox)
        as MoneroWalletService;

    if (!(await cwWalletService!.isWalletExist(walletId)) &&
        isRestore != true) {
      WalletInfo walletInfo;
      WalletCredentials credentials;
      try {
        final dirPath =
            await pathForWalletDir(name: walletId, type: WalletType.monero);
        final path =
            await pathForWallet(name: walletId, type: WalletType.monero);
        credentials = xmr_dart.monero.createMoneroNewWalletCredentials(
          name: walletId,
          language: "English",
        );

        walletInfo = WalletInfo.external(
          id: WalletBase.idFor(walletId, WalletType.monero),
          name: walletId,
          type: WalletType.monero,
          isRecovery: false,
          restoreHeight: credentials.height ?? 0,
          date: DateTime.now(),
          path: path,
          dirPath: dirPath,
          address: '',
        );
        credentials.walletInfo = walletInfo;

        final _walletCreationService = WalletCreationService(
          secureStorage: secureStorageInterface,
          walletService: cwWalletService!,
          keyService: cwKeysStorage,
          type: WalletType.monero,
        );
        // To restore from a seed
        final wallet = await _walletCreationService.create(credentials);

        // subtract a couple days to ensure we have a buffer for SWB
        final bufferedCreateHeight = xmr_dart.monero.getHeigthByDate(
          date: DateTime.now().subtract(const Duration(days: 2)),
        );

        await info.updateRestoreHeight(
          newRestoreHeight: bufferedCreateHeight,
          isar: mainDB.isar,
        );

        // special case for xmr/wow. Normally mnemonic + passphrase is saved
        // before wallet.init() is called
        await secureStorageInterface.write(
          key: Wallet.mnemonicKey(walletId: walletId),
          value: wallet.seed.trim(),
        );
        await secureStorageInterface.write(
          key: Wallet.mnemonicPassphraseKey(walletId: walletId),
          value: "",
        );

        walletInfo.restoreHeight = bufferedCreateHeight;

        walletInfo.address = wallet.walletAddresses.address;
        await DB.instance
            .add<WalletInfo>(boxName: WalletInfo.boxName, value: walletInfo);

        wallet.close();
      } catch (e, s) {
        Logging.instance.log("$e\n$s", level: LogLevel.Fatal);
        cwWalletBase?.close();
      }
      await updateNode();
    }

    return super.init();
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    if (isRescan) {
      await refreshMutex.protect(() async {
        // clear blockchain info
        await mainDB.deleteWalletBlockchainData(walletId);

        final restoreHeight = cwWalletBase?.walletInfo.restoreHeight;
        highestPercentCached = 0;
        await cwWalletBase?.rescan(height: restoreHeight ?? 0);
      });
      unawaited(refresh());
      return;
    }

    await refreshMutex.protect(() async {
      final mnemonic = await getMnemonic();
      final seedLength = mnemonic.trim().split(" ").length;

      if (seedLength != 25 && seedLength != 16) {
        throw Exception("Invalid monero mnemonic length found: $seedLength");
      }

      try {
        final height = max(info.restoreHeight, 0);

        await info.updateRestoreHeight(
          newRestoreHeight: height,
          isar: mainDB.isar,
        );

        cwWalletService = xmr_dart.monero
                .createMoneroWalletService(DB.instance.moneroWalletInfoBox)
            as MoneroWalletService;
        WalletInfo walletInfo;
        WalletCredentials credentials;
        final String name = walletId;
        final dirPath =
            await pathForWalletDir(name: name, type: WalletType.monero);
        final path = await pathForWallet(name: name, type: WalletType.monero);
        credentials =
            xmr_dart.monero.createMoneroRestoreWalletFromSeedCredentials(
          name: name,
          height: height,
          mnemonic: mnemonic.trim(),
        );
        try {
          walletInfo = WalletInfo.external(
            id: WalletBase.idFor(name, WalletType.monero),
            name: name,
            type: WalletType.monero,
            isRecovery: false,
            restoreHeight: credentials.height ?? 0,
            date: DateTime.now(),
            path: path,
            dirPath: dirPath,
            address: '',
          );
          credentials.walletInfo = walletInfo;

          final cwWalletCreationService = WalletCreationService(
            secureStorage: secureStorageInterface,
            walletService: cwWalletService!,
            keyService: cwKeysStorage,
            type: WalletType.monero,
          );
          // To restore from a seed
          final wallet =
              await cwWalletCreationService.restoreFromSeed(credentials);
          walletInfo.address = wallet.walletAddresses.address;
          await DB.instance
              .add<WalletInfo>(boxName: WalletInfo.boxName, value: walletInfo);
          if (walletInfo.address != null) {
            final newReceivingAddress = await getCurrentReceivingAddress() ??
                Address(
                  walletId: walletId,
                  derivationIndex: 0,
                  derivationPath: null,
                  value: walletInfo.address!,
                  publicKey: [],
                  type: AddressType.cryptonote,
                  subType: AddressSubType.receiving,
                );

            await mainDB.updateOrPutAddresses([newReceivingAddress]);
            await info.updateReceivingAddress(
              newAddress: newReceivingAddress.value,
              isar: mainDB.isar,
            );
          }
          cwWalletBase?.close();
          cwWalletBase = wallet as MoneroWalletBase;
        } catch (e, s) {
          Logging.instance.log("$e\n$s", level: LogLevel.Fatal);
        }
        await updateNode();

        await cwWalletBase?.rescan(height: credentials.height);
        cwWalletBase?.close();
      } catch (e, s) {
        Logging.instance.log(
          "Exception rethrown from recoverFromMnemonic(): $e\n$s",
          level: LogLevel.Error,
        );
        rethrow;
      }
    });
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    try {
      final feeRate = txData.feeRateType;
      if (feeRate is FeeRateType) {
        MoneroTransactionPriority feePriority;
        switch (feeRate) {
          case FeeRateType.fast:
            feePriority = MoneroTransactionPriority.fast;
            break;
          case FeeRateType.average:
            feePriority = MoneroTransactionPriority.regular;
            break;
          case FeeRateType.slow:
            feePriority = MoneroTransactionPriority.slow;
            break;
          default:
            throw ArgumentError("Invalid use of custom fee");
        }

        Future<PendingTransaction>? awaitPendingTransaction;
        try {
          // check for send all
          bool isSendAll = false;
          final balance = await availableBalance;
          if (txData.amount! == balance &&
              txData.recipients!.first.amount == balance) {
            isSendAll = true;
          }

          final List<monero_output.Output> outputs = [];
          for (final recipient in txData.recipients!) {
            final output = monero_output.Output(cwWalletBase!);
            output.address = recipient.address;
            output.sendAll = isSendAll;
            final String amountToSend = recipient.amount.decimal.toString();
            output.setCryptoAmount(amountToSend);
            outputs.add(output);
          }

          final tmp =
              xmr_dart.monero.createMoneroTransactionCreationCredentials(
            outputs: outputs,
            priority: feePriority,
          );

          await prepareSendMutex.protect(() async {
            awaitPendingTransaction = cwWalletBase!.createTransaction(tmp);
          });
        } catch (e, s) {
          Logging.instance.log(
            "Exception rethrown from prepareSend(): $e\n$s",
            level: LogLevel.Warning,
          );
        }

        final PendingMoneroTransaction pendingMoneroTransaction =
            await (awaitPendingTransaction!) as PendingMoneroTransaction;
        final realFee = Amount.fromDecimal(
          Decimal.parse(pendingMoneroTransaction.feeFormatted),
          fractionDigits: cryptoCurrency.fractionDigits,
        );

        return txData.copyWith(
          fee: realFee,
          pendingMoneroTransaction: pendingMoneroTransaction,
        );
      } else {
        throw ArgumentError("Invalid fee rate argument provided!");
      }
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from prepare send(): $e\n$s",
        level: LogLevel.Info,
      );

      if (e.toString().contains("Incorrect unlocked balance")) {
        throw Exception("Insufficient balance!");
      } else if (e is CreationTransactionException) {
        throw Exception("Insufficient funds to pay for transaction fee!");
      } else {
        throw Exception("Transaction failed with error code $e");
      }
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      try {
        await txData.pendingMoneroTransaction!.commit();
        Logging.instance.log(
          "transaction ${txData.pendingMoneroTransaction!.id} has been sent",
          level: LogLevel.Info,
        );
        return txData.copyWith(txid: txData.pendingMoneroTransaction!.id);
      } catch (e, s) {
        Logging.instance.log(
          "${info.name} monero confirmSend: $e\n$s",
          level: LogLevel.Error,
        );
        rethrow;
      }
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from confirmSend(): $e\n$s",
        level: LogLevel.Info,
      );
      rethrow;
    }
  }

  @override
  Future<Amount> get availableBalance async {
    try {
      int runningBalance = 0;
      for (final entry in cwWalletBase!.balance!.entries) {
        runningBalance += entry.value.unlockedBalance;
      }
      return Amount(
        rawValue: BigInt.from(runningBalance),
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    } catch (_) {
      return info.cachedBalance.spendable;
    }
  }

  @override
  Future<Amount> get totalBalance async {
    try {
      final balanceEntries = cwWalletBase?.balance?.entries;
      if (balanceEntries != null) {
        int bal = 0;
        for (final element in balanceEntries) {
          bal = bal + element.value.fullBalance;
        }
        return Amount(
          rawValue: BigInt.from(bal),
          fractionDigits: cryptoCurrency.fractionDigits,
        );
      } else {
        final transactions = cwWalletBase!.transactionHistory!.transactions;
        int transactionBalance = 0;
        for (final tx in transactions!.entries) {
          if (tx.value.direction == TransactionDirection.incoming) {
            transactionBalance += tx.value.amount!;
          } else {
            transactionBalance += -tx.value.amount! - tx.value.fee!;
          }
        }

        return Amount(
          rawValue: BigInt.from(transactionBalance),
          fractionDigits: cryptoCurrency.fractionDigits,
        );
      }
    } catch (_) {
      return info.cachedBalance.total;
    }
  }

  // ============== Private ====================================================

  StreamSubscription<TorConnectionStatusChangedEvent>? _torStatusListener;
  StreamSubscription<TorPreferenceChangedEvent>? _torPreferenceListener;

  final Mutex _torConnectingLock = Mutex();
  bool _requireMutex = false;
}
