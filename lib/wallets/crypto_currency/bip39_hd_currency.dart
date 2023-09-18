import 'package:coinlib/coinlib.dart' as coinlib;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/bip39_currency.dart';

abstract class Bip39HDCurrency extends Bip39Currency {
  Bip39HDCurrency(super.network);

  coinlib.NetworkParams get networkParams;

  Amount get dustLimit;

  String constructDerivePath({
    required DerivePathType derivePathType,
    int account = 0,
    required int chain,
    required int index,
  });

  ({coinlib.Address address, AddressType addressType}) getAddressForPublicKey({
    required coinlib.ECPublicKey publicKey,
    required DerivePathType derivePathType,
  });

  String addressToScriptHash({required String address}) {
    try {
      final addr = coinlib.Address.fromString(address, networkParams);
      return convertBytesToScriptHash(addr.program.script.compiled);
    } catch (e) {
      rethrow;
    }
  }

  static String convertBytesToScriptHash(Uint8List bytes) {
    final hash = sha256.convert(bytes.toList(growable: false)).toString();

    final chars = hash.split("");
    final List<String> reversedPairs = [];
    // TODO find a better/faster way to do this?
    int i = chars.length - 1;
    while (i > 0) {
      reversedPairs.add(chars[i - 1]);
      reversedPairs.add(chars[i]);
      i -= 2;
    }
    return reversedPairs.join("");
  }
}
