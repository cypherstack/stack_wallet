import 'package:bip39/bip39.dart' as bip39;
import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:isar/isar.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_hd_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_wallet.dart';

abstract class Bip39HDWallet<T extends Bip39HDCurrency> extends Bip39Wallet<T> {
  Bip39HDWallet(T cryptoCurrency) : super(cryptoCurrency);

  /// Generates a receiving address of [info.mainAddressType]. If none
  /// are in the current wallet db it will generate at index 0, otherwise the
  /// highest index found in the current wallet db.
  Future<Address> generateNewReceivingAddress() async {
    final current = await getCurrentReceivingAddress();
    final index = current?.derivationIndex ?? 0;
    const chain = 0; // receiving address

    final DerivePathType derivePathType;
    switch (info.mainAddressType) {
      case AddressType.p2pkh:
        derivePathType = DerivePathType.bip44;
        break;

      case AddressType.p2sh:
        derivePathType = DerivePathType.bip49;
        break;

      case AddressType.p2wpkh:
        derivePathType = DerivePathType.bip84;
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
    await info.updateReceivingAddress(
      newAddress: address.value,
      isar: mainDB.isar,
    );

    return address;
  }

  // ========== Private ========================================================

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
      // TODO: [prio=low] others or throw?
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

  @override
  Future<void> recover({required bool isRescan}) {
    // TODO: implement recover
    throw UnimplementedError();
  }
}