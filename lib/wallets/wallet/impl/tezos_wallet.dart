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
import 'package:stackwallet/wallets/api/tezos/tezos_transaction.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/tezos.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_wallet.dart';
import 'package:tezart/tezart.dart' as tezart;
import 'package:tuple/tuple.dart';

const int GAS_LIMIT = 10200;

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

    final sourceKeyStore = await _getKeyStore();
    final tezartClient = tezart.TezartClient(
      (_xtzNode ?? getCurrentNode()).host,
    );

    final opList = await tezartClient.transferOperation(
      source: sourceKeyStore,
      destination: txData.recipients!.first.address,
      amount: sendAmount.raw.toInt(),
    );

    await opList.computeFees();

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

    if (isSendAll) {
      sendAmount = sendAmount - fee;
    }

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
    // TODO: implement confirmSend
    throw UnimplementedError();
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    throw UnimplementedError();
    // final ADDRESS_REPLACEME = (await getCurrentReceivingAddress())!.value;
    //
    // try {
    //   final sourceKeyStore = await _getKeyStore();
    //   final tezartClient = tezart.TezartClient(
    //     (_xtzNode ?? getCurrentNode()).host,
    //   );
    //
    //   final opList = await tezartClient.transferOperation(
    //     source: sourceKeyStore,
    //     destination: ADDRESS_REPLACEME,
    //     amount: amount.raw.toInt(),
    //   );
    //
    //   await opList.run();
    //   await opList.estimate();
    //
    //   final fee = Amount(
    //     rawValue: opList.operations
    //         .map(
    //           (e) => BigInt.from(e.fee),
    //         )
    //         .fold(
    //           BigInt.zero,
    //           (p, e) => p + e,
    //         ),
    //     fractionDigits: cryptoCurrency.fractionDigits,
    //   );
    //
    //   return fee;
    // } catch (e, s) {
    //   Logging.instance.log(
    //     "Error in estimateFeeFor() in tezos_wallet.dart: $e\n$s}",
    //     level: LogLevel.Error,
    //   );
    //   rethrow;
    // }
  }

  @override
  Future<FeeObject> get fees async {
    final feePerTx = (await estimateFeeFor(
            Amount(
              rawValue: BigInt.one,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            42))
        .raw
        .toInt();
    Logging.instance.log("feePerTx:$feePerTx", level: LogLevel.Info);
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
    List<TezosTransaction>? txs =
        await TezosAPI.getTransactions(myAddress.value);
    Logging.instance.log("Transactions: $txs", level: LogLevel.Info);
    if (txs == null || txs.isEmpty) {
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
          rawValue: BigInt.parse(theTx.amountInMicroTez.toString()),
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
