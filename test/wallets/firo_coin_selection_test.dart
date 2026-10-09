import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/input.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/firo_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/firo_op_return.dart';

void main() {
  test('optimal FIRO selection includes OP_RETURN before signing', () async {
    final plain = _Wallet();
    final plainTx = await plain.select(10191);
    expect(plainTx.fee!.raw, BigInt.from(191));
    expect(plain.builds, isNotEmpty);

    final bridge = _Wallet();
    await expectLater(bridge.select(10191, data: _data), throwsException);
    expect(bridge.builds, isEmpty);
  });

  test('funded FIRO selection pays the serialized data output fee', () async {
    final plain = await _Wallet().select(20000);
    final bridgeWallet = _Wallet();
    final bridge = await bridgeWallet.select(20000, data: _data);
    expect(bridge.usedUTXOs, hasLength(1));
    expect(
      bridge.fee!.raw - plain.fee!.raw,
      BigInt.from(firoOpReturnOutput(_data).size),
    );
    expect(bridge.opReturnData, _data);
    expect(bridge.fee!.raw, BigInt.from(bridge.vSize!));
    expect(bridgeWallet.builds.every((tx) => tx.opReturnData == _data), isTrue);
  });
}

const _address = 'aEF6fyd5jjCPcbiEBZJ2g8583caUme8T7Y';
final _data = 'aa' * 80;

class _Wallet extends FiroWallet {
  _Wallet() : super(CryptoCurrencyNetwork.main);

  final builds = <TxData>[];

  Future<TxData> select(int inputValue, {String? data}) => coinSelection(
    txData: TxData(
      recipients: [
        TxRecipient(
          address: _address,
          amount: Amount(rawValue: BigInt.from(10000), fractionDigits: 8),
          isChange: false,
          addressType: AddressType.p2pkh,
        ),
      ],
      feeRateAmount: BigInt.from(1000),
      opReturnData: data,
    ),
    coinControl: false,
    isSendAll: false,
    isSendAllCoinControlUtxos: false,
    utxos: [
      StandardInput(
        UTXO(
          walletId: 'test',
          txid: '01' * 32,
          vout: 0,
          value: inputValue,
          name: '',
          isBlocked: false,
          blockedReason: null,
          isCoinbase: false,
          blockHash: 'confirmed',
          blockHeight: 90,
          blockTime: 1,
          address: _address,
        ),
      ),
    ],
  );

  @override
  Future<int> get chainHeight async => 100;

  @override
  Future<List<BaseInput>> addSigningKeys(List<BaseInput> utxosToUse) async =>
      utxosToUse;

  @override
  coinlib.Input standardInputToCoinlibInput(
    StandardInput input, {
    int sequence = 0xffffffff,
  }) => _SizedInput(input.utxo.txid, input.utxo.vout);

  @override
  Future<Address?> getCurrentChangeAddress() async => Address(
    walletId: 'test',
    value: _address,
    publicKey: [],
    derivationIndex: 0,
    derivationPath: null,
    type: AddressType.p2pkh,
    subType: AddressSubType.change,
  );

  @override
  Future<void> checkChangeAddressForTransactions() async {}

  @override
  Future<List<TxRecipient>> helperRecipientsConvert(
    List<String> addrs,
    List<BigInt> satValues,
  ) async => [
    for (var i = 0; i < addrs.length; i++)
      TxRecipient(
        address: addrs[i],
        amount: Amount(rawValue: satValues[i], fractionDigits: 8),
        isChange: i > 0,
        addressType: AddressType.p2pkh,
      ),
  ];

  @override
  Future<TxData> buildTransaction({
    required TxData txData,
    required List<BaseInput> inputsWithKeys,
  }) async {
    builds.add(txData);
    final transaction = coinlib.Transaction(
      inputs: inputsWithKeys
          .cast<StandardInput>()
          .map(standardInputToCoinlibInput)
          .toList(),
      outputs: [
        for (final recipient in txData.recipients!)
          coinlib.Output.fromAddress(
            recipient.amount.raw,
            coinlib.Address.fromString(
              recipient.address,
              cryptoCurrency.networkParams,
            ),
          ),
        if (txData.opReturnData != null)
          firoOpReturnOutput(txData.opReturnData!),
      ],
    );
    return txData.copyWith(vSize: transaction.size);
  }
}

class _SizedInput extends coinlib.RawInput {
  _SizedInput(String txid, int vout)
    : super(
        prevOut: coinlib.OutPoint.fromHex(txid, vout),
        scriptSig: Uint8List(106),
      );

  @override
  int get signedSize => size;
}
