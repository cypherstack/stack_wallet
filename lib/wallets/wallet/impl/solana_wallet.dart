import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:isar_community/isar.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../app_config.dart';
import '../../../exceptions/wallet/node_tor_mismatch_config_exception.dart';
import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart' as isar;
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../models/node_model.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../services/event_bus/events/global/updated_in_background_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
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

  RpcClient? _rpcClient;

  RpcClient? getRpcClient() {
    return _rpcClient;
  }

  Future<Ed25519HDKeyPair> getKeyPair() async {
    return _getKeyPair();
  }

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

  Future<BigInt> _getCurrentBalanceInLamports() async {
    checkClient();
    final balance = await _rpcClient?.getBalance((await _getKeyPair()).address);
    return BigInt.from(balance!.value);
  }

  Future<BigInt?> _getEstimatedNetworkFee(
    Amount transferAmount,
    String? memo,
  ) async {
    checkClient();
    final latestBlockhash = await _rpcClient?.getLatestBlockhash();
    final pubKey = (await _getKeyPair()).publicKey;

    final compiledMessage =
        Message(
          instructions: [
            if (memo != null) MemoInstruction(signers: const [], memo: memo),
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

    final estimate = await _rpcClient?.getFeeForMessage(
      base64Encode(compiledMessage.toByteArray().toList()),
    );

    if (estimate == null) return null;

    return BigInt.from(estimate);
  }

  @override
  int get isarTransactionVersion => 2;

  @override
  FilterOperation? get transactionFilterOperation => FilterGroup.not(
    const FilterCondition.equalTo(
      property: r"subType",
      value: TransactionSubType.splToken,
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
    try {
      Address? address = await getCurrentReceivingAddress();

      if (address == null) {
        address = await _generateAddress();

        await mainDB.updateOrPutAddresses([address]);
      }
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType  checkSaveInitialReceivingAddress() failed: ",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    try {
      checkClient();

      if (txData.recipients == null || txData.recipients!.length != 1) {
        throw Exception("$runtimeType prepareSend requires 1 recipient");
      }

      final Amount sendAmount = txData.amount!;

      if (sendAmount > info.cachedBalance.spendable) {
        throw Exception("Insufficient available balance");
      }

      final feeAmount = await _getEstimatedNetworkFee(sendAmount, txData.memo);
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

      final BigInt minimumRent = BigInt.from(
        await _rpcClient!.getMinimumBalanceForRentExemption(
          accInfo.value!.data.toString().length,
        ),
      );
      if (minimumRent >
          ((await _getCurrentBalanceInLamports()) -
              txData.amount!.raw -
              feeAmount)) {
        throw Exception(
          "Insufficient remaining balance for rent exemption, minimum rent: "
          "${minimumRent.toInt() / pow(10, cryptoCurrency.fractionDigits)}",
        );
      }

      return txData.copyWith(
        fee: Amount(
          rawValue: feeAmount,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
      );
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType Solana prepareSend failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      checkClient();

      final keyPair = await _getKeyPair();
      final recipientAccount = txData.recipients!.first;
      final recipientPubKey = Ed25519HDPublicKey.fromBase58(
        recipientAccount.address,
      );
      final message = Message(
        instructions: [
          if (txData.memo != null)
            MemoInstruction(signers: const [], memo: txData.memo!),
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

      // Persist pending transaction immediately so UI shows "Sending" status.
      if (txid != null) {
        final senderAddress = keyPair.address;
        final isToSelf = senderAddress == recipientAccount.address;

        final tempTx = TransactionV2(
          walletId: walletId,
          blockHash: null, // CRITICAL: indicates pending.
          hash: txid,
          txid: txid,
          timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          height: null, // CRITICAL: indicates pending.
          inputs: [
            InputV2.isarCantDoRequiredInDefaultConstructor(
              scriptSigHex: null,
              scriptSigAsm: null,
              sequence: null,
              outpoint: null,
              addresses: [senderAddress],
              valueStringSats: txData.amount!.raw.toString(),
              witness: null,
              innerRedeemScriptAsm: null,
              coinbase: null,
              walletOwns: true,
            ),
          ],
          outputs: [
            OutputV2.isarCantDoRequiredInDefaultConstructor(
              scriptPubKeyHex: "00",
              valueStringSats: txData.amount!.raw.toString(),
              addresses: [recipientAccount.address],
              walletOwns: isToSelf,
            ),
          ],
          version: -1,
          type: isToSelf
              ? isar.TransactionType.sentToSelf
              : isar.TransactionType.outgoing,
          subType: isar.TransactionSubType.none,
          otherData: jsonEncode({"overrideFee": txData.fee!.toJsonString()}),
        );

        await mainDB.updateOrPutTransactionV2s([tempTx]);
      }

      return txData.copyWith(txid: txid);
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType Solana confirmSend failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
    checkClient();

    if (info.cachedBalance.spendable.raw == BigInt.zero) {
      return Amount(
        rawValue: BigInt.zero,
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    }

    // The feeRate parameter contains the total fee amount to use.
    // For Solana, this is already calculated based on priority tier.
    // Simply return it as the fee estimate.
    return Amount(
      rawValue: feeRate,
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }

  @override
  Future<FeeObject> get fees async {
    checkClient();

    final baseFee = await _getEstimatedNetworkFee(
      Amount.fromDecimal(
        Decimal.one, // 1 SOL.
        fractionDigits: cryptoCurrency.fractionDigits,
      ),
      null, // ?
    );
    if (baseFee == null) {
      throw Exception("Failed to get fees, please check your node connection.");
    }

    // Differentiate fees by tier using multipliers:
    // Base fee is typically around 5000 lamports.
    // Slow: minimum 5000 lamports.
    // Average: base fee * 1.5 (but not less than slow).
    // Fast: base fee * 2.0 (but not less than average).
    // Ensure all fees stay within bounds: 5000-1000000 lamports.
    const minFeeBig = 5000;
    const maxFeeBig = 1000000;

    // Calculate tier fees with multipliers.
    final slowFee = baseFee; // Use base fee for slow.
    final averageFee = (baseFee * BigInt.from(3)) ~/ BigInt.from(2); // 1.5x.
    final fastFee = baseFee * BigInt.from(2); // 2.0x.

    // Clamp all fees to the allowed range.
    final _clamp = (BigInt value) {
      if (value < BigInt.from(minFeeBig)) return BigInt.from(minFeeBig);
      if (value > BigInt.from(maxFeeBig)) return BigInt.from(maxFeeBig);
      return value;
    };

    final clampedSlow = _clamp(slowFee);
    final clampedAverage = _clamp(averageFee);
    final clampedFast = _clamp(fastFee);

    return FeeObject(
      numberOfBlocksFast: 1,
      numberOfBlocksAverage: 1,
      numberOfBlocksSlow: 1,
      fast: clampedFast,
      medium: clampedAverage,
      slow: clampedSlow,
    );
  }

  @override
  Future<bool> pingCheck() async {
    String? health;
    try {
      checkClient();
      health = await _rpcClient?.getHealth();
      return health != null;
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType Solana pingCheck failed \"health response=$health\": $e\n$s",
      );
      return Future.value(false);
    }
  }

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
    checkClient();
    try {
      final address = await getCurrentReceivingAddress();

      final balance = await _rpcClient?.getBalance(address!.value);

      // Rent exemption of Solana
      final accInfo = await _rpcClient?.getAccountInfo(address!.value);
      if (accInfo!.value == null) {
        throw Exception("Account does not appear to exist");
      }

      final int minimumRent = await _rpcClient!
          .getMinimumBalanceForRentExemption(
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
      Logging.instance.e(
        "Error getting balance in solana_wallet.dart: ",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> updateChainHeight() async {
    try {
      checkClient();

      final int blockHeight = await _rpcClient?.getSlot() ?? 0;
      // TODO [prio=low]: Revisit null condition.

      await info.updateCachedChainHeight(
        newHeight: blockHeight,
        isar: mainDB.isar,
      );
    } catch (e, s) {
      Logging.instance.e(
        "Error occurred in solana_wallet.dart while getting"
        " chain height for solana: $e\n$s",
      );
    }
  }

  @override
  Future<void> updateNode() async {
    _solNode =
        NodeService(
          secureStorageInterface: secureStorageInterface,
        ).getPrimaryNodeFor(currency: info.coin) ??
        info.coin.defaultNode(isPrimary: true);
    await refresh();
  }

  @override
  NodeModel getCurrentNode() {
    _solNode ??=
        NodeService(
          secureStorageInterface: secureStorageInterface,
        ).getPrimaryNodeFor(currency: info.coin) ??
        info.coin.defaultNode(isPrimary: true);

    return _solNode!;
  }

  @override
  Future<void> updateTransactions() async {
    try {
      checkClient();

      final transactionsList = await _rpcClient?.getTransactionsList(
        (await _getKeyPair()).publicKey,
        encoding: Encoding.jsonParsed,
      );

      final myAddress = (await getCurrentReceivingAddress())!;

      if (transactionsList == null) {
        return;
      }

      final txns = <TransactionV2>[];
      int skippedCount = 0;

      for (final tx in transactionsList) {
        try {
          // Skip transactions without metadata.
          if (tx.meta == null) {
            skippedCount++;
            continue;
          }

          if (tx.transaction is! ParsedTransaction) {
            skippedCount++;
            continue;
          }

          final parsedTx = tx.transaction as ParsedTransaction;
          final txid = parsedTx.signatures.isNotEmpty
              ? parsedTx.signatures[0]
              : null;

          if (parsedTx.signatures.length > 1) {
            Logging.instance.w(
              "SOL $walletId found tx with "
              "${parsedTx.signatures.length} signatures",
            );
          }

          if (txid == null) {
            skippedCount++;
            continue;
          }

          final systemTransfers = parsedTx.message.instructions
              .map((e) => e.toJson())
              .where(
                (e) =>
                    e.containsKey("parsed") &&
                    e["program"] == "system" &&
                    e["parsed"]["type"] == "transfer",
              );

          if (systemTransfers.length != 1) {
            Logging.instance.w(
              "SOL $walletId found tx with "
              "${systemTransfers.length} system transfer! Skipping...",
            );
            skippedCount++;
            continue;
          }
          final transfer = systemTransfers.first;
          final lamports = BigInt.parse(
            transfer["parsed"]["info"]["lamports"].toString(),
          );
          final senderAddress = transfer["parsed"]["info"]["source"] as String;
          final receiverAddress =
              transfer["parsed"]["info"]["destination"] as String;

          final isar.TransactionType txType;

          if ((senderAddress == myAddress.value) &&
              (receiverAddress == senderAddress)) {
            txType = isar.TransactionType.sentToSelf;
          } else if (senderAddress == myAddress.value) {
            txType = isar.TransactionType.outgoing;
          } else if (receiverAddress == myAddress.value) {
            txType = isar.TransactionType.incoming;
          } else {
            // probably should never get here? If so, then this fragile parsing
            // is broken which isn't surprising...
            txType = isar.TransactionType.unknown;
          }

          // check for memo
          final memos = parsedTx.message.instructions
              .map((e) => e.toJson())
              .where(
                (e) => e["parsed"] is String && e["program"] == "spl-memo",
              );
          final String? memo = memos.isEmpty
              ? null
              : memos.first["parsed"] as String;

          // Create TransactionV2 object.
          final txn = TransactionV2(
            walletId: walletId,
            blockHash: null,
            hash: txid,
            txid: txid,
            timestamp:
                tx.blockTime ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
            height: tx.slot,
            inputs: [
              InputV2.isarCantDoRequiredInDefaultConstructor(
                scriptSigHex: null,
                scriptSigAsm: null,
                sequence: null,
                outpoint: null,
                addresses: [senderAddress],
                valueStringSats: lamports.toString(),
                witness: null,
                innerRedeemScriptAsm: null,
                coinbase: null,
                walletOwns: senderAddress == myAddress.value,
              ),
            ],
            outputs: [
              OutputV2.isarCantDoRequiredInDefaultConstructor(
                scriptPubKeyHex: "00",
                valueStringSats: lamports.toString(),
                addresses: [receiverAddress],
                walletOwns: receiverAddress == myAddress.value,
              ),
            ],
            version: tx.version?.version?.toInt() ?? -1,
            type: txType,
            subType: isar.TransactionSubType.none,
            otherData: jsonEncode({
              TxV2OdKeys.overrideFee: tx.meta!.fee.toString(),
              if (memo != null) TxV2OdKeys.memo: memo,
            }),
          );

          txns.add(txn);
        } catch (e, s) {
          Logging.instance.w(
            "$runtimeType updateTransactions: Failed to parse transaction",
            error: e,
            stackTrace: s,
          );
          skippedCount++;
          continue;
        }
      }

      // Persist all transactions if any were parsed.
      if (txns.isNotEmpty) {
        await mainDB.updateOrPutTransactionV2s(txns);
        Logging.instance.i(
          "$runtimeType updateTransactions: Synced ${txns.length} transactions (skipped $skippedCount)",
        );
      }
    } on NodeTorMismatchConfigException {
      rethrow;
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType updateTransactions failed: ",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<bool> updateUTXOs() async {
    return false;
  }

  Future<void> updateSolanaTokens(List<String> mintAddresses) async {
    await info.updateSolanaCustomTokenMintAddresses(
      newMintAddresses: mintAddresses,
      isar: mainDB.isar,
    );

    GlobalEventBus.instance.fire(
      UpdatedInBackgroundEvent(
        "Solana custom tokens updated for: $walletId ${info.name}",
        walletId,
      ),
    );
  }

  void checkClient() {
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

    if (AppConfig.hasFeature(AppFeature.tor) && prefs.useTor) {
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
