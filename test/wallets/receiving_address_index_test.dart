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

  Address address(
    String value,
    int index,
    AddressSubType subType, {
    AddressType type = AddressType.p2wpkh,
  }) => Address(
    walletId: wallet.walletId,
    value: value,
    publicKey: [],
    derivationIndex: index,
    derivationPath: null,
    type: type,
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

  test(
    'getOrCreateCurrentReceivingAddress persists the first typed address',
    () async {
      final current = await wallet.getOrCreateCurrentReceivingAddress(
        derivePathType: DerivePathType.bip84,
      );

      final stored = await isar.addresses
          .where()
          .walletIdEqualTo(wallet.walletId)
          .filter()
          .valueEqualTo(current.value)
          .findFirst();

      expect(current.derivationIndex, 0);
      expect(current.derivationPath!.value, "m/84'/0'/0'/0/0");
      expect(current.subType, AddressSubType.receiving);
      expect(stored?.value, current.value);
    },
  );

  test(
    'getOrCreateCurrentReceivingAddress reuses the persisted address',
    () async {
      final first = await wallet.getOrCreateCurrentReceivingAddress(
        derivePathType: DerivePathType.bip84,
      );
      final second = await wallet.getOrCreateCurrentReceivingAddress(
        derivePathType: DerivePathType.bip84,
      );

      final receivingAddresses = await isar.addresses
          .where()
          .walletIdEqualTo(wallet.walletId)
          .filter()
          .typeEqualTo(AddressType.p2wpkh)
          .subTypeEqualTo(AddressSubType.receiving)
          .findAll();

      expect(second.value, first.value);
      expect(second.derivationIndex, 0);
      expect(receivingAddresses, hasLength(1));
    },
  );

  test(
    'concurrent getOrCreateCurrentReceivingAddress calls persist one address',
    () async {
      final addresses = await Future.wait(
        List.generate(
          3,
          (_) => wallet.getOrCreateCurrentReceivingAddress(
            derivePathType: DerivePathType.bip84,
          ),
        ),
      );

      final receivingAddresses = await isar.addresses
          .where()
          .walletIdEqualTo(wallet.walletId)
          .filter()
          .typeEqualTo(AddressType.p2wpkh)
          .subTypeEqualTo(AddressSubType.receiving)
          .findAll();

      expect(addresses.map((address) => address.value).toSet(), hasLength(1));
      expect(receivingAddresses, hasLength(1));
      expect(receivingAddresses.single.derivationIndex, 0);
    },
  );

  test(
    'getOrCreateCurrentReceivingAddress excludes change addresses',
    () async {
      await MainDB.instance.putAddress(
        address('change', 100, AddressSubType.change),
      );

      final current = await wallet.getOrCreateCurrentReceivingAddress(
        derivePathType: DerivePathType.bip84,
      );

      expect(current.derivationIndex, 0);
      expect(current.subType, AddressSubType.receiving);
      expect(await isar.addresses.count(), 2);
    },
  );

  test(
    'getOrCreateCurrentReceivingAddress reuses an address with history',
    () async {
      final used = address('used', 7, AddressSubType.receiving);
      final transaction = Transaction(
        walletId: wallet.walletId,
        txid: 'used-transaction',
        timestamp: 1,
        type: TransactionType.incoming,
        subType: TransactionSubType.none,
        amount: 1,
        amountString: null,
        fee: 0,
        height: 1,
        isCancelled: false,
        isLelantus: null,
        slateId: null,
        otherData: null,
        inputs: const [],
        outputs: const [],
        nonce: null,
        numberOfMessages: null,
      );
      await isar.writeTxn(() async {
        await isar.transactions.put(transaction);
        await isar.addresses.put(used);
        used.transactions.add(transaction);
        await used.transactions.save();
      });

      final current = await wallet.getOrCreateCurrentReceivingAddress(
        derivePathType: DerivePathType.bip84,
      );

      expect(current.value, used.value);
      expect(current.derivationIndex, 7);
      expect(await isar.addresses.count(), 1);
    },
  );

  test(
    'getOrCreateCurrentReceivingAddress leaves primary BIP86 unchanged',
    () async {
      final primary = address(
        'primary-taproot',
        4,
        AddressSubType.receiving,
        type: AddressType.p2tr,
      );
      await MainDB.instance.putAddress(primary);

      final current = await wallet.getOrCreateCurrentReceivingAddress(
        derivePathType: DerivePathType.bip84,
      );

      final storedPrimary = await isar.addresses
          .where()
          .walletIdEqualTo(wallet.walletId)
          .filter()
          .valueEqualTo(primary.value)
          .findFirst();
      expect(current.type, AddressType.p2wpkh);
      expect(current.derivationIndex, 0);
      expect(storedPrimary?.value, primary.value);
      expect(storedPrimary?.type, AddressType.p2tr);
    },
  );
}
