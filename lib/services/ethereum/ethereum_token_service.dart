import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/dto/ethereum/eth_token_tx_dto.dart';
import 'package:stackwallet/dto/ethereum/eth_token_tx_extra_dto.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
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
import 'package:stackwallet/utilities/amount.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/eth_commons.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/utilities/extensions/impl/contract_abi.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:tuple/tuple.dart';
import 'package:web3dart/web3dart.dart' as web3dart;

class EthTokenWallet extends ChangeNotifier with EthTokenCache {
  final EthereumWallet ethWallet;
  final TransactionNotificationTracker tracker;
  final SecureStorageInterface _secureStore;

  // late web3dart.EthereumAddress _contractAddress;
  late web3dart.EthPrivateKey _credentials;
  late web3dart.DeployedContract _deployedContract;
  late web3dart.ContractFunction _balanceFunction;
  late web3dart.ContractFunction _sendFunction;
  late web3dart.Web3Client _client;

  static const _gasLimit = 200000;

  EthTokenWallet({
    required EthContract token,
    required this.ethWallet,
    required SecureStorageInterface secureStore,
    required this.tracker,
  })  : _secureStore = secureStore,
        _tokenContract = token {
    // _contractAddress = web3dart.EthereumAddress.fromHex(token.address);
    initCache(ethWallet.walletId, token);
  }

  EthContract get tokenContract => _tokenContract;
  EthContract _tokenContract;

  TokenBalance get balance => _balance ??= getCachedBalance();
  TokenBalance? _balance;

  Coin get coin => Coin.ethereum;

  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    final amount = txData['recipientAmt'];
    final decimalAmount =
        Format.satoshisToAmount(amount as int, coin: Coin.ethereum);
    final bigIntAmount =
        amountToBigInt(decimalAmount.toDouble(), tokenContract.decimals);

    final sentTx = await _client.sendTransaction(
        _credentials,
        web3dart.Transaction.callContract(
            contract: _deployedContract,
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
    return checksumEthereumAddress(
        address?.value ?? _credentials.address.toString());
  }

  Future<Address?> get _currentReceivingAddress => ethWallet.db
      .getAddresses(ethWallet.walletId)
      .filter()
      .typeEqualTo(AddressType.ethereum)
      .subTypeEqualTo(AddressSubType.receiving)
      .sortByDerivationIndexDesc()
      .findFirst();

  Future<int> estimateFeeFor(int satoshiAmount, int feeRate) async {
    final fee = estimateFee(feeRate, _gasLimit, tokenContract.decimals);
    return Format.decimalAmountToSatoshis(Decimal.parse(fee.toString()), coin);
  }

  Future<FeeObject> get fees => _feeObject ??= _getFees();
  Future<FeeObject>? _feeObject;

  Future<FeeObject> _getFees() async {
    return await EthereumAPI.getFees();
  }

  Future<EthContract> _updateTokenABI({
    required EthContract forContract,
    required String usingContractAddress,
  }) async {
    final abiResponse = await EthereumAPI.getTokenAbi(
      name: forContract.name,
      contractAddress: usingContractAddress,
    );
    // Fetch token ABI so we can call token functions
    if (abiResponse.value != null) {
      final updatedToken = forContract.copyWith(abi: abiResponse.value!);
      // Store updated contract
      final id = await MainDB.instance.putEthContract(updatedToken);
      return updatedToken..id = id;
    } else {
      throw abiResponse.exception!;
    }
  }

  Future<void> initialize() async {
    final contractAddress =
        web3dart.EthereumAddress.fromHex(tokenContract.address);

    // if (tokenContract.abi == null) {
    _tokenContract = await _updateTokenABI(
      forContract: tokenContract,
      usingContractAddress: contractAddress.hex,
    );
    // }

    String? mnemonicString = await ethWallet.mnemonicString;

    //Get private key for given mnemonic
    String privateKey = getPrivateKey(
      mnemonicString!,
      (await ethWallet.mnemonicPassphrase) ?? "",
    );
    _credentials = web3dart.EthPrivateKey.fromHex(privateKey);

    _deployedContract = web3dart.DeployedContract(
      ContractAbiExtensions.fromJsonList(
        jsonList: tokenContract.abi!,
        name: tokenContract.name,
      ),
      contractAddress,
    );

    try {
      _balanceFunction = _deployedContract.function('balanceOf');
      _sendFunction = _deployedContract.function('transfer');
    } catch (_) {
      //====================================================================
      final list = List<Map<String, dynamic>>.from(
          jsonDecode(tokenContract.abi!) as List);
      final functionNames = list.map((e) => e["name"] as String);

      if (!functionNames.contains("balanceOf")) {
        list.add(
          {
            "encoding": "0x70a08231",
            "inputs": [
              {"name": "account", "type": "address"}
            ],
            "name": "balanceOf",
            "outputs": [
              {"name": "val_0", "type": "uint256"}
            ],
            "signature": "balanceOf(address)",
            "type": "function"
          },
        );
      }

      if (!functionNames.contains("transfer")) {
        list.add(
          {
            "encoding": "0xa9059cbb",
            "inputs": [
              {"name": "dst", "type": "address"},
              {"name": "rawAmount", "type": "uint256"}
            ],
            "name": "transfer",
            "outputs": [
              {"name": "val_0", "type": "bool"}
            ],
            "signature": "transfer(address,uint256)",
            "type": "function"
          },
        );
      }
      //--------------------------------------------------------------------
      //====================================================================

      // function not found so likely a proxy so we need to fetch the impl
      //====================================================================
      final updatedToken = tokenContract.copyWith(abi: jsonEncode(list));
      // Store updated contract
      final id = await MainDB.instance.putEthContract(updatedToken);
      _tokenContract = updatedToken..id = id;
      //--------------------------------------------------------------------
      // final contractAddressResponse =
      //     await EthereumAPI.getProxyTokenImplementation(contractAddress.hex);
      //
      // if (contractAddressResponse.value != null) {
      //   _tokenContract = await _updateTokenABI(
      //     forContract: tokenContract,
      //     usingContractAddress: contractAddressResponse.value!,
      //   );
      // } else {
      //   throw contractAddressResponse.exception!;
      // }
      //====================================================================
    }

    _deployedContract = web3dart.DeployedContract(
      ContractAbiExtensions.fromJsonList(
        jsonList: tokenContract.abi!,
        name: tokenContract.name,
      ),
      contractAddress,
    );

    _balanceFunction = _deployedContract.function('balanceOf');
    _sendFunction = _deployedContract.function('transfer');

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
            ethWallet.walletId + tokenContract.address,
            coin,
          ),
        );

        await refreshCachedBalance();
        await _refreshTransactions();
      } catch (e, s) {
        Logging.instance.log(
          "Caught exception in ${tokenContract.name} ${ethWallet.walletName} ${ethWallet.walletId} refresh(): $e\n$s",
          level: LogLevel.Warning,
        );
      } finally {
        _refreshLock = false;
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(
            WalletSyncStatus.synced,
            ethWallet.walletId + tokenContract.address,
            coin,
          ),
        );
        notifyListeners();
      }
    }
  }

  Future<void> refreshCachedBalance() async {
    final balanceRequest = await _client.call(
      contract: _deployedContract,
      function: _balanceFunction,
      params: [_credentials.address],
    );

    String _balance = balanceRequest.first.toString();

    final newBalance = TokenBalance(
      contractAddress: tokenContract.address,
      total: int.parse(_balance),
      spendable: int.parse(_balance),
      blockedTotal: 0,
      pendingSpendable: 0,
      decimalPlaces: tokenContract.decimals,
    );
    await updateCachedBalance(newBalance);
    notifyListeners();
  }

  Future<List<Transaction>> get transactions => ethWallet.db
      .getTransactions(ethWallet.walletId)
      .filter()
      .otherDataEqualTo(tokenContract.address)
      .sortByTimestampDesc()
      .findAll();

  String _addressFromTopic(String topic) =>
      checksumEthereumAddress("0x${topic.substring(topic.length - 40)}");

  Future<void> _refreshTransactions() async {
    String addressString =
        checksumEthereumAddress(await currentReceivingAddress);

    final response = await EthereumAPI.getTokenTransactions(
      address: addressString,
      tokenContractAddress: tokenContract.address,
    );

    if (response.value == null) {
      throw response.exception ??
          Exception("Failed to fetch token transaction data");
    }

    // no need to continue if no transactions found
    if (response.value!.isEmpty) {
      return;
    }

    final response2 = await EthereumAPI.getEthTokenTransactionsByTxids(
      response.value!.map((e) => e.transactionHash).toList(),
    );

    if (response2.value == null) {
      throw response2.exception ??
          Exception("Failed to fetch token transactions");
    }
    final List<Tuple2<EthTokenTxDto, EthTokenTxExtraDTO>> data = [];
    for (final tokenDto in response.value!) {
      data.add(
        Tuple2(
          tokenDto,
          response2.value!.firstWhere(
            (e) => e.hash == tokenDto.transactionHash,
          ),
        ),
      );
    }

    final List<Tuple2<Transaction, Address?>> txnsData = [];

    for (final tuple in data) {
      // ignore all non Transfer events (for now)
      if (tuple.item1.topics[0] == kTransferEventSignature) {
        final Amount amount;
        String fromAddress, toAddress;
        amount = Amount(
          rawValue: tuple.item1.data.toBigIntFromHex,
          fractionDigits: tokenContract.decimals,
        );

        fromAddress = _addressFromTopic(
          tuple.item1.topics[1],
        );
        toAddress = _addressFromTopic(
          tuple.item1.topics[2],
        );

        bool isIncoming;
        bool isSentToSelf = false;
        if (fromAddress == addressString) {
          isIncoming = false;
          if (toAddress == addressString) {
            isSentToSelf = true;
          }
        } else if (toAddress == addressString) {
          isIncoming = true;
        } else {
          throw Exception("Unknown token transaction found for "
              "${ethWallet.walletName} ${ethWallet.walletId}: "
              "${tuple.item1.toString()}");
        }

        final txn = Transaction(
          walletId: ethWallet.walletId,
          txid: tuple.item1.transactionHash,
          timestamp: tuple.item2.timestamp,
          type:
              isIncoming ? TransactionType.incoming : TransactionType.outgoing,
          subType: TransactionSubType.ethToken,
          amount: amount.raw.toInt(),
          amountString: amount.toJsonString(),
          fee: (tuple.item2.gasUsed.raw * tuple.item2.gasPrice.raw).toInt(),
          height: tuple.item1.blockNumber,
          isCancelled: false,
          isLelantus: false,
          slateId: null,
          otherData: tuple.item1.address,
          inputs: [],
          outputs: [],
        );

        Address? transactionAddress = await ethWallet.db
            .getAddresses(ethWallet.walletId)
            .filter()
            .valueEqualTo(toAddress)
            .findFirst();

        transactionAddress ??= Address(
          walletId: ethWallet.walletId,
          value: toAddress,
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

        txnsData.add(Tuple2(txn, transactionAddress));
      }
    }
    await ethWallet.db.addNewTransactionData(txnsData, ethWallet.walletId);

    // quick hack to notify manager to call notifyListeners if
    // transactions changed
    if (txnsData.isNotEmpty) {
      GlobalEventBus.instance.fire(
        UpdatedInBackgroundEvent(
          "${tokenContract.name} transactions updated/added for: ${ethWallet.walletId} ${ethWallet.walletName}",
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
