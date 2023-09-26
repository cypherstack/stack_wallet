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
  // TODO: probably remove this as we don't use it in stack wallet. We store the mnemonic separately
  static String getMnemonic() {
    try {
      return lib_epiccash.walletMnemonic();
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
  static Future<void> initializeNewWallet({
    required String config,
    required String mnemonic,
    required String password,
    required String name,
  }) async {
    try {
      await compute(
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
  static Future<String> getWalletBalances(
      {required String wallet,
      required int refreshFromNode,
      required int minimumConfirmations}) async {
    try {
      String balances = await compute(_walletBalancesWrapper, (
        wallet: wallet,
        refreshFromNode: refreshFromNode,
        minimumConfirmations: minimumConfirmations,
      ));
      return balances;
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
  static Future<void> scanOutputs({
    required String wallet,
    required int startHeight,
    required int numberOfBlocks,
  }) async {
    try {
      await compute(_scanOutputsWrapper, (
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
      int secretKey,
      String epicboxConfig,
      int minimumConfirmations,
      String note,
    }) data,
  ) async {
    return lib_epiccash.createTransaction(
        data.wallet,
        data.amount,
        data.address,
        data.secretKey,
        data.epicboxConfig,
        data.minimumConfirmations,
        data.note);
  }

  ///
  /// Create an Epic transaction
  ///
  static Future<void> createTransaction({
    required String wallet,
    required int amount,
    required String address,
    required int secretKey,
    required String epicboxConfig,
    required int minimumConfirmations,
    required String note,
  }) async {
    try {
      await compute(_createTransactionWrapper, (
        wallet: wallet,
        amount: amount,
        address: address,
        secretKey: secretKey,
        epicboxConfig: epicboxConfig,
        minimumConfirmations: minimumConfirmations,
        note: note,
      ));
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
  static Future<void> getTransaction({
    required String wallet,
    required int refreshFromNode,
  }) async {
    try {
      await compute(_getTransactionsWrapper, (
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
  ///
  ///
  static Future<void> cancelTransaction({
    required String wallet,
    required String transactionId,
  }) async {
    try {
      await compute(_cancelTransactionWrapper, (
        wallet: wallet,
        transactionId: transactionId,
      ));
    } catch (e) {
      throw ("Error canceling epic transaction : ${e.toString()}");
    }
  }

  static Future<String> addressInfoWrapper(
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

  static Future<void> getAddressInfo({
    required String wallet,
    required int index,
    required String epicboxConfig,
  }) async {
    try {} catch (e) {}
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
      throw ("Error recovering wallet : ${e.toString()}");
    }
  }
}
