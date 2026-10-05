import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/firo_wallet.dart';
import 'package:stackwallet/wl_gen/interfaces/lib_spark_interface.dart';

class _AddressDB extends Mock implements MainDB {
  Address? owned;

  @override
  Future<Address?> getAddress(String walletId, String address) async =>
      owned?.value == address ? owned : null;
}

class _Wallet extends FiroWallet {
  _Wallet() : super(CryptoCurrencyNetwork.main) {
    mainDB = _AddressDB();
  }

  bool viewOnly = false;
  @override
  bool get isViewOnly => viewOnly;
  @override
  String get walletId => 'test';
  @override
  Future<coinlib.HDPrivateKey> getRootHDNode() async =>
      coinlib.HDPrivateKey.fromSeed(Uint8List.fromList(List.filled(32, 1)));
  @override
  Future<Address?> getCurrentReceivingSparkAddress() async => null;
}

void main() {
  setUpAll(coinlib.loadCoinlib);

  test(
    'Spark sign/verify uses ownership proofs and preserves message bytes',
    () async {
      final wallet = _Wallet();
      final root = await wallet.getRootHDNode();
      final address = Address(
        walletId: wallet.walletId,
        value: await libSpark.getAddress(
          privateKey: root
              .derivePath(wallet.sparkDerivationPath)
              .privateKey
              .data,
          index: wallet.sparkIndex,
          diversifier: 0,
        ),
        publicKey: [],
        derivationIndex: 0,
        derivationPath: DerivationPath()..value = wallet.sparkDerivationPath,
        type: AddressType.spark,
        subType: AddressSubType.receiving,
      );
      (wallet.mainDB as _AddressDB).owned = address;
      const message = ' ownership\nchallenge ';
      final proof = await wallet.signMessage(message, address: address);
      expect(proof, hasLength(260));
      expect(
        await wallet.verifyMessage(
          message,
          address: address.value,
          signature: proof,
        ),
        isTrue,
      );
      expect(
        await wallet.verifyMessage(
          message.trim(),
          address: address.value,
          signature: proof,
        ),
        isFalse,
      );
      expect(
        await wallet.verifyMessage(
          message,
          address: address.value,
          signature: '${proof}00',
        ),
        isFalse,
      );
      for (final blank in ['', ' ', '\n\t']) {
        await expectLater(
          wallet.signMessage(blank, address: address),
          throwsException,
        );
      }
      wallet.viewOnly = true;
      await expectLater(
        wallet.signMessage(message, address: address),
        throwsException,
      );
      expect(
        await wallet.verifyMessage(
          message,
          address: address.value,
          signature: proof,
        ),
        isTrue,
      );
      wallet.viewOnly = false;
      (wallet.mainDB as _AddressDB).owned = null;
      await expectLater(
        wallet.signMessage(message, address: address),
        throwsException,
      );
    },
  );

  test(
    'transparent signing and verification retain the Bitcoin-style path',
    () async {
      final wallet = _Wallet();
      const path = "m/44'/136'/0'/0/0";
      final key = (await wallet.getRootHDNode()).derivePath(path).publicKey;
      final value = coinlib.P2PKHAddress.fromPublicKey(
        key,
        version: wallet.cryptoCurrency.networkParams.p2pkhPrefix,
      ).toString();
      final address = Address(
        walletId: wallet.walletId,
        value: value,
        publicKey: key.data,
        derivationIndex: 0,
        derivationPath: DerivationPath()..value = path,
        type: AddressType.p2pkh,
        subType: AddressSubType.receiving,
      );
      final signature = await wallet.signMessage('message', address: address);
      expect(
        await wallet.verifyMessage(
          'message',
          address: value,
          signature: signature,
        ),
        isTrue,
      );
      expect(
        await wallet.verifyMessage(
          'different',
          address: value,
          signature: signature,
        ),
        isFalse,
      );
    },
  );
}
