import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:isar/isar.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';
import 'package:tuple/tuple.dart';

import '../../../exceptions/wallet/node_tor_mismatch_config_exception.dart';
import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart' as isar;
import '../../../models/isar/models/isar_models.dart';
import '../../../models/node_model.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../services/node_service.dart';
import '../../../services/tor_service.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/prefs.dart';
import '../../../utilities/tor_plain_net_option_enum.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_wallet.dart';

class SolanaWallet extends Bip39Wallet<Solana> {
  SolanaWallet(CryptoCurrencyNetwork network) : super(Solana(network));

  static const String _addressDerivationPath = "m/44'/501'/0'/0'";

  NodeModel? _solNode;

  RpcClient? _rpcClient; // The Solana RpcClient.

  Future<Ed25519HDKeyPair> _getKeyPair() async {
    return Ed25519HDKeyPair.fromMnemonic(
      await getMnemonic(),
      account: 0,
      change: 0,
    );
  }

  Future<Address> _generateAddress() async {
    final addressStruct = Address(
      walletId: walletId,
      value: (await _getKeyPair()).address,
      publicKey: List<int>.empty(),
      derivationIndex: 0,
      derivationPath: DerivationPath()..value = _addressDerivationPath,
      type: info.mainAddressType,
      subType: AddressSubType.receiving,
    );
    return addressStruct;
  }

  Future<int> _getCurrentBalanceInLamports() async {
    _checkClient();
    final balance = await _rpcClient?.getBalance((await _getKeyPair()).address);
    return balance!.value;
  }

  Future<int?> _getEstimatedNetworkFee(Amount transferAmount) async {
    _checkClient();
    final latestBlockhash = await _rpcClient?.getLatestBlockhash();
    final pubKey = (await _getKeyPair()).publicKey;

    final compiledMessage = Message(
      instructions: [
        SystemInstruction.transfer(
          fundingAccount: pubKey,
          recipientAccount: pubKey,
          lamports: transferAmount.raw.toInt(),
        ),
      ],
    ).compile(
      recentBlockhash: latestBlockhash!.value.blockhash,
      feePayer: pubKey,
    );

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
      Address? address = await getCurrentReceivingAddress();

      if (address == null) {
        address = await _generateAddress();

        await mainDB.updateOrPutAddresses([address]);
      }
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
          "Failed to get fees, please check your node connection.",
        );
      }

      final address = await getCurrentReceivingAddress();

      // Rent exemption of Solana
      final accInfo = await _rpcClient?.getAccountInfo(address!.value);
      if (accInfo!.value == null) {
        throw Exception("Account does not appear to exist");
      }

      final int minimumRent =
          await _rpcClient!.getMinimumBalanceForRentExemption(
        accInfo.value!.data.toString().length,
      );
      if (minimumRent >
          ((await _getCurrentBalanceInLamports()) -
              txData.amount!.raw.toInt() -
              feeAmount)) {
        throw Exception(
          "Insufficient remaining balance for rent exemption, minimum rent: "
          "${minimumRent / pow(10, cryptoCurrency.fractionDigits)}",
        );
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
            lamports: txData.amount!.raw.toInt(),
          ),
          ComputeBudgetInstruction.setComputeUnitPrice(
            microLamports: txData.fee!.raw.toInt() - 5000,
          ),
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
      slow: fee,
    );
  }

  @override
  Future<bool> pingCheck() async {
    String? health;
    try {
      _checkClient();
      health = await _rpcClient?.getHealth();
      return health != null;
    } catch (e, s) {
      Logging.instance.log(
        "$runtimeType Solana pingCheck failed \"health response=$health\": $e\n$s",
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
      final addressStruct = await _generateAddress();

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
    _checkClient();
    try {
      final address = await getCurrentReceivingAddress();

      final balance = await _rpcClient?.getBalance(address!.value);

      // Rent exemption of Solana
      final accInfo = await _rpcClient?.getAccountInfo(address!.value);
      if (accInfo!.value == null) {
        throw Exception("Account does not appear to exist");
      }

      final int minimumRent =
          await _rpcClient!.getMinimumBalanceForRentExemption(
        accInfo.value!.data.toString().length,
      );
      final spendableBalance = balance!.value - minimumRent;

      final newBalance = Balance(
        total: Amount(
          rawValue: BigInt.from(balance.value),
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        spendable: Amount(
          rawValue: BigInt.from(spendableBalance),
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        blockedTotal: Amount(
          rawValue: BigInt.from(minimumRent),
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
    _solNode = NodeService(secureStorageInterface: secureStorageInterface)
            .getPrimaryNodeFor(currency: info.coin) ??
        info.coin.defaultNode;
    await refresh();
  }

  @override
  NodeModel getCurrentNode() {
    _solNode ??= NodeService(secureStorageInterface: secureStorageInterface)
            .getPrimaryNodeFor(currency: info.coin) ??
        info.coin.defaultNode;

    return _solNode!;
  }

  @override
  Future<void> updateTransactions() async {
    try {
      _checkClient();

      final transactionsList = await _rpcClient?.getTransactionsList(
        (await _getKeyPair()).publicKey,
        encoding: Encoding.jsonParsed,
      );
      final txsList =
          List<Tuple2<isar.Transaction, Address>>.empty(growable: true);

      final myAddress = (await getCurrentReceivingAddress())!;

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

        if ((senderAddress == myAddress.value) &&
            (receiverAddress == "11111111111111111111111111111111")) {
          // The account that is only 1's are System Program accounts which
          // means there is no receiver except the sender,
          // see: https://explorer.solana.com/address/11111111111111111111111111111111
          txType = isar.TransactionType.sentToSelf;
          receiverAddress = senderAddress;
        } else if (senderAddress == myAddress.value) {
          txType = isar.TransactionType.outgoing;
        } else if (receiverAddress == myAddress.value) {
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
          derivationPath: DerivationPath()..value = _addressDerivationPath,
          type: AddressType.solana,
          subType: txType == isar.TransactionType.outgoing
              ? AddressSubType.unknown
              : AddressSubType.receiving,
        );

        txsList.add(Tuple2(transaction, txAddress));
      }
      await mainDB.addNewTransactionData(txsList, walletId);
    } on NodeTorMismatchConfigException {
      rethrow;
    } catch (e, s) {
      Logging.instance.log(
        "Error occurred in solana_wallet.dart while getting"
        " transactions for solana: $e\n$s",
        level: LogLevel.Error,
      );
    }
  }

  @override
  Future<bool> updateUTXOs() async {
    // No UTXOs in Solana
    return false;
  }

  /// Make sure the Solana RpcClient uses Tor if it's enabled.
  ///
  void _checkClient() {
    final node = getCurrentNode();

    final netOption = TorPlainNetworkOption.fromNodeData(
      node.torEnabled,
      node.clearnetEnabled,
    );

    if (prefs.useTor) {
      if (netOption == TorPlainNetworkOption.clear) {
        _rpcClient = null;
        throw NodeTorMismatchConfigException(
          message: "TOR enabled but node set to clearnet only",
        );
      }
    } else {
      if (netOption == TorPlainNetworkOption.tor) {
        _rpcClient = null;
        throw NodeTorMismatchConfigException(
          message: "TOR off but node set to TOR only",
        );
      }
    }

    _rpcClient = createRpcClient(
      node.host,
      node.port,
      node.useSSL,
      prefs,
      TorService.sharedInstance,
    );
  }

  // static helper function for building a sol rpc client
  static RpcClient createRpcClient(
    final String host,
    final int port,
    final bool useSSL,
    final Prefs prefs,
    final TorService torService,
  ) {
    HttpClient? httpClient;

    if (prefs.useTor) {
      // Make proxied HttpClient.
      final proxyInfo = torService.getProxyInfo();

      final proxySettings = ProxySettings(proxyInfo.host, proxyInfo.port);
      httpClient = HttpClient();
      SocksTCPClient.assignToHttpClient(httpClient, [proxySettings]);
    }

    final regex = RegExp("^(http|https)://");

    String editedHost;
    if (host.startsWith(regex)) {
      editedHost = host.replaceFirst(regex, "");
    } else {
      editedHost = host;
    }

    while (editedHost.endsWith("/")) {
      editedHost = editedHost.substring(0, editedHost.length - 1);
    }

    final uri = Uri(
      scheme: useSSL ? "https" : "http",
      host: editedHost,
      port: port,
    );

    return RpcClient(
      uri.toString(),
      timeout: const Duration(seconds: 30),
      customHeaders: {},
      httpClient: httpClient,
    );
  }
}
