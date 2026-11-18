import 'dart:io';
import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/keys/view_only_wallet_data.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/extended_keys_interface.dart';

import '../support/isar_test_utils.dart';

class _Wallet extends BitcoinWallet {
  _Wallet({this.viewOnlyPath}) : super(CryptoCurrencyNetwork.main) {
    mainDB = MainDB.instance;
  }

  /// Account path of the xpub a view-only wallet watches. Null for a wallet
  /// that holds its seed.
  final String? viewOnlyPath;

  /// Script hashes the fake server reports history for.
  final Set<String> used = {};

  @override
  String get walletId => 'address-rotation-test';

  @override
  bool get isViewOnly => viewOnlyPath != null;

  @override
  ViewOnlyWalletType get viewOnlyType => ViewOnlyWalletType.xPub;

  @override
  Future<ViewOnlyWalletData> getViewOnlyWalletData() async =>
      ExtendedKeysViewOnlyWalletData(
        walletId: walletId,
        xPubs: [
          XPub(
            path: viewOnlyPath!,
            encoded: (await getRootHDNode())
                .derivePath(viewOnlyPath!)
                .hdPublicKey
                .encode(cryptoCurrency.networkParams.pubHDPrefix),
          ),
        ],
      );

  @override
  Future<coinlib.HDPrivateKey> getRootHDNode() async =>
      coinlib.HDPrivateKey.fromSeed(Uint8List.fromList(List.filled(32, 1)));

  @override
  Future<int> fetchTxCount({required String addressScriptHash}) async =>
      used.contains(addressScriptHash) ? 1 : 0;
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
      'stack_address_rotation_',
    );
    addTearDown(() => directory.delete(recursive: true));
    isar = await Isar.open(
      [AddressSchema, TransactionSchema, WalletInfoSchema],
      directory: directory.path,
      name: 'address-rotation-test',
      inspector: false,
    );
    addTearDown(() => isar.close());
    await MainDB.instance.initMainDB(mock: isar);
    wallet = _Wallet();
    await isar.writeTxn(
      () => isar.walletInfo.put(
        WalletInfo.createNew(
          coin: wallet.cryptoCurrency,
          name: 'address-rotation-test',
          walletIdOverride: wallet.walletId,
        ),
      ),
    );
    // The Taproot address every Bitcoin wallet starts with.
    await wallet.checkSaveInitialReceivingAddress();
  });

  Future<List<Address>> receiving(AddressType type) => isar.addresses
      .where()
      .walletIdEqualTo(wallet.walletId)
      .filter()
      .typeEqualTo(type)
      .subTypeEqualTo(AddressSubType.receiving)
      .sortByDerivationIndex()
      .findAll();

  /// Saves the next receiving address on [type], as the Receive view does.
  Future<Address> saveNext(DerivePathType type) async {
    final address = await wallet.generateNextReceivingAddress(
      derivePathType: type,
    );
    await MainDB.instance.updateOrPutAddresses([address]);
    return address;
  }

  void markUsed(Address address) => wallet.used.add(
    wallet.cryptoCurrency.addressToScriptHash(address: address.value),
  );

  test('a used address is rotated on every derivation path', () async {
    final taproot = (await receiving(AddressType.p2tr)).single;
    final segwit = await saveNext(DerivePathType.bip84);
    final legacy = await saveNext(DerivePathType.bip44);
    markUsed(taproot);
    markUsed(segwit);
    markUsed(legacy);

    await wallet.checkReceivingAddressForTransactions();

    for (final type in [
      AddressType.p2tr,
      AddressType.p2wpkh,
      AddressType.p2pkh,
    ]) {
      final addresses = await receiving(type);
      expect(addresses.map((e) => e.derivationIndex), [0, 1], reason: '$type');
    }
    expect(
      (await receiving(AddressType.p2wpkh)).last.derivationPath!.value,
      "m/84'/0'/0'/0/1",
    );
    expect(
      (await receiving(AddressType.p2pkh)).last.derivationPath!.value,
      "m/44'/0'/0'/0/1",
    );

    // Only the main type's address becomes the wallet's receiving address.
    expect(
      wallet.info.cachedReceivingAddress,
      (await receiving(AddressType.p2tr)).last.value,
    );
  });

  test('rotation continues until an unused address is found', () async {
    final first = await saveNext(DerivePathType.bip84);
    markUsed(first);
    // The next address already has history too, as after a restore.
    markUsed(
      await wallet.generateNextReceivingAddress(
        derivePathType: DerivePathType.bip84,
      ),
    );

    await wallet.checkReceivingAddressForTransactions();

    final addresses = await receiving(AddressType.p2wpkh);
    expect(addresses.map((e) => e.derivationIndex), [0, 1, 2]);
  });

  test('an unused address is kept', () async {
    markUsed((await receiving(AddressType.p2tr)).single);
    final segwit = await saveNext(DerivePathType.bip84);

    await wallet.checkReceivingAddressForTransactions();

    expect((await receiving(AddressType.p2wpkh)).single.value, segwit.value);
    expect(await receiving(AddressType.p2tr), hasLength(2));
  });

  test('a path without a saved receiving address gets none', () async {
    markUsed((await receiving(AddressType.p2tr)).single);

    await wallet.checkReceivingAddressForTransactions();

    expect(await receiving(AddressType.p2tr), hasLength(2));
    expect(await isar.addresses.count(), 2);
  });

  test('a view-only wallet rotates the one path of its xpub', () async {
    await isar.writeTxn(() => isar.addresses.clear());
    wallet = _Wallet(viewOnlyPath: "m/84'/0'/0'");
    await wallet.checkSaveInitialReceivingAddress();
    markUsed((await receiving(AddressType.p2wpkh)).single);

    await wallet.checkReceivingAddressForTransactions();

    final addresses = await receiving(AddressType.p2wpkh);
    expect(addresses.map((e) => e.derivationIndex), [0, 1]);
    expect(await isar.addresses.count(), 2);
  });
}
