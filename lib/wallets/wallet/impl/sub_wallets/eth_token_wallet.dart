import 'dart:convert';

import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'package:isar_community/isar.dart';
import 'package:web3dart/web3dart.dart' as web3dart;

import '../../../../dto/ethereum/eth_token_tx_dto.dart';
import '../../../../models/balance.dart';
import '../../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../../models/isar/models/ethereum/eth_contract.dart';
import '../../../../models/paymint/fee_object_model.dart';
import '../../../../services/ethereum/ethereum_api.dart';
import '../../../../utilities/amount/amount.dart';
import '../../../../utilities/eth_commons.dart';
import '../../../../utilities/extensions/extensions.dart';
import '../../../../utilities/logger.dart';
import '../../../isar/models/token_wallet_info.dart';
import '../../../models/tx_data.dart';
import '../../wallet.dart';
import '../ethereum_wallet.dart';

class EthTokenWallet extends Wallet {
  @override
  int get isarTransactionVersion => 2;

  EthTokenWallet(this.ethWallet, this._tokenContract)
    : super(ethWallet.cryptoCurrency);

  final EthereumWallet ethWallet;

  EthContract get tokenContract => _tokenContract;
  EthContract _tokenContract;

  late web3dart.DeployedContract _deployedContract;
  late web3dart.ContractFunction _sendFunction;

  // ===========================================================================

  // ===========================================================================

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
      final id = await mainDB.putEthContract(updatedToken);
      return updatedToken..id = id;
    } else {
      throw abiResponse.exception!;
    }
  }

  String _addressFromTopic(String topic) =>
      checksumEthereumAddress("0x${topic.substring(topic.length - 40)}");

  TxData _prepareTempTx(TxData txData, String myAddress) {
    final otherData = {
      "nonce": txData.nonce!,
      "isCancelled": false,
      "overrideFee": txData.fee!.toJsonString(),
      "contractAddress": tokenContract.address,
    };

    final amount = txData.recipients!.first.amount;
    final addressTo = txData.recipients!.first.address;

    // hack eth tx data into inputs and outputs
    final List<OutputV2> outputs = [];
    final List<InputV2> inputs = [];

    final output = OutputV2.isarCantDoRequiredInDefaultConstructor(
      scriptPubKeyHex: "00",
      valueStringSats: amount.raw.toString(),
      addresses: [addressTo],
      walletOwns: addressTo == myAddress,
    );
    final input = InputV2.isarCantDoRequiredInDefaultConstructor(
      scriptSigHex: null,
      scriptSigAsm: null,
      sequence: null,
      outpoint: null,
      addresses: [myAddress],
      valueStringSats: amount.raw.toString(),
      witness: null,
      innerRedeemScriptAsm: null,
      coinbase: null,
      walletOwns: true,
    );

    outputs.add(output);
    inputs.add(input);

    final tempTx = TransactionV2(
      walletId: walletId,
      blockHash: null,
      hash: txData.txHash!,
      txid: txData.txid!,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      height: null,
      inputs: List.unmodifiable(inputs),
      outputs: List.unmodifiable(outputs),
      version: -1,
      type:
          addressTo == myAddress
              ? TransactionType.sentToSelf
              : TransactionType.outgoing,
      subType: TransactionSubType.ethToken,
      otherData: jsonEncode(otherData),
    );

    return txData.copyWith(tempTx: tempTx);
  }

  // ===========================================================================

  @override
  FilterOperation? get changeAddressFilterOperation =>
      ethWallet.changeAddressFilterOperation;

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      ethWallet.receivingAddressFilterOperation;

  @override
  Future<void> init() async {
    try {
      await super.init();

      final contractAddress = web3dart.EthereumAddress.fromHex(
        tokenContract.address,
      );

      // first try to update the abi regardless just in case something has changed
      try {
        _tokenContract = await _updateTokenABI(
          forContract: tokenContract,
          usingContractAddress: contractAddress.hex,
        );
      } catch (e, s) {
        Logging.instance.w(
          "$runtimeType _updateTokenABI(): ",
          error: e,
          stackTrace: s,
        );
      }

      try {
        // try parse abi and extract transfer function
        _deployedContract = web3dart.DeployedContract(
          ContractAbiExtensions.fromJsonList(
            jsonList: tokenContract.abi!,
            name: tokenContract.name,
          ),
          contractAddress,
        );
        _sendFunction = _deployedContract.function('transfer');
        // success
        return;
      } catch (_) {
        // continue
      }

      // Some failure, try for proxy contract
      final contractAddressResponse =
          await EthereumAPI.getProxyTokenImplementationAddress(
            contractAddress.hex,
          );

      if (contractAddressResponse.value != null) {
        _tokenContract = await _updateTokenABI(
          forContract: tokenContract,
          usingContractAddress: contractAddressResponse.value!,
        );
      } else {
        throw contractAddressResponse.exception!;
      }

      _deployedContract = web3dart.DeployedContract(
        ContractAbiExtensions.fromJsonList(
          jsonList: tokenContract.abi!,
          name: tokenContract.name,
        ),
        contractAddress,
      );

      _sendFunction = _deployedContract.function('transfer');
    } catch (e, s) {
      Logging.instance.w(
        "$runtimeType wallet failed init(): ",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    final amount = txData.recipients!.first.amount;
    final address = txData.recipients!.first.address;

    final myWeb3Address = await ethWallet.getMyWeb3Address();

    final prep = await ethWallet.internalSharedPrepareSend(
      txData: txData,
      myWeb3Address: myWeb3Address,
    );

    // double check balance after internalSharedPrepareSend call to ensure
    // balance is up to date
    final info =
        await mainDB.isar.tokenWalletInfo
            .where()
            .walletIdTokenAddressEqualTo(walletId, tokenContract.address)
            .findFirst();
    final availableBalance =
        info?.getCachedBalance().spendable ??
        Amount.zeroWith(fractionDigits: tokenContract.decimals);
    if (amount > availableBalance) {
      throw Exception("Insufficient balance");
    }

    final tx = web3dart.Transaction.callContract(
      contract: _deployedContract,
      function: _sendFunction,
      parameters: [web3dart.EthereumAddress.fromHex(address), amount.raw],
      maxGas: txData.ethEIP1559Fee?.gasLimit ?? kEthereumTokenMinGasLimit,
      nonce: prep.nonce,
      maxFeePerGas: web3dart.EtherAmount.fromBigInt(
        web3dart.EtherUnit.wei,
        prep.maxBaseFee,
      ),
      maxPriorityFeePerGas: web3dart.EtherAmount.fromBigInt(
        web3dart.EtherUnit.wei,
        prep.priorityFee,
      ),
    );

    final feeEstimate = await estimateFeeFor(
      Amount.zero,
      prep.maxBaseFee + prep.priorityFee,
    );
    return txData.copyWith(
      fee: feeEstimate,
      web3dartTransaction: tx,
      chainId: prep.chainId,
      nonce: tx.nonce,
    );
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      return await ethWallet.confirmSend(
        txData: txData,
        prepareTempTx: _prepareTempTx,
      );
    } catch (e) {
      // rethrow to pass error in alert
      rethrow;
    }
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
    return ethWallet.estimateEthFee(
      feeRate,
      kEthereumTokenMinGasLimit,
      cryptoCurrency.fractionDigits,
    );
  }

  @override
  Future<EthFeeObject> get fees => EthereumAPI.getFees();

  @override
  Future<bool> pingCheck() async {
    return await ethWallet.pingCheck();
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    try {
      throw Exception();
    } catch (_, s) {
      Logging.instance.w(
        "Eth token wallet recover called. This should not happen.",
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> updateBalance() async {
    try {
      final info =
          await mainDB.isar.tokenWalletInfo
              .where()
              .walletIdTokenAddressEqualTo(walletId, tokenContract.address)
              .findFirst();
      final response = await EthereumAPI.getWalletTokenBalance(
        address: (await getCurrentReceivingAddress())!.value,
        contractAddress: tokenContract.address,
      );

      if (response.value != null && info != null) {
        await info.updateCachedBalance(
          Balance(
            total: response.value!,
            spendable: response.value!,
            blockedTotal: Amount(
              rawValue: BigInt.zero,
              fractionDigits: tokenContract.decimals,
            ),
            pendingSpendable: Amount(
              rawValue: BigInt.zero,
              fractionDigits: tokenContract.decimals,
            ),
          ),
          isar: mainDB.isar,
        );
      } else {
        Logging.instance.w(
          "CachedEthTokenBalance.fetchAndUpdateCachedBalance failed: ${response.exception}",
        );
      }
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType wallet failed to update balance: ",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> updateChainHeight() async {
    await ethWallet.updateChainHeight();
  }

  @override
  Future<void> updateTransactions() async {
    try {
      final String addressString = checksumEthereumAddress(
        (await getCurrentReceivingAddress())!.value,
      );

      final response = await EthereumAPI.getTokenTransactions(
        address: addressString,
        tokenContractAddress: tokenContract.address,
      );

      if (response.value == null) {
        if (response.exception != null &&
            response.exception!.message.contains(
              "response is empty but status code is 200",
            )) {
          Logging.instance.d(
            "No ${tokenContract.name} transfers found for $addressString",
          );
          return;
        }
        throw response.exception ??
            Exception("Failed to fetch token transaction data");
      }

      // no need to continue if no transactions found
      if (response.value!.isEmpty) {
        return;
      }

      web3dart.Web3Client? client;
      final List<EthTokenTxDto> allTxs = [];
      for (final dto in response.value!) {
        if (dto.nonce == null) {
          client ??= ethWallet.getEthClient();
          final txInfo = await client.getTransactionByHash(dto.transactionHash);
          if (txInfo == null) {
            // Something strange is happening
            Logging.instance.w(
              "Could not find token transaction via RPC that was found use "
              "TrueBlocks API.\nOffending tx: $dto",
            );
          } else {
            final updated = dto.copyWith(
              nonce: txInfo.nonce,
              gasPrice: txInfo.gasPrice.getInWei,
              gasUsed: txInfo.gas,
            );
            allTxs.add(updated);
          }
        } else {
          allTxs.add(dto);
        }
      }

      final List<TransactionV2> txns = [];

      for (final tx in allTxs) {
        // ignore all non Transfer events (for now)
        if (tx.topics[0] == kTransferEventSignature) {
          final amount = Amount(
            rawValue: tx.data.toBigIntFromHex,
            fractionDigits: tokenContract.decimals,
          );

          if (amount.raw == BigInt.zero) {
            // probably don't need to show this
            continue;
          }

          final txFee = Amount(
            rawValue: BigInt.from(tx.gasUsed!) * tx.gasPrice!,
            fractionDigits: cryptoCurrency.fractionDigits,
          );
          final addressFrom = _addressFromTopic(tx.topics[1]);
          final addressTo = _addressFromTopic(tx.topics[2]);

          final TransactionType txType;
          if (addressTo == addressString) {
            if (addressFrom == addressTo) {
              txType = TransactionType.sentToSelf;
            } else {
              txType = TransactionType.incoming;
            }
          } else if (addressFrom == addressString) {
            txType = TransactionType.outgoing;
          } else {
            // ignore for now I guess since anything here is not reflected in
            // balance anyways
            continue;

            // throw Exception("Unknown token transaction found for "
            //     "${ethWallet.walletName} ${ethWallet.walletId}: "
            //     "${tuple.item1.toString()}");
          }

          final otherData = {
            "nonce": tx.nonce,
            "isCancelled": false,
            "overrideFee": txFee.toJsonString(),
            "contractAddress": tx.address,
          };

          // hack eth tx data into inputs and outputs
          final List<OutputV2> outputs = [];
          final List<InputV2> inputs = [];

          final output = OutputV2.isarCantDoRequiredInDefaultConstructor(
            scriptPubKeyHex: "00",
            valueStringSats: amount.raw.toString(),
            addresses: [addressTo],
            walletOwns: addressTo == addressString,
          );
          final input = InputV2.isarCantDoRequiredInDefaultConstructor(
            scriptSigHex: null,
            scriptSigAsm: null,
            sequence: null,
            outpoint: null,
            addresses: [addressFrom],
            valueStringSats: amount.raw.toString(),
            witness: null,
            innerRedeemScriptAsm: null,
            coinbase: null,
            walletOwns: addressFrom == addressString,
          );

          outputs.add(output);
          inputs.add(input);

          final txn = TransactionV2(
            walletId: walletId,
            blockHash: tx.blockHash,
            hash: tx.transactionHash,
            txid: tx.transactionHash,
            timestamp: tx.timestamp,
            height: tx.blockNumber,
            inputs: List.unmodifiable(inputs),
            outputs: List.unmodifiable(outputs),
            version: -1,
            type: txType,
            subType: TransactionSubType.ethToken,
            otherData: jsonEncode(otherData),
          );

          txns.add(txn);
        }
      }
      await mainDB.updateOrPutTransactionV2s(txns);
    } catch (e, s) {
      Logging.instance.w(
        "$runtimeType wallet failed to update transactions: ",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> updateNode() async {
    await ethWallet.updateNode();
  }

  @override
  Future<bool> updateUTXOs() async {
    return await ethWallet.updateUTXOs();
  }

  @override
  FilterOperation? get transactionFilterOperation => FilterGroup.and([
    FilterCondition.equalTo(
      property: r"contractAddress",
      value: tokenContract.address,
    ),
    const FilterCondition.equalTo(
      property: r"subType",
      value: TransactionSubType.ethToken,
    ),
  ]);

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    await ethWallet.checkSaveInitialReceivingAddress();
  }
}
