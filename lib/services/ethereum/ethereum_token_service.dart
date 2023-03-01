import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/ethereum/eth_token.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/models/token_balance.dart';
import 'package:stackwallet/services/coins/ethereum/ethereum_wallet.dart';
import 'package:stackwallet/services/ethereum/ethereum_api.dart';
import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/mixins/eth_token_cache.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/eth_commons.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:tuple/tuple.dart';
import 'package:web3dart/web3dart.dart' as web3dart;

class EthereumTokenService extends ChangeNotifier with EthTokenCache {
  final EthContractInfo token;
  final EthereumWallet ethWallet;
  final TransactionNotificationTracker tracker;
  final SecureStorageInterface _secureStore;

  late web3dart.EthereumAddress _contractAddress;
  late web3dart.EthPrivateKey _credentials;
  late web3dart.DeployedContract _contract;
  late web3dart.ContractFunction _balanceFunction;
  late web3dart.ContractFunction _sendFunction;
  late String _tokenAbi;
  late web3dart.Web3Client _client;

  static const _gasLimit = 200000;

  EthereumTokenService({
    required this.token,
    required this.ethWallet,
    required SecureStorageInterface secureStore,
    required this.tracker,
  }) : _secureStore = secureStore {
    _contractAddress = web3dart.EthereumAddress.fromHex(token.contractAddress);
    initCache(ethWallet.walletId, token);
  }

  TokenBalance get balance => _balance ??= getCachedBalance();
  TokenBalance? _balance;

  Coin get coin => Coin.ethereum;

  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    final amount = txData['recipientAmt'];
    final decimalAmount =
        Format.satoshisToAmount(amount as int, coin: Coin.ethereum);
    final bigIntAmount =
        amountToBigInt(decimalAmount.toDouble(), token.decimals);

    final sentTx = await _client.sendTransaction(
        _credentials,
        web3dart.Transaction.callContract(
            contract: _contract,
            function: _sendFunction,
            parameters: [
              web3dart.EthereumAddress.fromHex(txData['address'] as String),
              bigIntAmount
            ],
            maxGas: _gasLimit,
            gasPrice: web3dart.EtherAmount.fromUnitAndValue(
                web3dart.EtherUnit.wei, txData['feeInWei'])));

    return sentTx;
  }

  Future<String> get currentReceivingAddress async {
    final address = await _currentReceivingAddress;
    return address?.value ??
        checksumEthereumAddress(_credentials.address.toString());
  }

  Future<Address?> get _currentReceivingAddress => ethWallet.db
      .getAddresses(ethWallet.walletId)
      .filter()
      .typeEqualTo(AddressType.ethereum)
      .subTypeEqualTo(AddressSubType.receiving)
      .sortByDerivationIndexDesc()
      .findFirst();

  Future<int> estimateFeeFor(int satoshiAmount, int feeRate) async {
    final fee = estimateFee(feeRate, _gasLimit, token.decimals);
    return Format.decimalAmountToSatoshis(Decimal.parse(fee.toString()), coin);
  }

  Future<FeeObject> get fees => _feeObject ??= _getFees();
  Future<FeeObject>? _feeObject;

  Future<FeeObject> _getFees() async {
    return await EthereumAPI.getFees();
  }

  Future<void> initialize() async {
    final storedABI =
        await _secureStore.read(key: '${_contractAddress.toString()}_tokenAbi');

    if (storedABI == null) {
      AbiRequestResponse abi =
          await EthereumAPI.fetchTokenAbi(_contractAddress.hex);
      //Fetch token ABI so we can call token functions
      if (abi.message == "OK") {
        _tokenAbi = abi.result;
        //Store abi in secure store
        await _secureStore.write(
            key: '${_contractAddress.hex}_tokenAbi', value: _tokenAbi);
      } else {
        throw Exception('Failed to load token abi');
      }
    } else {
      _tokenAbi = storedABI;
    }

    String? mnemonicString = await ethWallet.mnemonicString;

    //Get private key for given mnemonic
    String privateKey = getPrivateKey(
        mnemonicString!, (await ethWallet.mnemonicPassphrase) ?? "");
    _credentials = web3dart.EthPrivateKey.fromHex(privateKey);

    _contract = web3dart.DeployedContract(
        web3dart.ContractAbi.fromJson(_tokenAbi, token.name), _contractAddress);

    bool hackInBalanceOf = false, hackInTransfer = false;
    try {
      _balanceFunction = _contract.function('balanceOf');
    } catch (_) {
      // function not found so likely a proxy so we need to hack the function in
      hackInBalanceOf = true;
    }

    try {
      _sendFunction = _contract.function('transfer');
    } catch (_) {
      // function not found so likely a proxy so we need to hack the function in
      hackInTransfer = true;
    }

    if (hackInBalanceOf || hackInTransfer) {
      final json = jsonDecode(_tokenAbi) as List;
      if (hackInBalanceOf) {
        json.add({
          "constant": true,
          "inputs": [
            {"name": "", "type": "address"}
          ],
          "name": "balanceOf",
          "outputs": [
            {"name": "", "type": "uint256"}
          ],
          "payable": false,
          "type": "function"
        });
      }
      if (hackInTransfer) {
        json.add({
          "constant": false,
          "inputs": [
            {"name": "_to", "type": "address"},
            {"name": "_value", "type": "uint256"}
          ],
          "name": "transfer",
          "outputs": <dynamic>[],
          "payable": false,
          "type": "function"
        });
      }
      _tokenAbi = jsonEncode(json);
      await _secureStore.write(
          key: '${_contractAddress.hex}_tokenAbi', value: _tokenAbi);

      _contract = web3dart.DeployedContract(
          web3dart.ContractAbi.fromJson(_tokenAbi, token.name),
          _contractAddress);

      _balanceFunction = _contract.function('balanceOf');
      _sendFunction = _contract.function('transfer');
    }

    _client = await getEthClient();

    unawaited(refresh());
  }

  bool get isRefreshing => _refreshLock;

  Future<Map<String, dynamic>> prepareSend(
      {required String address,
      required int satoshiAmount,
      Map<String, dynamic>? args}) async {
    final feeRateType = args?["feeRate"];
    int fee = 0;
    final feeObject = await fees;
    switch (feeRateType) {
      case FeeRateType.fast:
        fee = feeObject.fast;
        break;
      case FeeRateType.average:
        fee = feeObject.medium;
        break;
      case FeeRateType.slow:
        fee = feeObject.slow;
        break;
    }

    final feeEstimate = await estimateFeeFor(satoshiAmount, fee);

    Map<String, dynamic> txData = {
      "fee": feeEstimate,
      "feeInWei": fee,
      "address": address,
      "recipientAmt": satoshiAmount,
    };

    return txData;
  }

  bool _refreshLock = false;

  Future<void> refresh() async {
    if (!_refreshLock) {
      _refreshLock = true;
      try {
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(
            WalletSyncStatus.syncing,
            ethWallet.walletId + token.contractAddress,
            coin,
          ),
        );

        await refreshCachedBalance();
        await _refreshTransactions();
      } catch (e, s) {
        Logging.instance.log(
          "Caught exception in ${token.name} ${ethWallet.walletName} ${ethWallet.walletId} refresh(): $e\n$s",
          level: LogLevel.Warning,
        );
      } finally {
        _refreshLock = false;
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(
            WalletSyncStatus.synced,
            ethWallet.walletId + token.contractAddress,
            coin,
          ),
        );
        notifyListeners();
      }
    }
  }

  Future<void> refreshCachedBalance() async {
    final balanceRequest = await _client.call(
      contract: _contract,
      function: _balanceFunction,
      params: [_credentials.address],
    );

    String _balance = balanceRequest.first.toString();

    final newBalance = TokenBalance(
      contractAddress: token.contractAddress,
      total: int.parse(_balance),
      spendable: int.parse(_balance),
      blockedTotal: 0,
      pendingSpendable: 0,
      decimalPlaces: token.decimals,
    );
    await updateCachedBalance(newBalance);
    notifyListeners();
  }

  Future<List<Transaction>> get transactions => ethWallet.db
      .getTransactions(ethWallet.walletId)
      .filter()
      .otherDataEqualTo(token.contractAddress)
      .sortByTimestampDesc()
      .findAll();

  Future<void> _refreshTransactions() async {
    String addressString = await currentReceivingAddress;

    final response = await EthereumAPI.getTokenTransactions(
      address: addressString,
      contractAddress: token.contractAddress,
    );

    if (response.value == null) {
      throw response.exception ??
          Exception("Failed to fetch token transactions");
    }

    final List<Tuple2<Transaction, Address?>> txnsData = [];

    for (final tx in response.value!) {
      bool isIncoming;
      if (checksumEthereumAddress(tx.from) == addressString) {
        isIncoming = false;
      } else {
        isIncoming = true;
      }

      final txn = Transaction(
        walletId: ethWallet.walletId,
        txid: tx.hash,
        timestamp: tx.timeStamp,
        type: isIncoming ? TransactionType.incoming : TransactionType.outgoing,
        subType: TransactionSubType.ethToken,
        amount: tx.value.toInt(),
        fee: tx.gasUsed * tx.gasPrice.toInt(),
        height: tx.blockNumber,
        isCancelled: false,
        isLelantus: false,
        slateId: null,
        otherData: tx.contractAddress,
        inputs: [],
        outputs: [],
      );

      Address? transactionAddress = await ethWallet.db
          .getAddresses(ethWallet.walletId)
          .filter()
          .valueEqualTo(addressString)
          .findFirst();

      if (transactionAddress == null) {
        if (isIncoming) {
          transactionAddress = Address(
            walletId: ethWallet.walletId,
            value: addressString,
            publicKey: [],
            derivationIndex: 0,
            derivationPath: DerivationPath()..value = "$hdPathEthereum/0",
            type: AddressType.ethereum,
            subType: AddressSubType.receiving,
          );
        } else {
          final myRcvAddr = await currentReceivingAddress;
          final isSentToSelf = myRcvAddr == addressString;

          transactionAddress = Address(
            walletId: ethWallet.walletId,
            value: addressString,
            publicKey: [],
            derivationIndex: isSentToSelf ? 0 : -1,
            derivationPath: isSentToSelf
                ? (DerivationPath()..value = "$hdPathEthereum/0")
                : null,
            type: AddressType.ethereum,
            subType: isSentToSelf
                ? AddressSubType.receiving
                : AddressSubType.nonWallet,
          );
        }
      }

      txnsData.add(Tuple2(txn, transactionAddress));
    }
    await ethWallet.db.addNewTransactionData(txnsData, ethWallet.walletId);

    // quick hack to notify manager to call notifyListeners if
    // transactions changed
    if (txnsData.isNotEmpty) {
      GlobalEventBus.instance.fire(
        UpdatedInBackgroundEvent(
          "${token.name} transactions updated/added for: ${ethWallet.walletId} ${ethWallet.walletName}",
          ethWallet.walletId,
        ),
      );
    }
  }

  bool validateAddress(String address) {
    return isValidEthereumAddress(address);
  }

  Future<NodeModel> getCurrentNode() async {
    return NodeService(secureStorageInterface: _secureStore)
            .getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);
  }

  Future<web3dart.Web3Client> getEthClient() async {
    final node = await getCurrentNode();
    return web3dart.Web3Client(node.host, Client());
  }
}
