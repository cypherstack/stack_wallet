import 'dart:io';
import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';

import '../support/isar_test_utils.dart';

class _Wallet extends BitcoinWallet {
  _Wallet() : super(CryptoCurrencyNetwork.main) {
    mainDB = MainDB.instance;
  }

  @override
  String get walletId => 'address-index-test';

  @override
  bool get isViewOnly => false;

  @override
  Future<coinlib.HDPrivateKey> getRootHDNode() async =>
      coinlib.HDPrivateKey.fromSeed(Uint8List.fromList(List.filled(32, 1)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar isar;
  late _Wallet wallet;

  setUpAll(() async {
    await initializeTestIsar();
    await coinlib.loadCoinlib();
  });
  setUp(() async {
    final directory = await Directory.systemTemp.createTemp(
      'stack_address_index_',
    );
    addTearDown(() => directory.delete(recursive: true));
    isar = await Isar.open(
      [AddressSchema, TransactionSchema],
      directory: directory.path,
      name: 'address-index-test',
      inspector: false,
    );
    addTearDown(() => isar.close());
    await MainDB.instance.initMainDB(mock: isar);
    wallet = _Wallet();
  });

  Address address(String value, int index, AddressSubType subType) => Address(
    walletId: wallet.walletId,
    value: value,
    publicKey: [],
    derivationIndex: index,
    derivationPath: null,
    type: AddressType.p2wpkh,
    subType: subType,
  );

  test(
    'change and Paynym indexes do not advance the receiving chain',
    () async {
      await MainDB.instance.putAddresses([
        address('receiving', 2, AddressSubType.receiving),
        address('change', 100, AddressSubType.change),
        address('paynym', 200, AddressSubType.paynymReceive),
      ]);
      final generated = await wallet.generateNextReceivingAddress(
        derivePathType: DerivePathType.bip84,
      );
      expect(generated.derivationIndex, 3);
      expect(generated.derivationPath!.value, "m/84'/0'/0'/0/3");
      expect(generated.subType, AddressSubType.receiving);
    },
  );

  test(
    'a receiving chain starts at zero when only change addresses exist',
    () async {
      await MainDB.instance.putAddress(
        address('change', 100, AddressSubType.change),
      );
      final generated = await wallet.generateNextReceivingAddress(
        derivePathType: DerivePathType.bip84,
      );
      expect(generated.derivationIndex, 0);
      expect(generated.derivationPath!.value, "m/84'/0'/0'/0/0");
    },
  );
}
