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
      throw("Error creating new wallet : ${e.toString()}");
    }
  }

  ///
  /// Private function wrapper for wallet balances
  ///
  static Future<String> _walletBalancesWrapper(
  ({
    String wallet,
    int refreshFromNode,
    int minimumConfirmations
  }) data,) async {
    return  lib_epiccash.getWalletInfo(
        data.wallet, 
        data.refreshFromNode, 
        data.minimumConfirmations
    );
  }

  ///
  /// Get balance information for the currently open wallet
  ///
  static Future<String> getWalletBalances({
    required String wallet,
    required int refreshFromNode,
    required int minimumConfirmations
  }) async {
    try {
      String balances = await compute(_walletBalancesWrapper, (
      wallet: wallet,
      refreshFromNode: refreshFromNode,
      minimumConfirmations: minimumConfirmations,
      ));
      return balances;
    } catch (e) {
      throw("Error getting wallet info : ${e.toString()}");
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
      }) data,) async {
    return  lib_epiccash.recoverWallet(
        data.config,
        data.password,
        data.mnemonic,
        data.name,
    );
  }

  ///
  /// Recover an Epic wallet using a mnemonic
  ///
  static Future<void> recoverWallet({
    required String config,
    required String password,
    required String mnemonic,
    required String name
  }) async {
    try {
      await compute(_recoverWalletWrapper, (
      config: config,
      password: password,
      mnemonic: mnemonic,
      name: name,
      ));
    } catch (e) {
      throw("Error recovering wallet : ${e.toString()}");
    }
  }


}
