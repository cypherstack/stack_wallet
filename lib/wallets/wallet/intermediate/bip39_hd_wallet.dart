import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:isar/isar.dart';

import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/keys/view_only_wallet_data.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../crypto_currency/intermediate/bip39_hd_currency.dart';
import '../wallet_mixin_interfaces/multi_address_interface.dart';
import '../wallet_mixin_interfaces/view_only_option_interface.dart';
import 'bip39_wallet.dart';

abstract class Bip39HDWallet<T extends Bip39HDCurrency> extends Bip39Wallet<T>
    with MultiAddressInterface<T>, ViewOnlyOptionInterface<T> {
  Bip39HDWallet(super.cryptoCurrency);

  Set<AddressType> get supportedAddressTypes =>
      cryptoCurrency.supportedDerivationPathTypes
          .where((e) => e != DerivePathType.bip49)
          .map((e) => e.getAddressType())
          .toSet();

  Future<coinlib.HDPrivateKey> getRootHDNode() async {
    final seed = bip39.mnemonicToSeed(
      await getMnemonic(),
      passphrase: await getMnemonicPassphrase(),
    );
    return coinlib.HDPrivateKey.fromSeed(seed);
  }

  Future<String> getPrivateKeyWIF(Address address) async {
    final keys =
        (await getRootHDNode()).derivePath(address.derivationPath!.value);

    final List<int> data = [
      cryptoCurrency.networkParams.wifPrefix,
      ...keys.privateKey.data,
      if (keys.privateKey.compressed) 1,
    ];
    final checksum =
        coinlib.sha256DoubleHash(Uint8List.fromList(data)).sublist(0, 4);
    data.addAll(checksum);

    return Uint8List.fromList(data).toBase58Encoded;
  }

  Future<Address> generateNextReceivingAddress({
    required DerivePathType derivePathType,
  }) async {
    if (!cryptoCurrency.supportedDerivationPathTypes.contains(derivePathType)) {
      throw Exception(
        "Unsupported DerivePathType passed to generateNextReceivingAddress().",
      );
    }

    final current = await mainDB.isar.addresses
        .where()
        .walletIdEqualTo(walletId)
        .filter()
        .typeEqualTo(derivePathType.getAddressType())
        .sortByDerivationIndexDesc()
        .findFirst();
    final index = current == null ? 0 : current.derivationIndex + 1;
    const chain = 0; // receiving address
    final address = await _generateAddress(
      chain: chain,
      index: index,
      derivePathType: derivePathType,
    );

    return address;
  }

  /// Generates a receiving address. If none
  /// are in the current wallet db it will generate at index 0, otherwise the
  /// highest index found in the current wallet db.
  @override
  Future<void> generateNewReceivingAddress() async {
    final current = await getCurrentReceivingAddress();
    final index = current == null ? 0 : current.derivationIndex + 1;
    const chain = 0; // receiving address

    final address = await _generateAddress(
      chain: chain,
      index: index,
      derivePathType: _fromAddressType(info.mainAddressType),
    );

    await mainDB.updateOrPutAddresses([address]);
    await info.updateReceivingAddress(
      newAddress: address.value,
      isar: mainDB.isar,
    );
  }

  /// Generates a change address. If none
  /// are in the current wallet db it will generate at index 0, otherwise the
  /// highest index found in the current wallet db.
  @override
  Future<void> generateNewChangeAddress() async {
    final current = await getCurrentChangeAddress();
    final index = current == null ? 0 : current.derivationIndex + 1;
    const chain = 1; // change address

    final address = await _generateAddress(
      chain: chain,
      index: index,
      derivePathType: _fromAddressType(info.mainAddressType),
    );

    await mainDB.updateOrPutAddresses([address]);
  }

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    if (isViewOnly && viewOnlyType == ViewOnlyWalletType.addressOnly) return;

    final current = await getCurrentReceivingAddress();
    if (current == null) {
      final address = await _generateAddress(
        chain: 0, // receiving
        index: 0, // initial index
        derivePathType: _fromAddressType(info.mainAddressType),
      );

      await mainDB.updateOrPutAddresses([address]);
    }
  }

  // ========== Subclasses may override ========================================

  /// To be overridden by crypto currencies that do extra address conversions
  /// on top of the normal btc style address. (BCH and Ecash for example)
  String convertAddressString(String address) {
    return address;
  }

  // ========== Private ========================================================

  DerivePathType _fromAddressType(AddressType addressType) {
    switch (addressType) {
      case AddressType.p2pkh:
        // DerivePathType.bip44:
        // DerivePathType.bch44:
        // DerivePathType.eCash44:
        // Should be one of the above due to silly case due to bch and ecash
        return info.coin.defaultDerivePathType;

      case AddressType.p2sh:
        return DerivePathType.bip49;

      case AddressType.p2wpkh:
        return DerivePathType.bip84;

      case AddressType.p2tr:
        return DerivePathType.bip86;

      case AddressType.solana:
        return DerivePathType.solana;

      case AddressType.ethereum:
        return DerivePathType.eth;

      default:
        throw ArgumentError(
          "Incompatible AddressType \"$addressType\" passed to DerivePathType.fromAddressType()",
        );
    }
  }

  Future<Address> _generateAddress({
    required int chain,
    required int index,
    required DerivePathType derivePathType,
  }) async {
    final derivationPath = cryptoCurrency.constructDerivePath(
      derivePathType: derivePathType,
      chain: chain,
      index: index,
    );

    final coinlib.HDKey keys;
    if (isViewOnly) {
      final idx = derivationPath.lastIndexOf("'/");
      final path = derivationPath.substring(idx + 2);
      final data =
          await getViewOnlyWalletData() as ExtendedKeysViewOnlyWalletData;

      final xPub = data.xPubs.firstWhere(
        (e) => derivationPath.startsWith(e.path),
      );

      final node = coinlib.HDPublicKey.decode(xPub.encoded);
      keys = node.derivePath(path);
    } else {
      final root = await getRootHDNode();
      keys = root.derivePath(derivationPath);
    }

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
      // TODO: [prio=low] others or throw?
      subType = AddressSubType.unknown;
    }

    return Address(
      walletId: walletId,
      value: convertAddressString(data.address.toString()),
      publicKey: keys.publicKey.data,
      derivationIndex: index,
      derivationPath:
          isViewOnly ? null : (DerivationPath()..value = derivationPath),
      type: data.addressType,
      subType: subType,
    );
  }

  // ========== Overrides ======================================================

  @override
  Future<void> updateBalance() async {
    final utxos = await mainDB.getUTXOs(walletId).findAll();

    final currentChainHeight = await chainHeight;

    Amount satoshiBalanceTotal = Amount(
      rawValue: BigInt.zero,
      fractionDigits: cryptoCurrency.fractionDigits,
    );
    Amount satoshiBalancePending = Amount(
      rawValue: BigInt.zero,
      fractionDigits: cryptoCurrency.fractionDigits,
    );
    Amount satoshiBalanceSpendable = Amount(
      rawValue: BigInt.zero,
      fractionDigits: cryptoCurrency.fractionDigits,
    );
    Amount satoshiBalanceBlocked = Amount(
      rawValue: BigInt.zero,
      fractionDigits: cryptoCurrency.fractionDigits,
    );

    for (final utxo in utxos) {
      final utxoAmount = Amount(
        rawValue: BigInt.from(utxo.value),
        fractionDigits: cryptoCurrency.fractionDigits,
      );

      satoshiBalanceTotal += utxoAmount;

      if (utxo.isBlocked) {
        satoshiBalanceBlocked += utxoAmount;
      } else {
        if (utxo.isConfirmed(
          currentChainHeight,
          cryptoCurrency.minConfirms,
        )) {
          satoshiBalanceSpendable += utxoAmount;
        } else {
          satoshiBalancePending += utxoAmount;
        }
      }
    }

    final balance = Balance(
      total: satoshiBalanceTotal,
      spendable: satoshiBalanceSpendable,
      blockedTotal: satoshiBalanceBlocked,
      pendingSpendable: satoshiBalancePending,
    );

    await info.updateBalance(newBalance: balance, isar: mainDB.isar);
  }
}
