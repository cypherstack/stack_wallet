import 'dart:io';

import 'package:isar/isar.dart';
import 'package:tezart/tezart.dart' as tezart;
import 'package:tuple/tuple.dart';

import '../../../exceptions/wallet/node_tor_mismatch_config_exception.dart';
import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/node_model.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../services/node_service.dart';
import '../../../services/tor_service.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/extensions/impl/string.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/tor_plain_net_option_enum.dart';
import '../../api/tezos/tezos_account.dart';
import '../../api/tezos/tezos_api.dart';
import '../../api/tezos/tezos_rpc_api.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../isar/models/wallet_info.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_wallet.dart';

// const kDefaultTransactionStorageLimit = 496;
// const kDefaultTransactionGasLimit = 10600;
//
// const kDefaultKeyRevealFee = 1270;
// const kDefaultKeyRevealStorageLimit = 0;
// const kDefaultKeyRevealGasLimit = 1100;

class TezosWallet extends Bip39Wallet<Tezos> {
  TezosWallet(CryptoCurrencyNetwork network) : super(Tezos(network));

  NodeModel? _xtzNode;

  String get derivationPath =>
      info.otherData[WalletInfoKeys.tezosDerivationPath] as String? ?? "";

  Future<DerivationPath> _scanPossiblePaths({
    required String mnemonic,
    String passphrase = "",
  }) async {
    try {
      _hackedCheckTorNodePrefs();
      for (final path in Tezos.possibleDerivationPaths) {
        final ks = await _getKeyStore(path: path.value);

        // TODO: some kind of better check to see if the address has been used

        final hasHistory =
            (await TezosAPI.getTransactions(ks.address)).isNotEmpty;

        if (hasHistory) {
          return path;
        }
      }

      return Tezos.standardDerivationPath;
    } catch (e, s) {
      Logging.instance.e(
        "Error in _scanPossiblePaths() in tezos_wallet.dart: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<tezart.Keystore> _getKeyStore({String? path}) async {
    final mnemonic = await getMnemonic();
    final passphrase = await getMnemonicPassphrase();

    return Tezos.mnemonicToKeyStore(
      mnemonic: mnemonic,
      mnemonicPassphrase: passphrase,
      derivationPath: path ?? derivationPath,
    );
  }

  Future<Address> _getAddressFromMnemonic() async {
    final keyStore = await _getKeyStore();
    return Address(
      walletId: walletId,
      value: keyStore.address,
      publicKey: keyStore.publicKey.toUint8ListFromBase58CheckEncoded,
      derivationIndex: 0,
      derivationPath: DerivationPath()..value = derivationPath,
      type: info.mainAddressType,
      subType: AddressSubType.receiving,
    );
  }

  Future<tezart.OperationsList> _buildSendTransaction({
    required Amount amount,
    required String address,
    required int counter,
    // required bool reveal,
    // int? customGasLimit,
    // Amount? customFee,
    // Amount? customRevealFee,
  }) async {
    try {
      _hackedCheckTorNodePrefs();
      final sourceKeyStore = await _getKeyStore();
      final server = (_xtzNode ?? getCurrentNode()).host;
      // if (kDebugMode) {
      //   print("SERVER: $server");
      //   print("COUNTER: $counter");
      //   print("customFee: $customFee");
      // }
      final ({InternetAddress host, int port})? proxyInfo =
          prefs.useTor ? TorService.sharedInstance.getProxyInfo() : null;
      final tezartClient = tezart.TezartClient(
        server,
        proxy: proxyInfo != null
            ? "socks5://${proxyInfo.host}:${proxyInfo.port};"
            : null,
      );

      final opList = await tezartClient.transferOperation(
        source: sourceKeyStore,
        destination: address,
        amount: amount.raw.toInt(),
        // customFee: customFee?.raw.toInt(),
        // customGasLimit: customGasLimit,
        // reveal: false,
      );

      // if (reveal) {
      //   opList.prependOperation(
      //     tezart.RevealOperation(
      //       customGasLimit: customGasLimit,
      //       customFee: customRevealFee?.raw.toInt(),
      //     ),
      //   );
      // }

      for (final op in opList.operations) {
        op.counter = counter;
        counter++;
      }

      return opList;
    } catch (e, s) {
      Logging.instance.e(
        "Error in _buildSendTransaction() in tezos_wallet.dart: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // ===========================================================================

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    try {
      final _address = await getCurrentReceivingAddress();
      if (_address == null) {
        final address = await _getAddressFromMnemonic();
        await mainDB.updateOrPutAddresses([address]);
      }
    } catch (e, s) {
      // do nothing, still allow user into wallet
      Logging.instance.e(
        "$runtimeType  checkSaveInitialReceivingAddress() failed: ",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  FilterOperation? get changeAddressFilterOperation =>
      throw UnimplementedError("Not used for $runtimeType");

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    try {
      _hackedCheckTorNodePrefs();
      if (txData.recipients == null || txData.recipients!.length != 1) {
        throw Exception("$runtimeType prepareSend requires 1 recipient");
      }

      final Amount sendAmount = txData.amount!;

      if (sendAmount > info.cachedBalance.spendable) {
        throw Exception("Insufficient available balance");
      }

      final myAddress = (await getCurrentReceivingAddress())!;
      final account = await TezosAPI.getAccount(
        myAddress.value,
      );

      // final bool isSendAll = sendAmount == info.cachedBalance.spendable;
      //
      // int? customGasLimit;
      // Amount? fee;
      // Amount? revealFee;
      //
      // if (isSendAll) {
      //   final fees = await _estimate(
      //     account,
      //     txData.recipients!.first.address,
      //   );
      //   //Fee guides for emptying a tz account
      //   // https://github.com/TezTech/eztz/blob/master/PROTO_004_FEES.md
      //   // customGasLimit = kDefaultTransactionGasLimit + 320;
      //   fee = Amount(
      //     rawValue: BigInt.from(fees.transfer + 32),
      //     fractionDigits: cryptoCurrency.fractionDigits,
      //   );
      //
      //   BigInt rawAmount = sendAmount.raw - fee.raw;
      //
      //   if (!account.revealed) {
      //     revealFee = Amount(
      //       rawValue: BigInt.from(fees.reveal + 32),
      //       fractionDigits: cryptoCurrency.fractionDigits,
      //     );
      //
      //     rawAmount = rawAmount - revealFee.raw;
      //   }
      //
      //   sendAmount = Amount(
      //     rawValue: rawAmount,
      //     fractionDigits: cryptoCurrency.fractionDigits,
      //   );
      // }

      final opList = await _buildSendTransaction(
        amount: sendAmount,
        address: txData.recipients!.first.address,
        counter: account.counter + 1,
        // reveal: !account.revealed,
        // customFee: isSendAll ? fee : null,
        // customRevealFee: isSendAll ? revealFee : null,
        // customGasLimit: customGasLimit,
      );

      await opList.computeLimits();
      await opList.computeFees();
      await opList.simulate();

      return txData.copyWith(
        recipients: [
          (
            amount: sendAmount,
            address: txData.recipients!.first.address,
            isChange: txData.recipients!.first.isChange,
          ),
        ],
        // fee: fee,
        fee: Amount(
          rawValue: opList.operations
              .map(
                (e) => BigInt.from(e.fee),
              )
              .fold(
                BigInt.zero,
                (p, e) => p + e,
              ),
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        tezosOperationsList: opList,
      );
    } catch (e, s) {
      Logging.instance.e(
        "Error in prepareSend() in tezos_wallet.dart: ",
        error: e,
        stackTrace: s,
      );

      if (e
          .toString()
          .contains("(_operationResult['errors']): Must not be null")) {
        throw Exception("Probably insufficient balance");
      } else if (e.toString().contains(
            "The simulation of the operation: \"transaction\" failed with error(s) :"
            " contract.balance_too_low, tez.subtraction_underflow.",
          )) {
        throw Exception("Insufficient balance to pay fees");
      }

      rethrow;
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    _hackedCheckTorNodePrefs();
    await txData.tezosOperationsList!.inject();
    await txData.tezosOperationsList!.monitor();
    return txData.copyWith(
      txid: txData.tezosOperationsList!.result.id,
    );
  }

  int _estCount = 0;

  Future<({int reveal, int transfer})> _estimate(
    TezosAccount account,
    String recipientAddress,
  ) async {
    _hackedCheckTorNodePrefs();
    try {
      final opList = await _buildSendTransaction(
        amount: Amount(
          rawValue: BigInt.one,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        address: recipientAddress,
        counter: account.counter + 1,
        // reveal: !account.revealed,
      );

      await opList.computeLimits();
      await opList.computeFees();
      await opList.simulate();

      int reveal = 0;
      int transfer = 0;

      for (final op in opList.operations) {
        if (op is tezart.TransactionOperation) {
          transfer += op.fee;
        } else if (op is tezart.RevealOperation) {
          reveal += op.fee;
        }
      }

      return (reveal: reveal, transfer: transfer);
    } catch (e, s) {
      if (_estCount > 3) {
        _estCount = 0;
        Logging.instance.e(
          " Error in _estimate in tezos_wallet.dart: ",
          error: e,
          stackTrace: s,
        );
        rethrow;
      } else {
        _estCount++;
        Logging.instance.e(
          "_estimate() retry _estCount=$_estCount",
        );
        return await _estimate(
          account,
          recipientAddress,
        );
      }
    }
  }

  @override
  Future<Amount> estimateFeeFor(
    Amount amount,
    int feeRate, {
    String recipientAddress = "tz1MXvDCyXSqBqXPNDcsdmVZKfoxL9FTHmp2",
  }) async {
    _hackedCheckTorNodePrefs();
    if (info.cachedBalance.spendable.raw == BigInt.zero) {
      return Amount(
        rawValue: BigInt.zero,
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    }

    final myAddress = (await getCurrentReceivingAddress())!;
    final account = await TezosAPI.getAccount(
      myAddress.value,
    );

    try {
      final fees = await _estimate(account, recipientAddress);

      final fee = Amount(
        rawValue: BigInt.from(fees.reveal + fees.transfer),
        fractionDigits: cryptoCurrency.fractionDigits,
      );

      return fee;
    } catch (e, s) {
      Logging.instance.e(
        "  Error in estimateFeeFor() in tezos_wallet.dart: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Not really used (yet)
  @override
  Future<FeeObject> get fees async {
    const feePerTx = 1;
    return FeeObject(
      numberOfBlocksFast: 10,
      numberOfBlocksAverage: 10,
      numberOfBlocksSlow: 10,
      fast: feePerTx,
      medium: feePerTx,
      slow: feePerTx,
    );
  }

  @override
  Future<bool> pingCheck() async {
    _hackedCheckTorNodePrefs();
    final currentNode = getCurrentNode();
    return await TezosRpcAPI.testNetworkConnection(
      nodeInfo: (
        host: currentNode.host,
        port: currentNode.port,
      ),
    );
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    _hackedCheckTorNodePrefs();
    await refreshMutex.protect(() async {
      if (isRescan) {
        await mainDB.deleteWalletBlockchainData(walletId);
      } else {
        final derivationPath = await _scanPossiblePaths(
          mnemonic: await getMnemonic(),
          passphrase: await getMnemonicPassphrase(),
        );

        await info.updateOtherData(
          newEntries: {
            WalletInfoKeys.tezosDerivationPath: derivationPath.value,
          },
          isar: mainDB.isar,
        );
      }

      final address = await _getAddressFromMnemonic();

      await mainDB.updateOrPutAddresses([address]);

      // ensure we only have a single address
      mainDB.isar.writeTxnSync(() {
        mainDB.isar.addresses
            .where()
            .walletIdEqualTo(walletId)
            .filter()
            .not()
            .derivationPath((q) => q.valueEqualTo(derivationPath))
            .deleteAllSync();
      });

      if (info.cachedReceivingAddress != address.value) {
        await info.updateReceivingAddress(
          newAddress: address.value,
          isar: mainDB.isar,
        );
      }

      await Future.wait([
        updateBalance(),
        updateTransactions(),
        updateChainHeight(),
      ]);
    });
  }

  @override
  Future<void> updateBalance() async {
    try {
      _hackedCheckTorNodePrefs();
      final currentNode = _xtzNode ?? getCurrentNode();
      final balance = await TezosRpcAPI.getBalance(
        nodeInfo: (host: currentNode.host, port: currentNode.port),
        address: (await getCurrentReceivingAddress())!.value,
      );

      final balanceInAmount = Amount(
        rawValue: balance!,
        fractionDigits: cryptoCurrency.fractionDigits,
      );
      final newBalance = Balance(
        total: balanceInAmount,
        spendable: balanceInAmount,
        blockedTotal: Amount(
          rawValue: BigInt.zero,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        pendingSpendable: Amount(
          rawValue: BigInt.zero,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
      );

      await info.updateBalance(newBalance: newBalance, isar: mainDB.isar);
    } catch (e, s) {
      Logging.instance.e(
        "Error getting balance in tezos_wallet.dart: ",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> updateChainHeight() async {
    try {
      _hackedCheckTorNodePrefs();
      final currentNode = _xtzNode ?? getCurrentNode();
      final height = await TezosRpcAPI.getChainHeight(
        nodeInfo: (
          host: currentNode.host,
          port: currentNode.port,
        ),
      );

      await info.updateCachedChainHeight(
        newHeight: height!,
        isar: mainDB.isar,
      );
    } catch (e, s) {
      Logging.instance.e(
        "Error occurred in tezos_wallet.dart while getting"
        " chain height for tezos",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> updateNode() async {
    _xtzNode = NodeService(secureStorageInterface: secureStorageInterface)
            .getPrimaryNodeFor(currency: info.coin) ??
        info.coin.defaultNode;

    await refresh();
  }

  @override
  NodeModel getCurrentNode() {
    return _xtzNode ??=
        NodeService(secureStorageInterface: secureStorageInterface)
                .getPrimaryNodeFor(currency: info.coin) ??
            info.coin.defaultNode;
  }

  @override
  Future<void> updateTransactions() async {
    _hackedCheckTorNodePrefs();
    // TODO: optimize updateTransactions and use V2

    final myAddress = (await getCurrentReceivingAddress())!;
    final txs = await TezosAPI.getTransactions(myAddress.value);

    if (txs.isEmpty) {
      return;
    }

    final List<Tuple2<Transaction, Address>> transactions = [];
    for (final theTx in txs) {
      final TransactionType txType;

      if (myAddress.value == theTx.senderAddress) {
        txType = TransactionType.outgoing;
      } else if (myAddress.value == theTx.receiverAddress) {
        if (myAddress.value == theTx.senderAddress) {
          txType = TransactionType.sentToSelf;
        } else {
          txType = TransactionType.incoming;
        }
      } else {
        txType = TransactionType.unknown;
      }

      final transaction = Transaction(
        walletId: walletId,
        txid: theTx.hash,
        timestamp: theTx.timestamp,
        type: txType,
        subType: TransactionSubType.none,
        amount: theTx.amountInMicroTez,
        amountString: Amount(
          rawValue: BigInt.from(theTx.amountInMicroTez),
          fractionDigits: cryptoCurrency.fractionDigits,
        ).toJsonString(),
        fee: theTx.feeInMicroTez,
        height: theTx.height,
        isCancelled: false,
        isLelantus: false,
        slateId: "",
        otherData: "",
        inputs: [],
        outputs: [],
        nonce: 0,
        numberOfMessages: null,
      );

      final Address theAddress;
      switch (txType) {
        case TransactionType.incoming:
        case TransactionType.sentToSelf:
          theAddress = myAddress;
          break;
        case TransactionType.outgoing:
        case TransactionType.unknown:
          theAddress = Address(
            walletId: walletId,
            value: theTx.receiverAddress,
            publicKey: [],
            derivationIndex: 0,
            derivationPath: null,
            type: AddressType.tezos,
            subType: AddressSubType.unknown,
          );
          break;
      }
      transactions.add(Tuple2(transaction, theAddress));
    }
    await mainDB.addNewTransactionData(transactions, walletId);
  }

  @override
  Future<bool> updateUTXOs() async {
    // do nothing. Not used in tezos
    return false;
  }

  void _hackedCheckTorNodePrefs() {
    final node = nodeService.getPrimaryNodeFor(currency: cryptoCurrency)!;
    final netOption = TorPlainNetworkOption.fromNodeData(
      node.torEnabled,
      node.clearnetEnabled,
    );

    if (prefs.useTor) {
      if (netOption == TorPlainNetworkOption.clear) {
        throw NodeTorMismatchConfigException(
          message: "TOR enabled but node set to clearnet only",
        );
      }
    } else {
      if (netOption == TorPlainNetworkOption.tor) {
        throw NodeTorMismatchConfigException(
          message: "TOR off but node set to TOR only",
        );
      }
    }
  }
}
