// import 'dart:async';
//
// import 'package:bip39/bip39.dart' as bip39;
// import 'package:isar/isar.dart';
// import 'package:stackwallet/db/isar/main_db.dart';
// import 'package:stackwallet/models/balance.dart' as SWBalance;
// import 'package:stackwallet/models/isar/models/blockchain_data/address.dart'
//     as SWAddress;
// import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart'
//     as SWTransaction;
// import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
// import 'package:stackwallet/models/node_model.dart';
// import 'package:stackwallet/models/paymint/fee_object_model.dart';
// import 'package:stackwallet/services/coins/coin_service.dart';
// import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
// import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
// import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
// import 'package:stackwallet/services/event_bus/global_event_bus.dart';
// import 'package:stackwallet/services/mixins/wallet_cache.dart';
// import 'package:stackwallet/services/mixins/wallet_db.dart';
// import 'package:stackwallet/services/node_service.dart';
// import 'package:stackwallet/services/transaction_notification_tracker.dart';
// import 'package:stackwallet/utilities/amount/amount.dart';
// import 'package:stackwallet/utilities/constants.dart';
// import 'package:stackwallet/utilities/default_nodes.dart';
// import 'package:stackwallet/utilities/enums/coin_enum.dart';
// import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
// import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
// import 'package:stackwallet/utilities/logger.dart';
// import 'package:stackwallet/utilities/prefs.dart';
// import 'package:stackwallet/utilities/test_stellar_node_connection.dart';
// import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
// import 'package:tuple/tuple.dart';
//
// const int MINIMUM_CONFIRMATIONS = 1;
//
// class StellarWallet extends CoinServiceAPI with WalletCache, WalletDB {
//   late StellarSDK stellarSdk;
//   late Network stellarNetwork;
//
//   StellarWallet({
//     required String walletId,
//     required String walletName,
//     required Coin coin,
//     required TransactionNotificationTracker tracker,
//     required SecureStorageInterface secureStore,
//     MainDB? mockableOverride,
//   }) {
//     txTracker = tracker;
//     _walletId = walletId;
//     _walletName = walletName;
//     _coin = coin;
//     _secureStore = secureStore;
//     initCache(walletId, coin);
//     initWalletDB(mockableOverride: mockableOverride);
//
//     if (coin.isTestNet) {
//       stellarNetwork = Network.TESTNET;
//     } else {
//       stellarNetwork = Network.PUBLIC;
//     }
//
//     _updateNode();
//   }
//
//   Future<void> updateTransactions() async {
//     try {
//       List<Tuple2<SWTransaction.Transaction, SWAddress.Address?>>
//           transactionList = [];
//       Page<OperationResponse> payments;
//       try {
//         payments = await stellarSdk.payments
//             .forAccount(await getAddressSW())
//             .order(RequestBuilderOrder.DESC)
//             .execute()
//             .onError((error, stackTrace) => throw error!);
//       } catch (e) {
//         if (e is ErrorResponse &&
//             e.body.contains("The resource at the url requested was not found.  "
//                 "This usually occurs for one of two reasons:  "
//                 "The url requested is not valid, or no data in our database "
//                 "could be found with the parameters provided.")) {
//           // probably just doesn't have any history yet or whatever stellar needs
//           return;
//         } else {
//           Logging.instance.log(
//             "Stellar $walletName $walletId failed to fetch transactions",
//             level: LogLevel.Warning,
//           );
//           rethrow;
//         }
//       }
//       for (OperationResponse response in payments.records!) {
//         // PaymentOperationResponse por;
//         if (response is PaymentOperationResponse) {
//           PaymentOperationResponse por = response;
//
//           SWTransaction.TransactionType type;
//           if (por.sourceAccount == await getAddressSW()) {
//             type = SWTransaction.TransactionType.outgoing;
//           } else {
//             type = SWTransaction.TransactionType.incoming;
//           }
//           final amount = Amount(
//             rawValue: BigInt.parse(float
//                 .parse(por.amount!)
//                 .toStringAsFixed(coin.decimals)
//                 .replaceAll(".", "")),
//             fractionDigits: coin.decimals,
//           );
//           int fee = 0;
//           int height = 0;
//           //Query the transaction linked to the payment,
//           // por.transaction returns a null sometimes
//           TransactionResponse tx =
//               await stellarSdk.transactions.transaction(por.transactionHash!);
//
//           if (tx.hash.isNotEmpty) {
//             fee = tx.feeCharged!;
//             height = tx.ledger;
//           }
//           var theTransaction = SWTransaction.Transaction(
//             walletId: walletId,
//             txid: por.transactionHash!,
//             timestamp:
//                 DateTime.parse(por.createdAt!).millisecondsSinceEpoch ~/ 1000,
//             type: type,
//             subType: SWTransaction.TransactionSubType.none,
//             amount: 0,
//             amountString: amount.toJsonString(),
//             fee: fee,
//             height: height,
//             isCancelled: false,
//             isLelantus: false,
//             slateId: "",
//             otherData: "",
//             inputs: [],
//             outputs: [],
//             nonce: 0,
//             numberOfMessages: null,
//           );
//           SWAddress.Address? receivingAddress = await _currentReceivingAddress;
//           SWAddress.Address address =
//               type == SWTransaction.TransactionType.incoming
//                   ? receivingAddress!
//                   : SWAddress.Address(
//                       walletId: walletId,
//                       value: por.sourceAccount!,
//                       publicKey:
//                           KeyPair.fromAccountId(por.sourceAccount!).publicKey,
//                       derivationIndex: 0,
//                       derivationPath: null,
//                       type: SWAddress.AddressType.unknown, // TODO: set type
//                       subType: SWAddress.AddressSubType.unknown);
//           Tuple2<SWTransaction.Transaction, SWAddress.Address> tuple =
//               Tuple2(theTransaction, address);
//           transactionList.add(tuple);
//         } else if (response is CreateAccountOperationResponse) {
//           CreateAccountOperationResponse caor = response;
//           SWTransaction.TransactionType type;
//           if (caor.sourceAccount == await getAddressSW()) {
//             type = SWTransaction.TransactionType.outgoing;
//           } else {
//             type = SWTransaction.TransactionType.incoming;
//           }
//           final amount = Amount(
//             rawValue: BigInt.parse(float
//                 .parse(caor.startingBalance!)
//                 .toStringAsFixed(coin.decimals)
//                 .replaceAll(".", "")),
//             fractionDigits: coin.decimals,
//           );
//           int fee = 0;
//           int height = 0;
//           TransactionResponse tx =
//               await stellarSdk.transactions.transaction(caor.transactionHash!);
//           if (tx.hash.isNotEmpty) {
//             fee = tx.feeCharged!;
//             height = tx.ledger;
//           }
//           var theTransaction = SWTransaction.Transaction(
//             walletId: walletId,
//             txid: caor.transactionHash!,
//             timestamp:
//                 DateTime.parse(caor.createdAt!).millisecondsSinceEpoch ~/ 1000,
//             type: type,
//             subType: SWTransaction.TransactionSubType.none,
//             amount: 0,
//             amountString: amount.toJsonString(),
//             fee: fee,
//             height: height,
//             isCancelled: false,
//             isLelantus: false,
//             slateId: "",
//             otherData: "",
//             inputs: [],
//             outputs: [],
//             nonce: 0,
//             numberOfMessages: null,
//           );
//           SWAddress.Address? receivingAddress = await _currentReceivingAddress;
//           SWAddress.Address address =
//               type == SWTransaction.TransactionType.incoming
//                   ? receivingAddress!
//                   : SWAddress.Address(
//                       walletId: walletId,
//                       value: caor.sourceAccount!,
//                       publicKey:
//                           KeyPair.fromAccountId(caor.sourceAccount!).publicKey,
//                       derivationIndex: 0,
//                       derivationPath: null,
//                       type: SWAddress.AddressType.unknown, // TODO: set type
//                       subType: SWAddress.AddressSubType.unknown);
//           Tuple2<SWTransaction.Transaction, SWAddress.Address> tuple =
//               Tuple2(theTransaction, address);
//           transactionList.add(tuple);
//         }
//       }
//       await db.addNewTransactionData(transactionList, walletId);
//     } catch (e, s) {
//       Logging.instance.log(
//           "Exception rethrown from updateTransactions(): $e\n$s",
//           level: LogLevel.Error);
//       rethrow;
//     }
//   }
// }
