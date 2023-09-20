import 'package:flutter/foundation.dart';
import 'package:flutter_libepiccash/epic_cash.dart' as lib_epiccash;
import 'package:tuple/tuple.dart';

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

  static String getMnemonic() {
    return lib_epiccash.walletMnemonic();
  }

  static Future<String> _initializeWalletWrapper(
      Tuple4<String, String, String, String> data) async {
    final String initWalletStr =
    lib_epiccash.initWallet(data.item1, data.item2, data.item3, data.item4);
    return initWalletStr;
  }

  static Future<String> initializeNewWallet({
    required String config,
    required String mnemonic,
    required String password,
    required String name}) async {

    String result = await compute(
      _initializeWalletWrapper,
      Tuple4(
        config,
        mnemonic,
        password,
        name,
      ),
    );

    return result;
  }


}
