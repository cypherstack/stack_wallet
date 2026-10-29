import 'package:coinlib_flutter/coinlib_flutter.dart' as cl;
import 'package:flutter/foundation.dart';

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../utilities/logger.dart';
import '../intermediate/bip39_hd_currency.dart';

mixin ElectrumXCurrencyInterface on Bip39HDCurrency {
  int get transactionVersion;

  /// The default fee rate in satoshis per kilobyte.
  BigInt get defaultFeeRate;

  /// Whether raw transactions follow Bitcoin's layout, which the parser in
  /// owned_input_signatures.dart reads, allowing for Peercoin's timestamp and
  /// the Dash and Firo extra payload. Particl's layout differs, so its coins
  /// are not authenticated against the parent transaction; its signature hash
  /// commits to the amount anyway.
  bool get hasBitcoinTransactionLayout => true;

  /// Whether transactions below version 3 carry a timestamp after the
  /// version field, as Peercoin's do.
  bool get legacyTransactionTimestamp => false;

  @override
  AddressType? getAddressType(String address) {
    try {
      final clAddress = cl.Address.fromString(address, networkParams);

      Logging.instance.t(
        "getAddressType($address) type is ${clAddress.runtimeType}",
      );

      return switch (clAddress) {
        cl.P2PKHAddress() => AddressType.p2pkh,
        cl.P2SHAddress() => AddressType.p2sh,
        cl.P2WPKHAddress() => AddressType.p2wpkh,
        cl.P2TRAddress() => AddressType.p2tr,
        cl.MwebAddress() => AddressType.mweb,
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
