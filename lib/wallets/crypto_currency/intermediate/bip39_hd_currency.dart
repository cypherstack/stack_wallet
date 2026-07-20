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

  /// The effective address-scanning gap limit given an optional per-wallet
  /// [override]. The override may only RAISE the gap above [maxUnusedAddressGap];
  /// a smaller (or null) value falls back to the coin default. Scanning
  /// shallower than the default could stop before a funded address and hide a
  /// balance, so lowering is deliberately not allowed.
  int effectiveGapLimit(int? override) =>
      (override != null && override > maxUnusedAddressGap)
      ? override
      : maxUnusedAddressGap;

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
      (e) => (path: e, addressType: e.getAddressType()),
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

  /// SLIP-0132 public-key version bytes to use when serializing this wallet's
  /// extended public key for [derivePathType].
  ///
  /// Defaults to the coin's single [networkParams].pubHDPrefix (i.e. a generic
  /// `xpub`/`tpub`) so coins without script-typed extended keys are unchanged.
  /// Bitcoin/Litecoin override this to emit `ypub`/`zpub` (`upub`/`vpub` on
  /// testnet) per script type. See the `Slip132` helper.
  int slip132PubVersion(DerivePathType derivePathType) =>
      networkParams.pubHDPrefix;

  /// The private-key analog of [slip132PubVersion].
  int slip132PrivVersion(DerivePathType derivePathType) =>
      networkParams.privHDPrefix;

  /// The [DerivePathType] implied by the public-key version bytes [pubVersion]
  /// of a pasted extended key, or `null` when this coin cannot unambiguously
  /// map them (the default). Used when importing a view-only wallet so that
  /// addresses derive with the correct script type. Bitcoin/Litecoin override
  /// this.
  DerivePathType? derivePathTypeForExtendedKeyVersion(int pubVersion) => null;

  /// Reads the 4 SLIP-0132 version bytes from a serialized extended key
  /// [extendedKey] (e.g. an `xpub`/`ypub`/`zpub`), or returns `null` if it
  /// cannot be base58check-decoded. Does not validate that the key belongs to
  /// this coin; pair with [derivePathTypeForExtendedKeyVersion].
  static int? extendedKeyVersion(String extendedKey) {
    try {
      final b = coinlib.base58Decode(extendedKey.trim());
      if (b.length < 4) return null;
      return (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3];
    } catch (_) {
      return null;
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
