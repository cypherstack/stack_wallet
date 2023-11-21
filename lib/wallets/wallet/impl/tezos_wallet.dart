import 'package:isar/isar.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/extensions/impl/string.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/wallets/api/tezos/tezos_api.dart';
import 'package:stackwallet/wallets/api/tezos/tezos_rpc_api.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/tezos.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_wallet.dart';
import 'package:tezart/tezart.dart' as tezart;
import 'package:tuple/tuple.dart';

// const kDefaultTransactionStorageLimit = 496;
const kDefaultTransactionGasLimit = 10600;

// const kDefaultKeyRevealFee = 1270;
// const kDefaultKeyRevealStorageLimit = 0;
// const kDefaultKeyRevealGasLimit = 1100;

class TezosWallet extends Bip39Wallet {
  TezosWallet(CryptoCurrencyNetwork network) : super(Tezos(network));

  NodeModel? _xtzNode;

  Future<tezart.Keystore> _getKeyStore() async {
    final mnemonic = await getMnemonic();
    final passphrase = await getMnemonicPassphrase();
    return tezart.Keystore.fromMnemonic(mnemonic, password: passphrase);
  }

  Future<Address> _getAddressFromMnemonic() async {
    final keyStore = await _getKeyStore();
    return Address(
      walletId: walletId,
      value: keyStore.address,
      publicKey: keyStore.publicKey.toUint8ListFromBase58CheckEncoded,
      derivationIndex: 0,
      derivationPath: null,
      type: info.coin.primaryAddressType,
      subType: AddressSubType.receiving,
    );
  }

  Future<tezart.OperationsList> _buildSendTransaction({
    required Amount amount,
    required String address,
    int? customGasLimit,
    Amount? customFee,
  }) async {
    try {
      final sourceKeyStore = await _getKeyStore();
      final tezartClient = tezart.TezartClient(
        (_xtzNode ?? getCurrentNode()).host,
      );

      final opList = await tezartClient.transferOperation(
        source: sourceKeyStore,
        destination: address,
        amount: amount.raw.toInt(),
        customGasLimit: customGasLimit,
        customFee: customFee?.raw.toInt(),
      );

      final counter = (await TezosAPI.getCounter(
            (await getCurrentReceivingAddress())!.value,
          )) +
          1;

      for (final op in opList.operations) {
        if (op is tezart.RevealOperation) {
          // op.storageLimit = kDefaultKeyRevealStorageLimit;
          // op.gasLimit = kDefaultKeyRevealGasLimit;
          // op.fee = kDefaultKeyRevealFee;
          op.counter = counter;
        } else if (op is tezart.TransactionOperation) {
          op.counter = counter + 1;
          // op.storageLimit = kDefaultTransactionStorageLimit;
          // op.gasLimit = kDefaultTransactionGasLimit;
        }
      }

      return opList;
    } catch (e, s) {
      Logging.instance.log(
        "Error in estimateFeeFor() in tezos_wallet.dart: $e\n$s}",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  // ===========================================================================

  @override
  Future<void> init() async {
    final _address = await getCurrentReceivingAddress();
    if (_address == null) {
      final address = await _getAddressFromMnemonic();

      await mainDB.updateOrPutAddresses([address]);
    }

    await super.init();
  }

  @override
  FilterOperation? get changeAddressFilterOperation =>
      throw UnimplementedError("Not used for $runtimeType");

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    if (txData.recipients == null || txData.recipients!.length != 1) {
      throw Exception("$runtimeType prepareSend requires 1 recipient");
    }

    Amount sendAmount = txData.amount!;

    if (sendAmount > info.cachedBalance.spendable) {
      throw Exception("Insufficient available balance");
    }

    final bool isSendAll = sendAmount == info.cachedBalance.spendable;

    Amount fee = await estimateFeeFor(sendAmount, -1);

    int? customGasLimit;

    if (isSendAll) {
      //Fee guides for emptying a tz account
      // https://github.com/TezTech/eztz/blob/master/PROTO_004_FEES.md
      customGasLimit = kDefaultTransactionGasLimit + 320;
      fee = Amount(
        rawValue: BigInt.from(fee.raw.toInt() + 32),
        fractionDigits: cryptoCurrency.fractionDigits,
      );
      sendAmount = sendAmount - fee;
    }

    final opList = await _buildSendTransaction(
      amount: sendAmount,
      address: txData.recipients!.first.address,
      customFee: fee,
      customGasLimit: customGasLimit,
    );

    return txData.copyWith(
      recipients: [
        (
          amount: sendAmount,
          address: txData.recipients!.first.address,
        )
      ],
      fee: fee,
      tezosOperationsList: opList,
    );
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    await txData.tezosOperationsList!.executeAndMonitor();
    return txData.copyWith(
      txid: txData.tezosOperationsList!.result.id,
    );
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    if (amount.raw == BigInt.zero) {
      amount = Amount(
        rawValue: BigInt.one,
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    }

    final myAddressForSimulation = (await getCurrentReceivingAddress())!.value;

    try {
      final opList = await _buildSendTransaction(
        amount: amount,
        address: myAddressForSimulation,
      );

      await opList.computeLimits();
      await opList.computeFees();
      await opList.simulate();

      final fee = Amount(
        rawValue: opList.operations
            .map(
              (e) => BigInt.from(e.fee),
            )
            .fold(
              BigInt.zero,
              (p, e) => p + e,
            ),
        fractionDigits: cryptoCurrency.fractionDigits,
      );

      return fee;
    } catch (e, s) {
      Logging.instance.log(
        "Error in estimateFeeFor() in tezos_wallet.dart: $e\n$s}",
        level: LogLevel.Error,
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
    await refreshMutex.protect(() async {
      if (isRescan) {
        await mainDB.deleteWalletBlockchainData(walletId);
      }

      final address = await _getAddressFromMnemonic();

      await mainDB.updateOrPutAddresses([address]);

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
      Logging.instance.log(
        "Error getting balance in tezos_wallet.dart: $e\n$s}",
        level: LogLevel.Error,
      );
    }
  }

  @override
  Future<void> updateChainHeight() async {
    try {
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
      Logging.instance.log(
        "Error occurred in tezos_wallet.dart while getting"
        " chain height for tezos: $e\n$s}",
        level: LogLevel.Error,
      );
    }
  }

  @override
  Future<void> updateNode() async {
    _xtzNode = NodeService(secureStorageInterface: secureStorageInterface)
            .getPrimaryNodeFor(coin: info.coin) ??
        DefaultNodes.getNodeFor(info.coin);

    await refresh();
  }

  @override
  NodeModel getCurrentNode() {
    return _xtzNode ??
        NodeService(secureStorageInterface: secureStorageInterface)
            .getPrimaryNodeFor(coin: info.coin) ??
        DefaultNodes.getNodeFor(info.coin);
  }

  @override
  Future<void> updateTransactions() async {
    // TODO: optimize updateTransactions

    final myAddress = (await getCurrentReceivingAddress())!;
    final txs = await TezosAPI.getTransactions(myAddress.value);

    if (txs.isEmpty) {
      return;
    }

    List<Tuple2<Transaction, Address>> transactions = [];
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

      var transaction = Transaction(
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
            type: AddressType.unknown,
            subType: AddressSubType.unknown,
          );
          break;
      }
      transactions.add(Tuple2(transaction, theAddress));
    }
    await mainDB.addNewTransactionData(transactions, walletId);
  }

  @override
  Future<void> updateUTXOs() async {
    // do nothing. Not used in tezos
  }
}
