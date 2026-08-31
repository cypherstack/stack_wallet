import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/coinlib/exp2pkh_address.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';

int _estimateTxFee({required int vSize, required BigInt feeRatePerKB}) =>
    (feeRatePerKB * BigInt.from(vSize) ~/ BigInt.from(1000)).toInt();

void main() {
  test('final vSize fee uses the selected rate', () {
    final fee = requiredFeeForVSize(
      vSize: 226,
      satsPerVByte: null,
      feeRatePerKB: BigInt.from(2000),
      estimateTxFee: _estimateTxFee,
    );

    expect(fee, BigInt.from(452));
  });

  test('final vSize fee preserves the one atomic unit per byte floor', () {
    final fee = requiredFeeForVSize(
      vSize: 226,
      satsPerVByte: null,
      feeRatePerKB: BigInt.from(200),
      estimateTxFee: _estimateTxFee,
    );

    expect(fee, BigInt.from(226));
  });

  test('eCash default fee matches its relay policy', () {
    final ecash = Ecash(CryptoCurrencyNetwork.main);

    expect(ecash.defaultFeeRate, BigInt.from(1000));
  });

  test('Firo EX addresses use their exchange output script', () {
    final firo = Firo(CryptoCurrencyNetwork.main);
    final address = coinlib.base58Encode(
      Uint8List.fromList([
        ...firo.exAddressVersion,
        ...List<int>.filled(20, 1),
      ]),
    );

    final parsed = parseElectrumXAddress(
      address: address,
      cryptoCurrency: firo,
    );

    expect(parsed, isA<EXP2PKHAddress>());
    expect(coinlib.Output.fromAddress(BigInt.one, parsed).size, 35);
  });
}
