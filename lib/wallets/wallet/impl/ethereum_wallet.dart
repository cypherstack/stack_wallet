import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'package:http/http.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/input_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/output_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/ethereum/ethereum_api.dart';
import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/eth_commons.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/ethereum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/private_key_interface.dart';
import 'package:web3dart/web3dart.dart' as web3;

// Eth can not use tor with web3dart

class EthereumWallet extends Bip39Wallet with PrivateKeyInterface {
  EthereumWallet(CryptoCurrencyNetwork network) : super(Ethereum(network));

  Timer? timer;
  web3.EthPrivateKey? _credentials;

  Future<void> updateTokenContracts(List<String> contractAddresses) async {
    await info.updateContractAddresses(
      newContractAddresses: contractAddresses.toSet(),
      isar: mainDB.isar,
    );

    GlobalEventBus.instance.fire(
      UpdatedInBackgroundEvent(
        "$contractAddresses updated/added for: $walletId ${info.name}",
        walletId,
      ),
    );
  }

  web3.Web3Client getEthClient() {
    final node = getCurrentNode();

    // Eth can not use tor with web3dart as Client does not support proxies
    final client = Client();

    return web3.Web3Client(node.host, client);
  }

  Amount estimateEthFee(int feeRate, int gasLimit, int decimals) {
    final gweiAmount = feeRate.toDecimal() / (Decimal.ten.pow(9).toDecimal());
    final fee = gasLimit.toDecimal() *
        gweiAmount.toDecimal(
          scaleOnInfinitePrecision: cryptoCurrency.fractionDigits,
        );

    //Convert gwei to ETH
    final feeInWei = fee * Decimal.ten.pow(9).toDecimal();
    final ethAmount = feeInWei / Decimal.ten.pow(decimals).toDecimal();
    return Amount.fromDecimal(
      ethAmount.toDecimal(
        scaleOnInfinitePrecision: cryptoCurrency.fractionDigits,
      ),
      fractionDigits: decimals,
    );
  }

  // ==================== Private ==============================================

  Future<void> _initCredentials() async {
    final mnemonic = await getMnemonic();
    final mnemonicPassphrase = await getMnemonicPassphrase();
    final privateKey = getPrivateKey(mnemonic, mnemonicPassphrase);
    _credentials = web3.EthPrivateKey.fromHex(privateKey);
  }

  // ==================== Overrides ============================================

  @override
  int get isarTransactionVersion => 2;

  @override
  FilterOperation? get transactionFilterOperation => FilterGroup.not(
        const FilterCondition.equalTo(
          property: r"subType",
          value: TransactionSubType.ethToken,
        ),
      );

  @override
  FilterOperation? get changeAddressFilterOperation =>
      FilterGroup.and(standardChangeAddressFilters);

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    final address = await getCurrentReceivingAddress();
    if (address == null) {
      if (_credentials == null) {
        await _initCredentials();
      }

      final address = Address(
        walletId: walletId,
        value: _credentials!.address.hexEip55,
        publicKey: [],
        // maybe store address bytes here? seems a waste of space though
        derivationIndex: 0,
        derivationPath: DerivationPath()..value = "$hdPathEthereum/0",
        type: AddressType.ethereum,
        subType: AddressSubType.receiving,
      );

      await mainDB.updateOrPutAddresses([address]);
    }
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    return estimateEthFee(
      feeRate,
      (cryptoCurrency as Ethereum).gasLimit,
      cryptoCurrency.fractionDigits,
    );
  }

  @override
  Future<FeeObject> get fees => EthereumAPI.getFees();

  @override
  Future<bool> pingCheck() async {
    web3.Web3Client client = getEthClient();
    try {
      await client.getBlockNumber();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> updateBalance() async {
    try {
      final client = getEthClient();

      final addressHex = (await getCurrentReceivingAddress())!.value;
      final address = web3.EthereumAddress.fromHex(addressHex);
      web3.EtherAmount ethBalance = await client.getBalance(address);
      final balance = Balance(
        total: Amount(
          rawValue: ethBalance.getInWei,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        spendable: Amount(
          rawValue: ethBalance.getInWei,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        blockedTotal: Amount.zeroWith(
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        pendingSpendable: Amount.zeroWith(
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
      );
      await info.updateBalance(
        newBalance: balance,
        isar: mainDB.isar,
      );
    } catch (e, s) {
      Logging.instance.log(
        "$runtimeType wallet failed to update balance: $e\n$s",
        level: LogLevel.Warning,
      );
    }
  }

  @override
  Future<void> updateChainHeight() async {
    try {
      final client = getEthClient();
      final height = await client.getBlockNumber();

      await info.updateCachedChainHeight(
        newHeight: height,
        isar: mainDB.isar,
      );
    } catch (e, s) {
      Logging.instance.log(
        "$runtimeType Exception caught in chainHeight: $e\n$s",
        level: LogLevel.Warning,
      );
    }
  }

  @override
  Future<void> updateNode() async {
    // do nothing
  }

  @override
  Future<void> updateTransactions({bool isRescan = false}) async {
    final thisAddress = (await getCurrentReceivingAddress())!.value;

    int firstBlock = 0;

    if (!isRescan) {
      firstBlock = await mainDB.isar.transactionV2s
              .where()
              .walletIdEqualTo(walletId)
              .heightProperty()
              .max() ??
          0;

      if (firstBlock > 10) {
        // add some buffer
        firstBlock -= 10;
      }
    }

    final response = await EthereumAPI.getEthTransactions(
      address: thisAddress,
      firstBlock: isRescan ? 0 : firstBlock,
      includeTokens: true,
    );

    if (response.value == null) {
      Logging.instance.log(
        "Failed to refresh transactions for ${cryptoCurrency.coin.prettyName} ${info.name} "
        "$walletId: ${response.exception}",
        level: LogLevel.Warning,
      );
      return;
    }

    if (response.value!.isEmpty) {
      // no new transactions found
      return;
    }

    final txsResponse =
        await EthereumAPI.getEthTransactionNonces(response.value!);

    if (txsResponse.value != null) {
      final allTxs = txsResponse.value!;
      final List<TransactionV2> txns = [];
      for (final tuple in allTxs) {
        final element = tuple.item1;

        if (element.hasToken && !element.isError) {
          continue;
        }

        //Calculate fees (GasLimit * gasPrice)
        // int txFee = element.gasPrice * element.gasUsed;
        final Amount txFee = element.gasCost;
        final transactionAmount = element.value;
        final addressFrom = checksumEthereumAddress(element.from);
        final addressTo = checksumEthereumAddress(element.to);

        bool isIncoming;
        bool txFailed = false;
        if (addressFrom == thisAddress) {
          if (element.isError) {
            txFailed = true;
          }
          isIncoming = false;
        } else if (addressTo == thisAddress) {
          isIncoming = true;
        } else {
          continue;
        }

        // hack eth tx data into inputs and outputs
        final List<OutputV2> outputs = [];
        final List<InputV2> inputs = [];

        OutputV2 output = OutputV2.isarCantDoRequiredInDefaultConstructor(
          scriptPubKeyHex: "00",
          valueStringSats: transactionAmount.raw.toString(),
          addresses: [
            addressTo,
          ],
          walletOwns: addressTo == thisAddress,
        );
        InputV2 input = InputV2.isarCantDoRequiredInDefaultConstructor(
          scriptSigHex: null,
          scriptSigAsm: null,
          sequence: null,
          outpoint: null,
          addresses: [addressFrom],
          valueStringSats: transactionAmount.raw.toString(),
          witness: null,
          innerRedeemScriptAsm: null,
          coinbase: null,
          walletOwns: addressFrom == thisAddress,
        );

        final TransactionType txType;
        if (isIncoming) {
          if (addressFrom == addressTo) {
            txType = TransactionType.sentToSelf;
          } else {
            txType = TransactionType.incoming;
          }
        } else {
          txType = TransactionType.outgoing;
        }

        outputs.add(output);
        inputs.add(input);

        final otherData = {
          "nonce": tuple.item2,
          "isCancelled": txFailed,
          "overrideFee": txFee.toJsonString(),
        };

        final txn = TransactionV2(
          walletId: walletId,
          blockHash: element.blockHash,
          hash: element.hash,
          txid: element.hash,
          timestamp: element.timestamp,
          height: element.blockNumber,
          inputs: List.unmodifiable(inputs),
          outputs: List.unmodifiable(outputs),
          version: -1,
          type: txType,
          subType: TransactionSubType.none,
          otherData: jsonEncode(otherData),
        );

        txns.add(txn);
      }
      await mainDB.updateOrPutTransactionV2s(txns);
    } else {
      Logging.instance.log(
        "Failed to refresh transactions with nonces for ${cryptoCurrency.coin.prettyName} "
        "${info.name} $walletId: ${txsResponse.exception}",
        level: LogLevel.Warning,
      );
    }
  }

  @override
  Future<bool> updateUTXOs() async {
    // not used in eth
    return false;
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    final int
        rate; // TODO: use BigInt for feeObject whenever FeeObject gets redone
    final feeObject = await fees;
    switch (txData.feeRateType!) {
      case FeeRateType.fast:
        rate = feeObject.fast;
        break;
      case FeeRateType.average:
        rate = feeObject.medium;
        break;
      case FeeRateType.slow:
        rate = feeObject.slow;
        break;
      case FeeRateType.custom:
        throw UnimplementedError("custom eth fees");
    }

    final feeEstimate = await estimateFeeFor(Amount.zero, rate);

    // bool isSendAll = false;
    // final availableBalance = balance.spendable;
    // if (satoshiAmount == availableBalance) {
    //   isSendAll = true;
    // }
    //
    // if (isSendAll) {
    //   //Subtract fee amount from send amount
    //   satoshiAmount -= feeEstimate;
    // }

    final client = getEthClient();

    final myAddress = (await getCurrentReceivingAddress())!.value;
    final myWeb3Address = web3.EthereumAddress.fromHex(myAddress);

    final amount = txData.recipients!.first.amount;
    final address = txData.recipients!.first.address;

    // final est = await client.estimateGas(
    //   sender: myWeb3Address,
    //   to: web3.EthereumAddress.fromHex(address),
    //   gasPrice: web3.EtherAmount.fromUnitAndValue(
    //     web3.EtherUnit.wei,
    //     rate,
    //   ),
    //   amountOfGas: BigInt.from((cryptoCurrency as Ethereum).gasLimit),
    //   value: web3.EtherAmount.inWei(amount.raw),
    // );

    final nonce = txData.nonce ??
        await client.getTransactionCount(myWeb3Address,
            atBlock: const web3.BlockNum.pending());

    // final nResponse = await EthereumAPI.getAddressNonce(address: myAddress);
    // print("==============================================================");
    // print("ETH client.estimateGas:  $est");
    // print("ETH estimateFeeFor    :  $feeEstimate");
    // print("ETH nonce custom response:  $nResponse");
    // print("ETH actual nonce         :  $nonce");
    // print("==============================================================");

    final tx = web3.Transaction(
      to: web3.EthereumAddress.fromHex(address),
      gasPrice: web3.EtherAmount.fromUnitAndValue(
        web3.EtherUnit.wei,
        rate,
      ),
      maxGas: (cryptoCurrency as Ethereum).gasLimit,
      value: web3.EtherAmount.inWei(amount.raw),
      nonce: nonce,
    );

    return txData.copyWith(
      nonce: tx.nonce,
      web3dartTransaction: tx,
      fee: feeEstimate,
      feeInWei: BigInt.from(rate),
      chainId: (await client.getChainId()),
    );
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    final client = getEthClient();
    if (_credentials == null) {
      await _initCredentials();
    }

    final txid = await client.sendTransaction(
      _credentials!,
      txData.web3dartTransaction!,
      chainId: txData.chainId!.toInt(),
    );

    return txData.copyWith(
      txid: txid,
      txHash: txid,
    );
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    await refreshMutex.protect(() async {
      if (isRescan) {
        await mainDB.deleteWalletBlockchainData(walletId);
        await checkSaveInitialReceivingAddress();
        await updateBalance();
        await updateTransactions(isRescan: true);
      } else {
        await checkSaveInitialReceivingAddress();
        unawaited(updateBalance());
        unawaited(updateTransactions());
      }
    });
  }

  @override
  Future<void> exit() async {
    timer?.cancel();
    timer = null;
    await super.exit();
  }
}
