import 'package:flutter/foundation.dart';
import 'package:flutter_libepiccash/epic_cash.dart' as lib_epiccash;
import 'package:mutex/mutex.dart';

///
/// Wrapped up calls to flutter_libepiccash.
///
/// Should all be static calls (no state stored in this class)
///
abstract class LibEpiccash {
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
  /// Fetch the mnemonic of (some? current?) wallet
  ///
  // TODO: ensure the above documentation comment is correct
  // TODO: ensure this will always return the mnemonic. If not, this function should throw an exception
  // TODO: probably remove this as we don't use it in stack wallet. We store the mnemonic separately
  static String getMnemonic() {
    return lib_epiccash.walletMnemonic();
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
  /// Create and or initialize a new epiccash wallet.
  ///
  // TODO: Complete/modify the documentation comment above
  // TODO: Should return a void future. On error this function should throw and exception
  static Future<String> initializeNewWallet({
    required String config,
    required String mnemonic,
    required String password,
    required String name,
  }) async {
    final String result = await compute(
      _initializeWalletWrapper,
      (
        config: config,
        mnemonic: mnemonic,
        password: password,
        name: name,
      ),
    );

    return result;
  }
}
