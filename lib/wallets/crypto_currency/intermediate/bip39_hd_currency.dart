import 'package:bech32/bech32.dart';
import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_currency.dart';

abstract class Bip39HDCurrency extends Bip39Currency {
  Bip39HDCurrency(super.network);

  coinlib.NetworkParams get networkParams;

  Amount get dustLimit;

  List<DerivePathType> get supportedDerivationPathTypes;

  int get maxUnusedAddressGap => 50;
  int get maxNumberOfIndexesToCheck => 10000;

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

  DerivePathType addressType({required String address}) {
    Uint8List? decodeBase58;
    Segwit? decodeBech32;
    try {
      decodeBase58 = bs58check.decode(address);
    } catch (err) {
      // Base58check decode fail
    }
    if (decodeBase58 != null) {
      if (decodeBase58[0] == networkParams.p2pkhPrefix) {
        // P2PKH
        return DerivePathType.bip44;
      }
      if (decodeBase58[0] == networkParams.p2shPrefix) {
        // P2SH
        return DerivePathType.bip49;
      }
      throw ArgumentError('Invalid version or Network mismatch');
    } else {
      try {
        decodeBech32 = segwit.decode(address, networkParams.bech32Hrp);
      } catch (err) {
        // Bech32 decode fail
      }
      if (networkParams.bech32Hrp != decodeBech32!.hrp) {
        throw ArgumentError('Invalid prefix or Network mismatch');
      }
      if (decodeBech32.version != 0) {
        throw ArgumentError('Invalid address version');
      }
      // P2WPKH
      return DerivePathType.bip84;
    }
  }
}
