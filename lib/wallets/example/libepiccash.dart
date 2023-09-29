import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_libepiccash/epic_cash.dart' as lib_epiccash;
import 'package:mutex/mutex.dart';

///
/// Wrapped up calls to flutter_libepiccash.
///
/// Should all be static calls (no state stored in this class)
///
abstract class LibEpiccash {
  static final Mutex _mutex = Mutex();

  ///
  /// Check if [address] is a valid epiccash address according to libepiccash
  ///
  static bool validateSendAddress({required String address}) {
    final String validate = lib_epiccash.validateSendAddress(address);
    if (int.parse(validate) == 1) {
      // Check if address contains a domain
      if (address.contains("@")) {
        return true;
      }
      return false;
    } else {
      return false;
    }
  }

  ///
  /// Fetch the mnemonic For a new wallet (Only used in the example app)
  ///
  // TODO: ensure the above documentation comment is correct
  // TODO: ensure this will always return the mnemonic. If not, this function should throw an exception
  //Function is used in _getMnemonicList()
  static String getMnemonic() {
    try {
      String mnemonic = lib_epiccash.walletMnemonic();
      if (mnemonic.isEmpty) {
        throw Exception("Error getting mnemonic, returned empty string");
      }
      return mnemonic;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Private function wrapper for compute
  static Future<String> _initializeWalletWrapper(
    ({
      String config,
      String mnemonic,
      String password,
      String name,
    }) data,
  ) async {
    final String initWalletStr = lib_epiccash.initWallet(
      data.config,
      data.mnemonic,
      data.password,
      data.name,
    );
    return initWalletStr;
  }

  ///
  /// Create a new epiccash wallet.
  ///
  // TODO: Complete/modify the documentation comment above
  // TODO: Should return a void future. On error this function should throw and exception
  static Future<String> initializeNewWallet({
    required String config,
    required String mnemonic,
    required String password,
    required String name,
  }) async {
    try {
      return await compute(
        _initializeWalletWrapper,
        (
          config: config,
          mnemonic: mnemonic,
          password: password,
          name: name,
        ),
      );
    } catch (e) {
      throw ("Error creating new wallet : ${e.toString()}");
    }
  }

  ///
  /// Private function wrapper for wallet balances
  ///
  static Future<String> _walletBalancesWrapper(
    ({String wallet, int refreshFromNode, int minimumConfirmations}) data,
  ) async {
    return lib_epiccash.getWalletInfo(
        data.wallet, data.refreshFromNode, data.minimumConfirmations);
  }

  ///
  /// Get balance information for the currently open wallet
  ///
  static Future<
          ({
            double awaitingFinalization,
            double pending,
            double spendable,
            double total
          })>
      getWalletBalances(
          {required String wallet,
          required int refreshFromNode,
          required int minimumConfirmations}) async {
    try {
      String balances = await compute(_walletBalancesWrapper, (
        wallet: wallet,
        refreshFromNode: refreshFromNode,
        minimumConfirmations: minimumConfirmations,
      ));

      //If balances is valid json return, else return error
      if (balances.toUpperCase().contains("ERROR")) {
        throw Exception(balances);
      }
      var jsonBalances = json.decode(balances);
      //Return balances as record
      ({
        double spendable,
        double pending,
        double total,
        double awaitingFinalization
      }) balancesRecord = (
        spendable: jsonBalances['amount_currently_spendable'],
        pending: jsonBalances['amount_awaiting_finalization'],
        total: jsonBalances['total'],
        awaitingFinalization: jsonBalances['amount_awaiting_finalization'],
      );
      return balancesRecord;
    } catch (e) {
      throw ("Error getting wallet info : ${e.toString()}");
    }
  }

  ///
  /// Private function wrapper for scanning output function
  ///
  static Future<String> _scanOutputsWrapper(
    ({String wallet, int startHeight, int numberOfBlocks}) data,
  ) async {
    return lib_epiccash.scanOutPuts(
      data.wallet,
      data.startHeight,
      data.numberOfBlocks,
    );
  }

  ///
  /// Scan Epic outputs
  ///
  static Future<String> scanOutputs({
    required String wallet,
    required int startHeight,
    required int numberOfBlocks,
  }) async {
    try {
      return await compute(_scanOutputsWrapper, (
        wallet: wallet,
        startHeight: startHeight,
        numberOfBlocks: numberOfBlocks,
      ));
    } catch (e) {
      throw ("Error getting scanning outputs : ${e.toString()}");
    }
  }

  ///
  /// Private function wrapper for create transactions
  ///
  static Future<String> _createTransactionWrapper(
    ({
      String wallet,
      int amount,
      String address,
      int secretKeyIndex,
      String epicboxConfig,
      int minimumConfirmations,
      String note,
    }) data,
  ) async {
    return lib_epiccash.createTransaction(
        data.wallet,
        data.amount,
        data.address,
        data.secretKeyIndex,
        data.epicboxConfig,
        data.minimumConfirmations,
        data.note);
  }

  ///
  /// Create an Epic transaction
  ///
  static Future<({String slateId, String commitId})> createTransaction({
    required String wallet,
    required int amount,
    required String address,
    required int secretKeyIndex,
    required String epicboxConfig,
    required int minimumConfirmations,
    required String note,
  }) async {
    try {
      String result =  await compute(_createTransactionWrapper, (
        wallet: wallet,
        amount: amount,
        address: address,
        secretKeyIndex: secretKeyIndex,
        epicboxConfig: epicboxConfig,
        minimumConfirmations: minimumConfirmations,
        note: note,
      ));

      if (result.toUpperCase().contains("ERROR")) {
        throw Exception("Error creating transaction ${result.toString()}");
      }

      //Decode sent tx and return Slate Id
      final slate0 = jsonDecode(result);
      final slate = jsonDecode(slate0[0] as String);
      final part1 = jsonDecode(slate[0] as String);
      final part2 = jsonDecode(slate[1] as String);

      ({String slateId, String commitId}) data = (
        slateId: part1[0]['tx_slate_id'],
        commitId: part2['tx']['body']['outputs'][0]['commit'],
      );

      return data;
    } catch (e) {
      throw ("Error creating epic transaction : ${e.toString()}");
    }
  }

  ///
  /// Private function wrapper for get transactions
  ///
  static Future<String> _getTransactionsWrapper(
    ({
      String wallet,
      int refreshFromNode,
    }) data,
  ) async {
    return lib_epiccash.getTransactions(
      data.wallet,
      data.refreshFromNode,
    );
  }

  ///
  ///
  ///
  static Future<String> getTransaction({
    required String wallet,
    required int refreshFromNode,
  }) async {
    try {
      return await compute(_getTransactionsWrapper, (
        wallet: wallet,
        refreshFromNode: refreshFromNode,
      ));
    } catch (e) {
      throw ("Error getting epic transaction : ${e.toString()}");
    }
  }

  ///
  /// Private function for cancel transaction function
  ///
  static Future<String> _cancelTransactionWrapper(
    ({
      String wallet,
      String transactionId,
    }) data,
  ) async {
    return lib_epiccash.cancelTransaction(
      data.wallet,
      data.transactionId,
    );
  }

  ///
  /// Cancel current Epic transaction
  ///
  static Future<String> cancelTransaction({
    required String wallet,
    required String transactionId,
  }) async {
    try {
      return await compute(_cancelTransactionWrapper, (
        wallet: wallet,
        transactionId: transactionId,
      ));
    } catch (e) {
      throw ("Error canceling epic transaction : ${e.toString()}");
    }
  }

  static Future<int> _chainHeightWrapper(
    ({
      String config,
    }) data,
  ) async {
    return lib_epiccash.getChainHeight(data.config);
  }

  static Future<int> getChainHeight({
    required String config,
  }) async {
    try {
      return await compute(_chainHeightWrapper, (config: config,));
    } catch (e) {
      throw ("Error getting chain height : ${e.toString()}");
    }
  }

  ///
  /// Private function for address info function
  ///
  static Future<String> _addressInfoWrapper(
    ({
      String wallet,
      int index,
      String epicboxConfig,
    }) data,
  ) async {
    return lib_epiccash.getAddressInfo(
      data.wallet,
      data.index,
      data.epicboxConfig,
    );
  }

  ///
  /// get Epic address info
  ///
  static Future<String> getAddressInfo({
    required String wallet,
    required int index,
    required String epicboxConfig,
  }) async {
    try {
      return await compute(_addressInfoWrapper, (
        wallet: wallet,
        index: index,
        epicboxConfig: epicboxConfig,
      ));
    } catch (e) {
      throw ("Error getting address info : ${e.toString()}");
    }
  }

  ///
  /// Private function for getting transaction fees
  ///
  static Future<String> _transactionFeesWrapper(
    ({
      String wallet,
      int amount,
      int minimumConfirmations,
    }) data,
  ) async {
    return lib_epiccash.getTransactionFees(
      data.wallet,
      data.amount,
      data.minimumConfirmations,
    );
  }

  ///
  /// get transaction fees for Epic
  ///
  static Future<({int fee, bool strategyUseAll, int total})>
      getTransactionFees({
    required String wallet,
    required int amount,
    required int minimumConfirmations,
    required int available,
  }) async {
    try {
      String fees = await compute(_transactionFeesWrapper, (
        wallet: wallet,
        amount: amount,
        minimumConfirmations: minimumConfirmations,
      ));

      if (available == amount) {
        if (fees.contains("Required")) {
          var splits = fees.split(" ");
          Decimal required = Decimal.zero;
          Decimal available = Decimal.zero;
          for (int i = 0; i < splits.length; i++) {
            var word = splits[i];
            if (word == "Required:") {
              required = Decimal.parse(splits[i + 1].replaceAll(",", ""));
            } else if (word == "Available:") {
              available = Decimal.parse(splits[i + 1].replaceAll(",", ""));
            }
          }
          int largestSatoshiFee =
              ((required - available) * Decimal.fromInt(100000000))
                  .toBigInt()
                  .toInt();
          var amountSending = amount - largestSatoshiFee;
          //Get fees for this new amount
          ({
            String wallet,
            int amount,
          }) data = (wallet: wallet, amount: amountSending);
          fees = await compute(_transactionFeesWrapper, (
            wallet: wallet,
            amount: amountSending,
            minimumConfirmations: minimumConfirmations,
          ));
        }
      }

      if (fees.toUpperCase().contains("ERROR")) {
        //Check if the error is an
        //Throw the returned error
        throw Exception(fees);
      }
      var decodedFees = json.decode(fees);
      var feeItem = decodedFees[0];
      ({
        bool strategyUseAll,
        int total,
        int fee,
      }) feeRecord = (
        strategyUseAll: feeItem['selection_strategy_is_use_all'],
        total: feeItem['total'],
        fee: feeItem['fee'],
      );
      return feeRecord;
    } catch (e) {
      throw (e.toString());
    }
  }

  ///
  /// Private function wrapper for recover wallet function
  ///
  static Future<String> _recoverWalletWrapper(
    ({
      String config,
      String password,
      String mnemonic,
      String name,
    }) data,
  ) async {
    return lib_epiccash.recoverWallet(
      data.config,
      data.password,
      data.mnemonic,
      data.name,
    );
  }

  ///
  /// Recover an Epic wallet using a mnemonic
  ///
  static Future<void> recoverWallet(
      {required String config,
      required String password,
      required String mnemonic,
      required String name}) async {
    try {
      await compute(_recoverWalletWrapper, (
        config: config,
        password: password,
        mnemonic: mnemonic,
        name: name,
      ));
    } catch (e) {
      throw (e.toString());
    }
  }

  ///
  /// Private function wrapper for delete wallet function
  ///
  static Future<String> _deleteWalletWrapper(
    ({
      String wallet,
      String config,
    }) data,
  ) async {
    return lib_epiccash.deleteWallet(
      data.wallet,
      data.config,
    );
  }

  ///
  /// Delete an Epic wallet
  ///
  static Future<String> deleteWallet({
    required String wallet,
    required String config,
  }) async {
    try {
      return await compute(_deleteWalletWrapper, (
        wallet: wallet,
        config: config,
      ));
    } catch (e) {
      throw ("Error deleting wallet : ${e.toString()}");
    }
  }

  ///
  /// Private function wrapper for open wallet function
  ///
  static Future<String> _openWalletWrapper(
    ({
      String config,
      String password,
    }) data,
  ) async {
    return lib_epiccash.openWallet(
      data.config,
      data.password,
    );
  }

  ///
  /// Open an Epic wallet
  ///
  static Future<String> openWallet({
    required String config,
    required String password,
  }) async {
    try {
      return await compute(_openWalletWrapper, (
        config: config,
        password: password,
      ));
    } catch (e) {
      throw ("Error opening wallet : ${e.toString()}");
    }
  }

  ///
  /// Private function for txHttpSend function
  ///
  static Future<String> _txHttpSendWrapper(
    ({
      String wallet,
      int selectionStrategyIsAll,
      int minimumConfirmations,
      String message,
      int amount,
      String address,
    }) data,
  ) async {
    return lib_epiccash.txHttpSend(
      data.wallet,
      data.selectionStrategyIsAll,
      data.minimumConfirmations,
      data.message,
      data.amount,
      data.address,
    );
  }

  ///
  ///
  ///
  static Future<String> txHttpSend({
    required String wallet,
    required int selectionStrategyIsAll,
    required int minimumConfirmations,
    required String message,
    required int amount,
    required String address,
  }) async {
    try {
      return await compute(_txHttpSendWrapper, (
        wallet: wallet,
        selectionStrategyIsAll: selectionStrategyIsAll,
        minimumConfirmations: minimumConfirmations,
        message: message,
        amount: amount,
        address: address,
      ));
    } catch (e) {
      throw ("Error sending tx HTTP : ${e.toString()}");
    }
  }
}
