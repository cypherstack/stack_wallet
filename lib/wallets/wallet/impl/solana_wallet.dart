import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:isar/isar.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart'
    as isar;
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/solana.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_wallet.dart';
import 'package:tuple/tuple.dart';

class SolanaWallet extends Bip39Wallet<Solana> {
  SolanaWallet(CryptoCurrencyNetwork network) : super(Solana(network));

  NodeModel? _solNode;

  RpcClient? _rpcClient; // The Solana RpcClient.

  Future<Ed25519HDKeyPair> _getKeyPair() async {
    return Ed25519HDKeyPair.fromMnemonic(await getMnemonic(),
        account: 0, change: 0);
  }

  Future<Address> _getCurrentAddress() async {
    final addressStruct = Address(
        walletId: walletId,
        value: (await _getKeyPair()).address,
        publicKey: List<int>.empty(),
        derivationIndex: 0,
        derivationPath: DerivationPath()..value = "m/44'/501'/0'/0'",
        type: cryptoCurrency.coin.primaryAddressType,
        subType: AddressSubType.unknown);
    return addressStruct;
  }

  Future<int> _getCurrentBalanceInLamports() async {
    _checkClient();
    final balance = await _rpcClient?.getBalance((await _getKeyPair()).address);
    return balance!.value;
  }

  Future<int?> _getEstimatedNetworkFee(Amount transferAmount) async {
    final latestBlockhash = await _rpcClient?.getLatestBlockhash();
    final pubKey = (await _getKeyPair()).publicKey;

    final compiledMessage = Message(instructions: [
      SystemInstruction.transfer(
        fundingAccount: pubKey,
        recipientAccount: pubKey,
        lamports: transferAmount.raw.toInt(),
      )
    ]).compile(recentBlockhash: latestBlockhash!.value.blockhash, feePayer: (await _getKeyPair()).publicKey);

    return await _rpcClient?.getFeeForMessage(
      base64Encode(compiledMessage.toByteArray().toList()),
    );
  }

  @override
  FilterOperation? get changeAddressFilterOperation =>
      throw UnimplementedError();

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    try {
      final address = (await _getKeyPair()).address;

      await mainDB.updateOrPutAddresses([
        Address(
            walletId: walletId,
            value: address,
            publicKey: List<int>.empty(),
            derivationIndex: 0,
            derivationPath: DerivationPath()..value = "m/44'/501'/0'/0'",
            type: cryptoCurrency.coin.primaryAddressType,
            subType: AddressSubType.unknown)
      ]);
    } catch (e, s) {
      Logging.instance.log(
        "$runtimeType  checkSaveInitialReceivingAddress() failed: $e\n$s",
        level: LogLevel.Error,
      );
    }
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    try {
      _checkClient();

      if (txData.recipients == null || txData.recipients!.length != 1) {
        throw Exception("$runtimeType prepareSend requires 1 recipient");
      }

      final Amount sendAmount = txData.amount!;

      if (sendAmount > info.cachedBalance.spendable) {
        throw Exception("Insufficient available balance");
      }

      final feeAmount = await _getEstimatedNetworkFee(sendAmount);
      if (feeAmount == null) {
        throw Exception(
            "Failed to get fees, please check your node connection.");
      }

      // Rent exemption of Solana
      final accInfo =
          await _rpcClient?.getAccountInfo((await _getKeyPair()).address);
      final int minimumRent =
          await _rpcClient?.getMinimumBalanceForRentExemption(
                  accInfo!.value!.data.toString().length) ??
              0; // TODO revisit null condition.
      if (minimumRent >
          ((await _getCurrentBalanceInLamports()) -
              txData.amount!.raw.toInt() -
              feeAmount)) {
        throw Exception(
            "Insufficient remaining balance for rent exemption, minimum rent: ${minimumRent / pow(10, cryptoCurrency.fractionDigits)}");
      }

      return txData.copyWith(
        fee: Amount(
          rawValue: BigInt.from(feeAmount),
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
      );
    } catch (e, s) {
      Logging.instance.log(
        "$runtimeType Solana prepareSend failed: $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      _checkClient();

      final keyPair = await _getKeyPair();
      final recipientAccount = txData.recipients!.first;
      final recipientPubKey =
          Ed25519HDPublicKey.fromBase58(recipientAccount.address);
      final message = Message(
        instructions: [
          SystemInstruction.transfer(
              fundingAccount: keyPair.publicKey,
              recipientAccount: recipientPubKey,
              lamports: txData.amount!.raw.toInt()),
          ComputeBudgetInstruction.setComputeUnitPrice(
              microLamports: txData.fee!.raw.toInt() - 5000),
          // 5000 lamports is the base fee for a transaction. This instruction adds the necessary fee on top of base fee if it is needed.
          ComputeBudgetInstruction.setComputeUnitLimit(units: 1000000),
          // 1000000 is the multiplication number to turn the compute unit price of microLamports to lamports.
          // These instructions also help the user to not pay more than the shown fee.
          // See: https://solanacookbook.com/references/basic-transactions.html#how-to-change-compute-budget-fee-priority-for-a-transaction
        ],
      );

      final txid = await _rpcClient?.signAndSendTransaction(message, [keyPair]);
      return txData.copyWith(
        txid: txid,
      );
    } catch (e, s) {
      Logging.instance.log(
        "$runtimeType Solana confirmSend failed: $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    _checkClient();

    if (info.cachedBalance.spendable.raw == BigInt.zero) {
      return Amount(
        rawValue: BigInt.zero,
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    }

    final fee = await _getEstimatedNetworkFee(amount);
    if (fee == null) {
      throw Exception("Failed to get fees, please check your node connection.");
    }

    return Amount(
      rawValue: BigInt.from(fee),
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }

  @override
  Future<FeeObject> get fees async {
    _checkClient();

    final fee = await _getEstimatedNetworkFee(
      Amount.fromDecimal(
        Decimal.one, // 1 SOL
        fractionDigits: cryptoCurrency.fractionDigits,
      ),
    );
    if (fee == null) {
      throw Exception("Failed to get fees, please check your node connection.");
    }

    return FeeObject(
        numberOfBlocksFast: 1,
        numberOfBlocksAverage: 1,
        numberOfBlocksSlow: 1,
        fast: fee,
        medium: fee,
        slow: fee);
  }

  @override
  Future<bool> pingCheck() {
    try {
      _checkClient();
      _rpcClient?.getHealth();
      return Future.value(true);
    } catch (e, s) {
      Logging.instance.log(
        "$runtimeType Solana pingCheck failed: $e\n$s",
        level: LogLevel.Error,
      );
      return Future.value(false);
    }
  }

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  @override
  Future<void> recover({required bool isRescan}) async {
    await refreshMutex.protect(() async {
      final addressStruct = await _getCurrentAddress();

      await mainDB.updateOrPutAddresses([addressStruct]);

      if (info.cachedReceivingAddress != addressStruct.value) {
        await info.updateReceivingAddress(
          newAddress: addressStruct.value,
          isar: mainDB.isar,
        );
      }

      await Future.wait([
        updateBalance(),
        updateChainHeight(),
        updateTransactions(),
      ]);
    });
  }

  @override
  Future<void> updateBalance() async {
    try {
      _checkClient();

      final balance = await _rpcClient?.getBalance(info.cachedReceivingAddress);

      // Rent exemption of Solana
      final accInfo =
          await _rpcClient?.getAccountInfo((await _getKeyPair()).address);
      // TODO [prio=low]: handle null account info.
      final int minimumRent =
          await _rpcClient?.getMinimumBalanceForRentExemption(
                  accInfo!.value!.data.toString().length) ??
              0;
      // TODO [prio=low]: revisit null condition.
      final spendableBalance = balance!.value - minimumRent;

      final newBalance = Balance(
        total: Amount(
          rawValue: BigInt.from(balance.value),
          fractionDigits: Coin.solana.decimals,
        ),
        spendable: Amount(
          rawValue: BigInt.from(spendableBalance),
          fractionDigits: Coin.solana.decimals,
        ),
        blockedTotal: Amount(
          rawValue: BigInt.from(minimumRent),
          fractionDigits: Coin.solana.decimals,
        ),
        pendingSpendable: Amount(
          rawValue: BigInt.zero,
          fractionDigits: Coin.solana.decimals,
        ),
      );

      await info.updateBalance(newBalance: newBalance, isar: mainDB.isar);
    } catch (e, s) {
      Logging.instance.log(
        "Error getting balance in solana_wallet.dart: $e\n$s",
        level: LogLevel.Error,
      );
    }
  }

  @override
  Future<void> updateChainHeight() async {
    try {
      _checkClient();

      final int blockHeight = await _rpcClient?.getSlot() ?? 0;
      // TODO [prio=low]: Revisit null condition.

      await info.updateCachedChainHeight(
        newHeight: blockHeight,
        isar: mainDB.isar,
      );
    } catch (e, s) {
      Logging.instance.log(
        "Error occurred in solana_wallet.dart while getting"
        " chain height for solana: $e\n$s",
        level: LogLevel.Error,
      );
    }
  }

  @override
  Future<void> updateNode() async {
    _solNode = getCurrentNode();
    await refresh();
  }

  @override
  NodeModel getCurrentNode() {
    return _solNode ??
        NodeService(secureStorageInterface: secureStorageInterface)
            .getPrimaryNodeFor(coin: info.coin) ??
        DefaultNodes.getNodeFor(info.coin);
  }

  @override
  Future<void> updateTransactions() async {
    try {
      _checkClient();

      final transactionsList = await _rpcClient?.getTransactionsList(
          (await _getKeyPair()).publicKey,
          encoding: Encoding.jsonParsed);
      final txsList =
          List<Tuple2<isar.Transaction, Address>>.empty(growable: true);

      // TODO [prio=low]: Revisit null assertion below.

      for (final tx in transactionsList!) {
        final senderAddress =
            (tx.transaction as ParsedTransaction).message.accountKeys[0].pubkey;
        var receiverAddress =
            (tx.transaction as ParsedTransaction).message.accountKeys[1].pubkey;
        var txType = isar.TransactionType.unknown;
        final txAmount = Amount(
          rawValue:
              BigInt.from(tx.meta!.postBalances[1] - tx.meta!.preBalances[1]),
          fractionDigits: cryptoCurrency.fractionDigits,
        );

        if ((senderAddress == (await _getKeyPair()).address) && (receiverAddress == "11111111111111111111111111111111")) {
          // The account that is only 1's are System Program accounts which means there is no receiver except the sender, see: https://explorer.solana.com/address/11111111111111111111111111111111
          txType = isar.TransactionType.sentToSelf;
          receiverAddress = senderAddress;
        } else if (senderAddress == (await _getKeyPair()).address) {
          txType = isar.TransactionType.outgoing;
        } else if (receiverAddress == (await _getKeyPair()).address) {
          txType = isar.TransactionType.incoming;
        }

        final transaction = isar.Transaction(
          walletId: walletId,
          txid: (tx.transaction as ParsedTransaction).signatures[0],
          timestamp: tx.blockTime!,
          type: txType,
          subType: isar.TransactionSubType.none,
          amount: tx.meta!.postBalances[1] - tx.meta!.preBalances[1],
          amountString: txAmount.toJsonString(),
          fee: tx.meta!.fee,
          height: tx.slot,
          isCancelled: false,
          isLelantus: false,
          slateId: null,
          otherData: null,
          inputs: [],
          outputs: [],
          nonce: null,
          numberOfMessages: 0,
        );

        final txAddress = Address(
            walletId: walletId,
            value: receiverAddress,
            publicKey: List<int>.empty(),
            derivationIndex: 0,
            derivationPath: DerivationPath()..value = "m/44'/501'/0'/0'",
            type: AddressType.solana,
            subType: txType == isar.TransactionType.outgoing
                ? AddressSubType.unknown
                : AddressSubType.receiving);

        txsList.add(Tuple2(transaction, txAddress));
      }
      await mainDB.addNewTransactionData(txsList, walletId);
    } catch (e, s) {
      Logging.instance.log(
        "Error occurred in solana_wallet.dart while getting"
        " transactions for solana: $e\n$s",
        level: LogLevel.Error,
      );
    }
  }

  @override
  Future<bool> updateUTXOs() {
    // No UTXOs in Solana
    return Future.value(false);
  }

  /// Make sure the Solana RpcClient uses Tor if it's enabled.
  ///
  void _checkClient() async {
    HttpClient? httpClient;

    if (prefs.useTor) {
      // Make proxied HttpClient.
      final ({InternetAddress host, int port}) proxyInfo =
          TorService.sharedInstance.getProxyInfo();

      final proxySettings = ProxySettings(proxyInfo.host, proxyInfo.port);
      httpClient = HttpClient();
      SocksTCPClient.assignToHttpClient(httpClient, [proxySettings]);
    }

    _rpcClient = RpcClient(
      "${getCurrentNode().host}:${getCurrentNode().port}",
      timeout: const Duration(seconds: 30),
      customHeaders: {},
      httpClient: httpClient,
    );
    return;
  }
}
