import 'dart:async';
import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:nanodart/nanodart.dart';
import 'package:tuple/tuple.dart';

import '../../../external_api_keys.dart';
import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/node_model.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../networking/http.dart';
import '../../../services/nano_api.dart';
import '../../../services/node_service.dart';
import '../../../services/tor_service.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/extensions/impl/string.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/intermediate/nano_currency.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_wallet.dart';

// const _kWorkServer = "https://rpc.nano.to";
const _kWorkServer = "https://nodes.nanswap.com/XNO";

Map<String, String> _buildHeaders(String url) {
  final result = {
    'Content-type': 'application/json',
  };
  if (url
      case "https://nodes.nanswap.com/XNO" || "https://nodes.nanswap.com/BAN") {
    result["nodes-api-key"] = kNanoSwapRpcApiKey;
  }
  return result;
}

mixin NanoInterface<T extends NanoCurrency> on Bip39Wallet<T> {
  // since nano based coins only have a single address/account we can cache
  // the address instead of fetching from db every time we need it in certain
  // cases
  Address? _cachedAddress;

  NodeModel? _cachedNode;

  final _httpClient = HTTP();

  Future<String?> _requestWork(String hash) async {
    return _httpClient
        .post(
      url: Uri.parse(_kWorkServer), // this should be a
      headers: _buildHeaders(_kWorkServer),
      body: json.encode(
        {
          "action": "work_generate",
          "hash": hash,
        },
      ),
      proxyInfo: prefs.useTor ? TorService.sharedInstance.getProxyInfo() : null,
    )
        .then((_httpClient) {
      if (_httpClient.code == 200) {
        final Map<String, dynamic> decoded =
            json.decode(_httpClient.body) as Map<String, dynamic>;
        if (decoded.containsKey("error")) {
          throw Exception("Received error ${decoded["error"]}");
        }
        return decoded["work"] as String?;
      } else {
        throw Exception("Received error ${_httpClient.code}");
      }
    });
  }

  Future<String> _getPrivateKeyFromMnemonic() async {
    final mnemonicList = await getMnemonicAsWords();
    final seed = NanoMnemomics.mnemonicListToSeed(mnemonicList);
    return NanoKeys.seedToPrivate(seed, 0);
  }

  Future<Address> _getAddressFromMnemonic() async {
    final publicKey = NanoKeys.createPublicKey(
      await _getPrivateKeyFromMnemonic(),
    );

    final addressString =
        NanoAccounts.createAccount(cryptoCurrency.nanoAccountType, publicKey);

    return Address(
      walletId: walletId,
      value: addressString,
      publicKey: publicKey.toUint8ListFromHex,
      derivationIndex: 0,
      derivationPath: null,
      type: info.mainAddressType,
      subType: AddressSubType.receiving,
    );
  }

  Future<void> _receiveBlock(
    String blockHash,
    String source,
    String amountRaw,
    String publicAddress,
  ) async {
    // TODO: the opening block of an account is a special case
    bool openBlock = false;

    // first check if the account is open:
    // get the account info (we need the frontier and representative):
    final infoBody = jsonEncode({
      "action": "account_info",
      "representative": "true",
      "account": publicAddress,
    });
    final node = getCurrentNode();
    final infoResponse = await _httpClient.post(
      url: Uri.parse(node.host),
      headers: _buildHeaders(node.host),
      body: infoBody,
      proxyInfo: prefs.useTor ? TorService.sharedInstance.getProxyInfo() : null,
    );
    final infoData = jsonDecode(infoResponse.body);

    if (infoData["error"] != null) {
      // account is not open yet, we need to create an open block:
      openBlock = true;
    }

    // first get the account balance:
    final balanceBody = jsonEncode({
      "action": "account_balance",
      "account": publicAddress,
    });

    final balanceResponse = await _httpClient.post(
      url: Uri.parse(node.host),
      headers: _buildHeaders(node.host),
      body: balanceBody,
      proxyInfo: prefs.useTor ? TorService.sharedInstance.getProxyInfo() : null,
    );

    final balanceData = jsonDecode(balanceResponse.body);
    final BigInt currentBalance =
        BigInt.parse(balanceData["balance"].toString());
    final BigInt txAmount = BigInt.parse(amountRaw);
    final BigInt balanceAfterTx = currentBalance + txAmount;

    final String frontier = infoData["frontier"].toString();
    String representative = infoData["representative"].toString();

    if (openBlock) {
      // we don't have a representative set yet:
      representative = cryptoCurrency.defaultRepresentative;
    }

    // link = send block hash:
    final String link = blockHash;
    // this "linkAsAccount" is meaningless:
    final String linkAsAccount =
        NanoAccounts.createAccount(NanoAccountType.BANANO, blockHash);

    // construct the receive block:
    final Map<String, String> receiveBlock = {
      "type": "state",
      "account": publicAddress,
      "previous": openBlock
          ? "0000000000000000000000000000000000000000000000000000000000000000"
          : frontier,
      "representative": representative,
      "balance": balanceAfterTx.toString(),
      "link": link,
      "link_as_account": linkAsAccount,
    };

    // sign the receive block:
    final String hash = NanoBlocks.computeStateHash(
      NanoAccountType.BANANO,
      receiveBlock["account"]!,
      receiveBlock["previous"]!,
      receiveBlock["representative"]!,
      BigInt.parse(receiveBlock["balance"]!),
      receiveBlock["link"]!,
    );
    final String privateKey = await _getPrivateKeyFromMnemonic();
    final String signature = NanoSignatures.signBlock(hash, privateKey);

    // get PoW for the receive block:
    String? work;
    if (openBlock) {
      work = await _requestWork(NanoAccounts.extractPublicKey(publicAddress));
    } else {
      work = await _requestWork(frontier);
    }
    if (work == null) {
      throw Exception("Failed to get PoW for receive block");
    }
    receiveBlock["link_as_account"] = linkAsAccount;
    receiveBlock["signature"] = signature;
    receiveBlock["work"] = work;

    // process the receive block:

    final processBody = jsonEncode({
      "action": "process",
      "json_block": "true",
      "subtype": "receive",
      "block": receiveBlock,
    });
    final processResponse = await _httpClient.post(
      url: Uri.parse(node.host),
      headers: _buildHeaders(node.host),
      body: processBody,
      proxyInfo: prefs.useTor ? TorService.sharedInstance.getProxyInfo() : null,
    );

    final Map<String, dynamic> decoded =
        json.decode(processResponse.body) as Map<String, dynamic>;
    if (decoded.containsKey("error")) {
      throw Exception("Received error ${decoded["error"]}");
    }
  }

  Future<void> _confirmAllReceivable(String accountAddress) async {
    final node = getCurrentNode();
    final receivableResponse = await _httpClient.post(
      url: Uri.parse(node.host),
      headers: _buildHeaders(node.host),
      body: jsonEncode({
        "action": "receivable",
        "source": "true",
        "account": accountAddress,
      }),
      proxyInfo: prefs.useTor ? TorService.sharedInstance.getProxyInfo() : null,
    );

    final receivableData = await jsonDecode(receivableResponse.body);
    if (receivableData["blocks"] == "") {
      return;
    }
    final blocks = receivableData["blocks"] as Map<String, dynamic>;
    // confirm all receivable blocks:
    for (final blockHash in blocks.keys) {
      final block = blocks[blockHash];
      final String amountRaw = block["amount"] as String;
      final String source = block["source"] as String;
      await _receiveBlock(blockHash, source, amountRaw, accountAddress);
      // a bit of a hack:
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  //========= public ===========================================================

  Future<String> getCurrentRepresentative() async {
    final serverURI = Uri.parse(getCurrentNode().host);
    final address =
        (_cachedAddress ?? await getCurrentReceivingAddress())!.value;

    final node = getCurrentNode();
    final response = await NanoAPI.getAccountInfo(
      server: serverURI,
      representative: true,
      account: address,
      headers: _buildHeaders(node.host),
    );

    return response.accountInfo?.representative ??
        cryptoCurrency.defaultRepresentative;
  }

  Future<bool> changeRepresentative(String newRepresentative) async {
    try {
      final node = getCurrentNode();
      final serverURI = Uri.parse(node.host);
      await updateBalance();
      final balance = info.cachedBalance.spendable.raw.toString();
      final String privateKey = await _getPrivateKeyFromMnemonic();
      final address =
          (_cachedAddress ?? await getCurrentReceivingAddress())!.value;

      final response = await NanoAPI.getAccountInfo(
        server: serverURI,
        representative: true,
        account: address,
        headers: _buildHeaders(node.host),
      );

      if (response.accountInfo == null) {
        throw response.exception ?? Exception("Failed to get account info");
      }

      final work = await _requestWork(response.accountInfo!.frontier);

      return await NanoAPI.changeRepresentative(
        server: serverURI,
        accountType: NanoAccountType.BANANO,
        account: address,
        newRepresentative: newRepresentative,
        previousBlock: response.accountInfo!.frontier,
        balance: balance,
        privateKey: privateKey,
        work: work!,
        headers: _buildHeaders(node.host),
      );
    } catch (_) {
      rethrow;
    }
  }

  //========= overrides ========================================================

  @override
  Future<void> updateNode() async {
    _cachedNode = NodeService(secureStorageInterface: secureStorageInterface)
            .getPrimaryNodeFor(currency: info.coin) ??
        info.coin.defaultNode;

    unawaited(refresh());
  }

  @override
  NodeModel getCurrentNode() {
    return _cachedNode ??
        NodeService(secureStorageInterface: secureStorageInterface)
            .getPrimaryNodeFor(currency: info.coin) ??
        info.coin.defaultNode;
  }

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    try {
      _cachedAddress = await getCurrentReceivingAddress();
      if (_cachedAddress == null) {
        _cachedAddress = await _getAddressFromMnemonic();
        await mainDB.updateOrPutAddresses([_cachedAddress!]);
      }
    } catch (e, s) {
      // do nothing, still allow user into wallet
      Logging.instance.log(
        "$runtimeType  checkSaveInitialReceivingAddress() failed: $e\n$s",
        level: LogLevel.Error,
      );
    }
  }

  @override
  Future<bool> pingCheck() async {
    final node = getCurrentNode();
    final uri = Uri.parse(node.host);
    final response = await _httpClient.post(
      url: uri,
      headers: _buildHeaders(node.host),
      body: jsonEncode(
        {
          "action": "version",
        },
      ),
      proxyInfo: prefs.useTor ? TorService.sharedInstance.getProxyInfo() : null,
    );

    return response.code == 200;
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    if (txData.recipients!.length != 1) {
      throw ArgumentError(
        "${cryptoCurrency.runtimeType} currently only "
        "supports one recipient per transaction",
      );
    }

    return txData.copyWith(
      fee: Amount(
        rawValue: BigInt.zero,
        fractionDigits: cryptoCurrency.fractionDigits,
      ),
    );
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      // our address:
      final String publicAddress =
          (_cachedAddress ?? await getCurrentReceivingAddress())!.value;

      // first update to get latest account balance:

      final currentBalance = info.cachedBalance.spendable;
      final txAmount = txData.amount!;
      final BigInt balanceAfterTx = (currentBalance - txAmount).raw;

      // get the account info (we need the frontier and representative):
      final infoBody = jsonEncode({
        "action": "account_info",
        "representative": "true",
        "account": publicAddress,
      });

      final node = getCurrentNode();
      final infoResponse = await _httpClient.post(
        url: Uri.parse(node.host),
        headers: _buildHeaders(node.host),
        body: infoBody,
        proxyInfo:
            prefs.useTor ? TorService.sharedInstance.getProxyInfo() : null,
      );

      final String frontier =
          jsonDecode(infoResponse.body)["frontier"].toString();
      final String representative =
          jsonDecode(infoResponse.body)["representative"].toString();
      // link = destination address:
      final String linkAsAccount = txData.recipients!.first.address;
      final String link = NanoAccounts.extractPublicKey(linkAsAccount);

      // construct the send block:
      final Map<String, String> sendBlock = {
        "type": "state",
        "account": publicAddress,
        "previous": frontier,
        "representative": representative,
        "balance": balanceAfterTx.toString(),
        "link": link,
      };

      // sign the send block:
      final String hash = NanoBlocks.computeStateHash(
        NanoAccountType.BANANO,
        sendBlock["account"]!,
        sendBlock["previous"]!,
        sendBlock["representative"]!,
        BigInt.parse(sendBlock["balance"]!),
        sendBlock["link"]!,
      );
      final String privateKey = await _getPrivateKeyFromMnemonic();
      final String signature = NanoSignatures.signBlock(hash, privateKey);

      // get PoW for the send block:
      final String? work = await _requestWork(frontier);
      if (work == null) {
        throw Exception("Failed to get PoW for send block");
      }

      sendBlock["link_as_account"] = linkAsAccount;
      sendBlock["signature"] = signature;
      sendBlock["work"] = work;

      final processBody = jsonEncode({
        "action": "process",
        "json_block": "true",
        "subtype": "send",
        "block": sendBlock,
      });
      final processResponse = await _httpClient.post(
        url: Uri.parse(node.host),
        headers: _buildHeaders(node.host),
        body: processBody,
        proxyInfo:
            prefs.useTor ? TorService.sharedInstance.getProxyInfo() : null,
      );

      final Map<String, dynamic> decoded =
          json.decode(processResponse.body) as Map<String, dynamic>;
      if (decoded.containsKey("error")) {
        throw Exception("Received error ${decoded["error"]}");
      }

      // return the hash of the transaction:
      return txData.copyWith(
        txid: decoded["hash"].toString(),
      );
    } catch (e, s) {
      Logging.instance
          .log("Error sending transaction $e - $s", level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    try {
      await refreshMutex.protect(() async {
        if (isRescan) {
          await mainDB.deleteWalletBlockchainData(walletId);
        }
        _cachedAddress = await _getAddressFromMnemonic();

        await mainDB.updateOrPutAddresses([_cachedAddress!]);
      });

      await refresh();
    } catch (e) {
      rethrow;
    }
  }

  // recurse over api calls if required
  // (if more than 200 history items)
  Future<Map<String, dynamic>> _fetchAll(
    String publicAddress,
    String? previous,
    Map<String, dynamic>? data,
  ) async {
    final node = getCurrentNode();
    final body = {
      "action": "account_history",
      "account": publicAddress,
      "count": "200",
    };

    if (previous is String) {
      body["head"] = previous;
    }

    final response = await _httpClient.post(
      url: Uri.parse(node.host),
      headers: _buildHeaders(node.host),
      body: jsonEncode(body),
      proxyInfo: prefs.useTor ? TorService.sharedInstance.getProxyInfo() : null,
    );

    // this should really have proper type checking and error propagation but I'm out of time
    final newData =
        Map<String, dynamic>.from((await jsonDecode(response.body)) as Map);

    if (newData["previous"] is String) {
      if (data?["history"] is List) {
        (newData["history"] as List).addAll(data!["history"] as List);
      }
      return await _fetchAll(
        publicAddress,
        newData["previous"] as String,
        newData,
      );
    }

    return newData;
  }

  @override
  Future<void> updateTransactions() async {
    await updateChainHeight();
    final receivingAddress =
        (_cachedAddress ?? await getCurrentReceivingAddress())!;
    final String publicAddress = receivingAddress.value;
    await _confirmAllReceivable(publicAddress);

    final data = await _fetchAll(publicAddress, null, null);

    final transactions = data["history"] is List
        ? data["history"] as List<dynamic>
        : <dynamic>[];
    if (transactions.isEmpty) {
      return;
    } else {
      final List<Tuple2<Transaction, Address?>> transactionList = [];
      for (final tx in transactions) {
        final typeString = tx["type"].toString();
        TransactionType transactionType = TransactionType.unknown;
        if (typeString == "send") {
          transactionType = TransactionType.outgoing;
        } else if (typeString == "receive") {
          transactionType = TransactionType.incoming;
        }
        final amount = Amount(
          rawValue: BigInt.parse(tx["amount"].toString()),
          fractionDigits: cryptoCurrency.fractionDigits,
        );

        final transaction = Transaction(
          walletId: walletId,
          txid: tx["hash"].toString(),
          timestamp: int.parse(tx["local_timestamp"].toString()),
          type: transactionType,
          subType: TransactionSubType.none,
          amount: 0,
          amountString: amount.toJsonString(),
          fee: 0,
          height: int.parse(tx["height"].toString()),
          isCancelled: false,
          isLelantus: false,
          slateId: "",
          otherData: "",
          inputs: [],
          outputs: [],
          nonce: 0,
          numberOfMessages: null,
        );

        final Address address = transactionType == TransactionType.incoming
            ? receivingAddress
            : Address(
                walletId: walletId,
                publicKey: [],
                value: tx["account"].toString(),
                derivationIndex: 0,
                derivationPath: null,
                type: info.mainAddressType,
                subType: AddressSubType.nonWallet,
              );
        final Tuple2<Transaction, Address> tuple = Tuple2(transaction, address);
        transactionList.add(tuple);
      }

      await mainDB.addNewTransactionData(transactionList, walletId);
    }
  }

  @override
  Future<void> updateBalance() async {
    try {
      final addressString =
          (_cachedAddress ??= (await getCurrentReceivingAddress())!).value;
      final body = jsonEncode({
        "action": "account_balance",
        "account": addressString,
      });

      final node = getCurrentNode();
      final response = await _httpClient.post(
        url: Uri.parse(node.host),
        headers: _buildHeaders(node.host),
        body: body,
        proxyInfo:
            prefs.useTor ? TorService.sharedInstance.getProxyInfo() : null,
      );
      final data = jsonDecode(response.body);
      final balance = Balance(
        total: Amount(
          rawValue: (BigInt.parse(data["balance"].toString()) +
              BigInt.parse(data["receivable"].toString())),
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        spendable: Amount(
          rawValue: BigInt.parse(data["balance"].toString()),
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        blockedTotal: Amount(
          rawValue: BigInt.parse("0"),
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        pendingSpendable: Amount(
          rawValue: BigInt.parse(data["receivable"].toString()),
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
      );

      await info.updateBalance(newBalance: balance, isar: mainDB.isar);
    } catch (e, s) {
      Logging.instance.log(
        "Failed to update ${cryptoCurrency.runtimeType} balance: $e\n$s",
        level: LogLevel.Warning,
      );
    }
  }

  @override
  Future<void> updateChainHeight() async {
    try {
      final String publicAddress =
          (_cachedAddress ??= (await getCurrentReceivingAddress())!).value;

      final infoBody = jsonEncode({
        "action": "account_info",
        "account": publicAddress,
      });

      final node = getCurrentNode();
      final infoResponse = await _httpClient.post(
        url: Uri.parse(node.host),
        headers: _buildHeaders(node.host),
        body: infoBody,
        proxyInfo:
            prefs.useTor ? TorService.sharedInstance.getProxyInfo() : null,
      );
      final infoData = jsonDecode(infoResponse.body);

      final height = int.tryParse(
            infoData["confirmation_height"].toString(),
          ) ??
          0;

      await info.updateCachedChainHeight(newHeight: height, isar: mainDB.isar);
    } catch (e, s) {
      Logging.instance.log(
        "Failed to update ${cryptoCurrency.runtimeType} chain height: $e\n$s",
        level: LogLevel.Warning,
      );
    }
  }

  @override
  FilterOperation? get changeAddressFilterOperation =>
      FilterGroup.and(standardChangeAddressFilters);

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  @override
  Future<bool> updateUTXOs() async {
    // do nothing for nano based coins
    return false;
  }

  @override
  // nano has no fees
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async => Amount(
        rawValue: BigInt.from(0),
        fractionDigits: cryptoCurrency.fractionDigits,
      );

  @override
  // nano has no fees
  Future<FeeObject> get fees async => FeeObject(
        numberOfBlocksFast: 1,
        numberOfBlocksAverage: 1,
        numberOfBlocksSlow: 1,
        fast: 0,
        medium: 0,
        slow: 0,
      );
}
