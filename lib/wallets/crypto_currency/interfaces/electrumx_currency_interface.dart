import 'package:coin/coin.dart' as coin;
import 'package:flutter/foundation.dart';

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../utilities/logger.dart';
import '../intermediate/bip39_hd_currency.dart';

mixin ElectrumXCurrencyInterface on Bip39HDCurrency {
  int get transactionVersion;

  /// The default fee rate in satoshis per kilobyte.
  BigInt get defaultFeeRate;

  @override
  AddressType? getAddressType(String address) {
    try {
      final addr = coin.Addr.fromString(address, networkParams);

      Logging.instance.t(
        "getAddressType($address) type is ${addr.runtimeType}",
      );

      return switch (addr) {
        coin.P2pkhAddr() => AddressType.p2pkh,
        coin.P2shAddr() => AddressType.p2sh,
        coin.SegwitAddr() => AddressType.p2wpkh,
        coin.TaprootAddr() => AddressType.p2tr,
        coin.MwebAddr() => AddressType.mweb,
        _ => null,
      };
    } catch (e, s) {
      if (kDebugMode) {
        Logging.instance.e(
          "getAddressType($address) failed",
          error: e,
          stackTrace: s,
        );
      } else {
        Logging.instance.t("getAddressType($address) failed");
      }

      return null;
    }
  }
}
