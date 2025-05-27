import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:socks5_proxy/socks.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as stellar;

import '../../../exceptions/wallet/node_tor_mismatch_config_exception.dart';
import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../services/event_bus/events/global/tor_connection_status_changed_event.dart';
import '../../../services/event_bus/events/global/tor_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
import '../../../services/tor_service.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/fee_rate_type_enum.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/test_stellar_node_connection.dart';
import '../../../utilities/tor_plain_net_option_enum.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_wallet.dart';

class StellarWallet extends Bip39Wallet<Stellar> {
  StellarWallet(CryptoCurrencyNetwork network) : super(Stellar(network)) {
    final bus = GlobalEventBus.instance;

    // Listen for tor status changes.
    _torStatusListener = bus.on<TorConnectionStatusChangedEvent>().listen((
      event,
    ) async {
      switch (event.newStatus) {
        case TorConnectionStatus.connecting:
          if (!_torConnectingLock.isLocked) {
            await _torConnectingLock.acquire();
          }
          _requireMutex = true;
          break;

        case TorConnectionStatus.connected:
        case TorConnectionStatus.disconnected:
          if (_torConnectingLock.isLocked) {
            _torConnectingLock.release();
          }
          _requireMutex = false;
          break;
      }
    });

    // Listen for tor preference changes.
    _torPreferenceListener = bus.on<TorPreferenceChangedEvent>().listen((
      event,
    ) async {
      _stellarSdk?.httpClient.close();
      _stellarSdk = null;
    });
  }

  void _hackedCheck() {
    final node = getCurrentNode();
    final netOption = TorPlainNetworkOption.fromNodeData(
      node.torEnabled,
      node.clearnetEnabled,
    );

    if (prefs.useTor) {
      if (netOption == TorPlainNetworkOption.clear) {
        _stellarSdk?.httpClient.close();
        _stellarSdk = null;
        throw NodeTorMismatchConfigException(
          message: "TOR enabled but node set to clearnet only",
        );
      }
    } else {
      if (netOption == TorPlainNetworkOption.tor) {
        _stellarSdk?.httpClient.close();
        _stellarSdk = null;
        throw NodeTorMismatchConfigException(
          message: "TOR off but node set to TOR only",
        );
      }
    }
  }

  Future<stellar.StellarSDK> get stellarSdk async {
    if (_requireMutex) {
      await _torConnectingLock.protect(() async {
        _hackedCheck();
        _stellarSdk ??= _getFreshSdk();
      });
    } else {
      _hackedCheck();
      _stellarSdk ??= _getFreshSdk();
    }
    return _stellarSdk!;
  }

  stellar.Network get stellarNetwork {
    switch (cryptoCurrency.network) {
      case CryptoCurrencyNetwork.main:
        return stellar.Network.PUBLIC;
      case CryptoCurrencyNetwork.test:
        return stellar.Network.TESTNET;
      default:
        throw Exception("Unsupported network");
    }
  }

  // ============== Private ====================================================
  // add finalizer to cancel stream subscription when all references to an
  // instance of this becomes inaccessible
  final _ = Finalizer<StellarWallet>((p0) {
    p0._torPreferenceListener?.cancel();
    p0._torStatusListener?.cancel();
  });

  StreamSubscription<TorConnectionStatusChangedEvent>? _torStatusListener;
  StreamSubscription<TorPreferenceChangedEvent>? _torPreferenceListener;

  final Mutex _torConnectingLock = Mutex();
  bool _requireMutex = false;

  stellar.StellarSDK? _stellarSdk;

  Future<BigInt> _getBaseFee() async {
    final fees = await (await stellarSdk).feeStats.execute();
    return BigInt.parse(fees.lastLedgerBaseFee);
  }

  stellar.StellarSDK _getFreshSdk() {
    final currentNode = getCurrentNode();
    HttpClient? _httpClient;

    if (prefs.useTor) {
      final ({InternetAddress host, int port}) proxyInfo =
          TorService.sharedInstance.getProxyInfo();

      _httpClient = HttpClient();
      SocksTCPClient.assignToHttpClient(_httpClient, [
        ProxySettings(proxyInfo.host, proxyInfo.port),
      ]);
    }

    return stellar.StellarSDK(
      "${currentNode.host}:${currentNode.port}",
      httpClient: _httpClient,
    );
  }

  Future<bool> _accountExists(String accountId) async {
    bool exists = false;

    try {
      final receiverAccount = await (await stellarSdk).accounts.account(
        accountId,
      );
      if (receiverAccount.accountId != "") {
        exists = true;
      }
    } catch (e, s) {
      Logging.instance.e(
        "Error getting account  ${e.toString()} - ${s.toString()}",
        error: e,
        stackTrace: s,
      );
    }
    return exists;
  }

  Future<stellar.Wallet> _getStellarWallet() async {
    return await stellar.Wallet.from(
      await getMnemonic(),
      passphrase: await getMnemonicPassphrase(),
    );
  }

  Future<stellar.KeyPair> _getSenderKeyPair({required int index}) async {
    final wallet = await _getStellarWallet();
    return await wallet.getKeyPair(index: index);
  }

  Future<Address> _fetchStellarAddress({required int index}) async {
    final stellar.KeyPair keyPair = await _getSenderKeyPair(index: index);
    final String address = keyPair.accountId;

    return Address(
      walletId: walletId,
      value: address,
      publicKey: keyPair.publicKey,
      derivationIndex: index,
      derivationPath: null,
      type: AddressType.stellar,
      subType: AddressSubType.receiving,
    );
  }

  // ============== Overrides ==================================================

  @override
  int get isarTransactionVersion => 2;

  @override
  FilterOperation? get changeAddressFilterOperation =>
      FilterGroup.and(standardChangeAddressFilters);

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    try {
      final address = await getCurrentReceivingAddress();
      if (address == null) {
        await mainDB.updateOrPutAddresses([
          await _fetchStellarAddress(index: 0),
        ]);
      }
    } catch (e, s) {
      // do nothing, still allow user into wallet
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
      if (txData.recipients?.length != 1) {
        throw Exception("Missing recipient");
      }

      final feeRate = txData.feeRateType;
      BigInt fee = BigInt.from(1000);
      if (feeRate is FeeRateType) {
        final theFees = await fees;
        switch (feeRate) {
          case FeeRateType.fast:
            fee = theFees.fast;
          case FeeRateType.slow:
            fee = theFees.slow;
          case FeeRateType.average:
          default:
            fee = theFees.medium;
        }
      }

      return txData.copyWith(
        fee: Amount(
          rawValue: fee,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
      );
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType prepareSend() failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    final senderKeyPair = await _getSenderKeyPair(index: 0);
    final sender = await (await stellarSdk).accounts.account(
      senderKeyPair.accountId,
    );

    final address = txData.recipients!.first.address;
    final amountToSend = txData.recipients!.first.amount;
    final memo = txData.memo;

    //First check if account exists, can be skipped, but if the account does not exist,
    // the transaction fee will be charged when the transaction fails.
    final validAccount = await _accountExists(address);
    final stellar.TransactionBuilder transactionBuilder;

    if (!validAccount) {
      //Fund the account, user must ensure account is correct
      final createAccBuilder = stellar.CreateAccountOperationBuilder(
        address,
        amountToSend.decimal.toString(),
      );
      transactionBuilder = stellar.TransactionBuilder(
        sender,
      ).addOperation(createAccBuilder.build());
    } else {
      transactionBuilder = stellar.TransactionBuilder(sender).addOperation(
        stellar.PaymentOperationBuilder(
          address,
          stellar.Asset.NATIVE,
          amountToSend.decimal.toString(),
        ).build(),
      );
    }

    if (memo != null) {
      transactionBuilder.addMemo(stellar.MemoText(memo));
    }

    final transaction = transactionBuilder.build();

    transaction.sign(senderKeyPair, stellarNetwork);
    try {
      final response = await (await stellarSdk).submitTransaction(transaction);
      if (!response.success) {
        throw Exception(
          "${response.extras?.resultCodes?.transactionResultCode}"
          " ::: ${response.extras?.resultCodes?.operationsResultCodes}",
        );
      }

      return txData.copyWith(txHash: response.hash!, txid: response.hash!);
    } catch (e, s) {
      Logging.instance.e("Error sending TX $e - $s", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
    final baseFee = await _getBaseFee();
    return Amount(
      rawValue: baseFee,
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }

  @override
  Future<FeeObject> get fees async {
    final fee = await _getBaseFee();
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
    final currentNode = getCurrentNode();
    return await testStellarNodeConnection(currentNode.host, currentNode.port);
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    await refreshMutex.protect(() async {
      if (isRescan) {
        await mainDB.deleteWalletBlockchainData(walletId);
      }

      await mainDB.updateOrPutAddresses([await _fetchStellarAddress(index: 0)]);
    });

    if (isRescan) {
      unawaited(refresh());
    }
  }

  @override
  Future<void> updateBalance() async {
    try {
      stellar.AccountResponse accountResponse;

      try {
        accountResponse = await (await stellarSdk).accounts
            .account((await getCurrentReceivingAddress())!.value)
            .onError((error, stackTrace) => throw error!);
      } catch (e) {
        if (e is stellar.ErrorResponse &&
            e.body.contains(
              "The resource at the url requested was not found.  "
              "This usually occurs for one of two reasons:  "
              "The url requested is not valid, or no data in our database "
              "could be found with the parameters provided.",
            )) {
          // probably just doesn't have any history yet or whatever stellar needs
          return;
        } else {
          Logging.instance.w(
            "$runtimeType ${info.name} $walletId "
            "failed to fetch account to updateBalance",
          );
          rethrow;
        }
      }

      for (final stellar.Balance balance in accountResponse.balances) {
        switch (balance.assetType) {
          case stellar.Asset.TYPE_NATIVE:
            final swBalance = Balance(
              total: Amount(
                rawValue: BigInt.from(float.parse(balance.balance) * 10000000),
                fractionDigits: cryptoCurrency.fractionDigits,
              ),
              spendable: Amount(
                rawValue: BigInt.from(float.parse(balance.balance) * 10000000),
                fractionDigits: cryptoCurrency.fractionDigits,
              ),
              blockedTotal: Amount(
                rawValue: BigInt.from(0),
                fractionDigits: cryptoCurrency.fractionDigits,
              ),
              pendingSpendable: Amount(
                rawValue: BigInt.from(0),
                fractionDigits: cryptoCurrency.fractionDigits,
              ),
            );
            await info.updateBalance(newBalance: swBalance, isar: mainDB.isar);
        }
      }
    } catch (e, s) {
      Logging.instance.w(
        "$runtimeType ${info.name} $walletId "
        "updateBalance() failed: $e\n$s",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateChainHeight() async {
    try {
      final height = await (await stellarSdk).ledgers
          .order(stellar.RequestBuilderOrder.DESC)
          .limit(1)
          .execute()
          .then((value) => value.records!.first.sequence);
      await info.updateCachedChainHeight(newHeight: height, isar: mainDB.isar);
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType updateChainHeight() failed: ",
        error: e,
        stackTrace: s,
      );

      rethrow;
    }
  }

  @override
  Future<void> updateNode() async {
    _stellarSdk?.httpClient.close();
    _stellarSdk = _getFreshSdk();
  }

  @override
  Future<void> updateTransactions() async {
    try {
      final myAddress = (await getCurrentReceivingAddress())!;

      final List<TransactionV2> transactionList = [];
      stellar.Page<stellar.OperationResponse> payments;
      try {
        payments =
            await (await stellarSdk).payments
                .forAccount(myAddress.value)
                .order(stellar.RequestBuilderOrder.DESC)
                .execute();
      } catch (e) {
        if (e is stellar.ErrorResponse &&
            e.body.contains(
              "The resource at the url requested was not found.  "
              "This usually occurs for one of two reasons:  "
              "The url requested is not valid, or no data in our database "
              "could be found with the parameters provided.",
            )) {
          // probably just doesn't have any history yet or whatever stellar needs
          return;
        } else {
          Logging.instance.w(
            "Stellar ${info.name} $walletId failed to fetch transactions",
          );
          rethrow;
        }
      }
      for (final stellar.OperationResponse response in payments.records!) {
        // PaymentOperationResponse por;
        if (response is stellar.PaymentOperationResponse) {
          final por = response;

          final addressTo = por.to!.accountId;
          final addressFrom = por.from!.accountId;

          final TransactionType type;
          if (addressFrom == myAddress.value) {
            if (addressTo == myAddress.value) {
              type = TransactionType.sentToSelf;
            } else {
              type = TransactionType.outgoing;
            }
          } else {
            type = TransactionType.incoming;
          }
          final amount = Amount(
            rawValue: BigInt.parse(
              float
                  .parse(por.amount!)
                  .toStringAsFixed(cryptoCurrency.fractionDigits)
                  .replaceAll(".", ""),
            ),
            fractionDigits: cryptoCurrency.fractionDigits,
          );

          // hack eth tx data into inputs and outputs
          final List<OutputV2> outputs = [];
          final List<InputV2> inputs = [];

          final OutputV2 output =
              OutputV2.isarCantDoRequiredInDefaultConstructor(
                scriptPubKeyHex: "00",
                valueStringSats: amount.raw.toString(),
                addresses: [addressTo],
                walletOwns: addressTo == myAddress.value,
              );
          final InputV2 input = InputV2.isarCantDoRequiredInDefaultConstructor(
            scriptSigHex: null,
            scriptSigAsm: null,
            sequence: null,
            outpoint: null,
            addresses: [addressFrom],
            valueStringSats: amount.raw.toString(),
            witness: null,
            innerRedeemScriptAsm: null,
            coinbase: null,
            walletOwns: addressFrom == myAddress.value,
          );

          outputs.add(output);
          inputs.add(input);

          int fee = 0;
          int height = 0;
          //Query the transaction linked to the payment,
          // por.transaction returns a null sometimes
          final stellar.TransactionResponse tx = await (await stellarSdk)
              .transactions
              .transaction(por.transactionHash!);

          if (tx.hash.isNotEmpty) {
            fee = tx.feeCharged!;
            height = tx.ledger;
          }

          final otherData = {
            "overrideFee":
                Amount(
                  rawValue: BigInt.from(fee),
                  fractionDigits: cryptoCurrency.fractionDigits,
                ).toJsonString(),
          };

          final theTransaction = TransactionV2(
            walletId: walletId,
            blockHash: "",
            hash: por.transactionHash!,
            txid: por.transactionHash!,
            timestamp:
                DateTime.parse(por.createdAt!).millisecondsSinceEpoch ~/ 1000,
            height: height,
            inputs: inputs,
            outputs: outputs,
            version: -1,
            type: type,
            subType: TransactionSubType.none,
            otherData: jsonEncode(otherData),
          );

          transactionList.add(theTransaction);
        } else if (response is stellar.CreateAccountOperationResponse) {
          final caor = response;
          final TransactionType type;
          if (caor.sourceAccount == myAddress.value) {
            type = TransactionType.outgoing;
          } else {
            type = TransactionType.incoming;
          }
          final amount = Amount(
            rawValue: BigInt.parse(
              float
                  .parse(caor.startingBalance!)
                  .toStringAsFixed(cryptoCurrency.fractionDigits)
                  .replaceAll(".", ""),
            ),
            fractionDigits: cryptoCurrency.fractionDigits,
          );

          // hack eth tx data into inputs and outputs
          final List<OutputV2> outputs = [];
          final List<InputV2> inputs = [];

          final OutputV2
          output = OutputV2.isarCantDoRequiredInDefaultConstructor(
            scriptPubKeyHex: "00",
            valueStringSats: amount.raw.toString(),
            addresses: [
              // this is what the previous code was doing and I don't think its correct
              caor.sourceAccount!,
            ],
            walletOwns: caor.sourceAccount! == myAddress.value,
          );
          final InputV2 input = InputV2.isarCantDoRequiredInDefaultConstructor(
            scriptSigHex: null,
            scriptSigAsm: null,
            sequence: null,
            outpoint: null,
            addresses: [
              // this is what the previous code was doing and I don't think its correct
              caor.sourceAccount!,
            ],
            valueStringSats: amount.raw.toString(),
            witness: null,
            innerRedeemScriptAsm: null,
            coinbase: null,
            walletOwns: caor.sourceAccount! == myAddress.value,
          );

          outputs.add(output);
          inputs.add(input);

          int fee = 0;
          int height = 0;
          final tx = await (await stellarSdk).transactions.transaction(
            caor.transactionHash!,
          );
          if (tx.hash.isNotEmpty) {
            fee = tx.feeCharged!;
            height = tx.ledger;
          }

          final otherData = {
            "overrideFee":
                Amount(
                  rawValue: BigInt.from(fee),
                  fractionDigits: cryptoCurrency.fractionDigits,
                ).toJsonString(),
          };

          final theTransaction = TransactionV2(
            walletId: walletId,
            blockHash: "",
            hash: caor.transactionHash!,
            txid: caor.transactionHash!,
            timestamp:
                DateTime.parse(caor.createdAt!).millisecondsSinceEpoch ~/ 1000,
            height: height,
            inputs: inputs,
            outputs: outputs,
            version: -1,
            type: type,
            subType: TransactionSubType.none,
            otherData: jsonEncode(otherData),
          );

          transactionList.add(theTransaction);
        }
      }

      await mainDB.updateOrPutTransactionV2s(transactionList);
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from updateTransactions(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<bool> updateUTXOs() async {
    // do nothing for stellar
    return false;
  }
}
