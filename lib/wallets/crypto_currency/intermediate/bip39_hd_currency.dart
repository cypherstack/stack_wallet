import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../interfaces/view_only_option_currency_interface.dart';
import 'bip39_currency.dart';

abstract class Bip39HDCurrency extends Bip39Currency
    implements ViewOnlyOptionCurrencyInterface {
  Bip39HDCurrency(super.network);

  coinlib.Network get networkParams;

  Amount get dustLimit;

  List<DerivePathType> get supportedDerivationPathTypes;

  int get maxUnusedAddressGap => 50;

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

  List<String> get supportedHardenedDerivationPaths {
    final paths = supportedDerivationPathTypes.map(
      (e) => (
        path: e,
        addressType: e.getAddressType(),
      ),
    );

    return paths.map((e) {
      final path = constructDerivePath(
        derivePathType: e.path,
        chain: 0,
        index: 0,
      );
      // trim unhardened
      return path.substring(0, path.lastIndexOf("'") + 1);
    }).toList();
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
    final address2 = coinlib.Address.fromString(address, networkParams);

    if (address2 is coinlib.P2PKHAddress) {
      return DerivePathType.bip44;
    } else if (address2 is coinlib.P2SHAddress) {
      return DerivePathType.bip49;
    } else if (address2 is coinlib.P2WPKHAddress) {
      return DerivePathType.bip84;
    } else if (address2 is coinlib.P2TRAddress) {
      return DerivePathType.bip86;
    } else {
      // TODO: [prio=med] better error handling
      throw ArgumentError('Invalid address');
    }
  }
}
