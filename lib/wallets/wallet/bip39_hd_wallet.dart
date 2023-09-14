import 'package:bip39/bip39.dart' as bip39;
import 'package:coinlib/coinlib.dart' as coinlib;
import 'package:isar/isar.dart';
import 'package:stackwallet/exceptions/sw_exception.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/coin/bip39_hd_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

class Bip39HDWallet<T extends Bip39HDCurrency> extends Wallet<T> {
  Bip39HDWallet(super.cryptoCurrency);

  /// Generates a receiving address of [walletInfo.mainAddressType]. If none
  /// are in the current wallet db it will generate at index 0, otherwise the
  /// highest index found in the current wallet db.
  Future<Address> generateNewReceivingAddress() async {
    final current = await _currentReceivingAddress;
    final index = current?.derivationIndex ?? 0;
    const chain = 0; // receiving address

    final DerivePathType derivePathType;
    switch (walletInfo.mainAddressType) {
      case AddressType.p2pkh:
        derivePathType = DerivePathType.bip44;
        break;

      case AddressType.p2sh:
        derivePathType = DerivePathType.bip44;
        break;

      case AddressType.p2wpkh:
        derivePathType = DerivePathType.bip44;
        break;

      default:
        throw Exception(
          "Invalid AddressType accessed in $runtimeType generateNewReceivingAddress()",
        );
    }

    final address = await _generateAddress(
      chain: chain,
      index: index,
      derivePathType: derivePathType,
    );

    await mainDB.putAddress(address);

    return address;
  }

  Future<String> getMnemonic() async {
    final mnemonic = await secureStorageInterface.read(
      key: Wallet.mnemonicKey(walletId: walletInfo.walletId),
    );

    if (mnemonic == null) {
      throw SWException("mnemonic has not been set");
    }

    return mnemonic;
  }

  Future<String> getMnemonicPassphrase() async {
    final mnemonicPassphrase = await secureStorageInterface.read(
      key: Wallet.mnemonicPassphraseKey(walletId: walletInfo.walletId),
    );

    if (mnemonicPassphrase == null) {
      throw SWException("mnemonicPassphrase has not been set");
    }

    return mnemonicPassphrase;
  }

  // ========== Private ========================================================

  Future<Address?> get _currentReceivingAddress async =>
      await mainDB.isar.addresses
          .where()
          .walletIdEqualTo(walletId)
          .filter()
          .typeEqualTo(walletInfo.mainAddressType)
          .subTypeEqualTo(AddressSubType.receiving)
          .sortByDerivationIndexDesc()
          .findFirst();

  Future<coinlib.HDPrivateKey> _generateRootHDNode() async {
    final seed = bip39.mnemonicToSeed(
      await getMnemonic(),
      passphrase: await getMnemonicPassphrase(),
    );
    return coinlib.HDPrivateKey.fromSeed(seed);
  }

  Future<Address> _generateAddress({
    required int chain,
    required int index,
    required DerivePathType derivePathType,
  }) async {
    final root = await _generateRootHDNode();

    final derivationPath = cryptoCurrency.constructDerivePath(
      derivePathType: derivePathType,
      chain: chain,
      index: index,
    );

    final keys = root.derivePath(derivationPath);

    final data = cryptoCurrency.getAddressForPublicKey(
      publicKey: keys.publicKey,
      derivePathType: derivePathType,
    );

    final AddressSubType subType;

    if (chain == 0) {
      subType = AddressSubType.receiving;
    } else if (chain == 1) {
      subType = AddressSubType.change;
    } else {
      // TODO others?
      subType = AddressSubType.unknown;
    }

    return Address(
      walletId: walletId,
      value: data.address.toString(),
      publicKey: keys.publicKey.data,
      derivationIndex: index,
      derivationPath: DerivationPath()..value = derivationPath,
      type: data.addressType,
      subType: subType,
    );
  }

  // ========== Overrides ======================================================

  @override
  Future<TxData> confirmSend({required TxData txData}) {
    // TODO: implement confirmSend
    throw UnimplementedError();
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) {
    // TODO: implement prepareSend
    throw UnimplementedError();
  }
}
