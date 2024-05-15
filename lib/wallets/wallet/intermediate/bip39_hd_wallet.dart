import 'package:bip39/bip39.dart' as bip39;
import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:isar/isar.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_hd_currency.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/multi_address_interface.dart';

abstract class Bip39HDWallet<T extends Bip39HDCurrency> extends Bip39Wallet<T>
    with MultiAddressInterface<T> {
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
      derivePathType: info.coin.primaryDerivePathType,
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
      derivePathType: info.coin.primaryDerivePathType,
    );

    await mainDB.updateOrPutAddresses([address]);
  }

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    final current = await getCurrentChangeAddress();
    if (current == null) {
      final address = await _generateAddress(
        chain: 0, // receiving
        index: 0, // initial index
        derivePathType: info.coin.primaryDerivePathType,
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

  Future<Address> _generateAddress({
    required int chain,
    required int index,
    required DerivePathType derivePathType,
  }) async {
    final root = await getRootHDNode();

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
      // TODO: [prio=low] others or throw?
      subType = AddressSubType.unknown;
    }

    return Address(
      walletId: walletId,
      value: convertAddressString(data.address.toString()),
      publicKey: keys.publicKey.data,
      derivationIndex: index,
      derivationPath: DerivationPath()..value = derivationPath,
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
