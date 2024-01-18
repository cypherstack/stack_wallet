import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:frostdart/frostdart.dart' as frost;
import 'package:frostdart/frostdart_bindings_generated.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/electrumx_rpc/cached_electrumx_client.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/bitcoin_frost.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/private_key_currency.dart';
import 'package:stackwallet/wallets/isar/models/frost_wallet_info.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/private_key_interface.dart';

class BitcoinFrostWallet<T extends FrostCurrency> extends Wallet<T>
    with PrivateKeyInterface {
  FrostWalletInfo get frostInfo => throw UnimplementedError();

  late ElectrumXClient electrumXClient;
  late CachedElectrumXClient electrumXCachedClient;

  @override
  int get isarTransactionVersion => 2;

  BitcoinFrostWallet(CryptoCurrencyNetwork network)
      : super(BitcoinFrost(network) as T);

  @override
  FilterOperation? get changeAddressFilterOperation => FilterGroup.and(
        [
          FilterCondition.equalTo(
            property: r"type",
            value: info.mainAddressType,
          ),
          const FilterCondition.equalTo(
            property: r"subType",
            value: AddressSubType.change,
          ),
        ],
      );

  @override
  FilterOperation? get receivingAddressFilterOperation => FilterGroup.and(
        [
          FilterCondition.equalTo(
            property: r"type",
            value: info.mainAddressType,
          ),
          const FilterCondition.equalTo(
            property: r"subType",
            value: AddressSubType.receiving,
          ),
        ],
      );

  // Future<List<Address>> fetchAddressesForElectrumXScan() async {
  //   final allAddresses = await mainDB
  //       .getAddresses(walletId)
  //       .filter()
  //       .typeEqualTo(AddressType.frostMS)
  //       .and()
  //       .group(
  //         (q) => q
  //             .subTypeEqualTo(AddressSubType.receiving)
  //             .or()
  //             .subTypeEqualTo(AddressSubType.change),
  //       )
  //       .findAll();
  //   return allAddresses;
  // }

  @override
  Future<void> updateTransactions() {
    // TODO: implement updateTransactions
    throw UnimplementedError();
  }

  int estimateTxFee({required int vSize, required int feeRatePerKB}) {
    return vSize * (feeRatePerKB / 1000).ceil();
  }

  Amount roughFeeEstimate(int inputCount, int outputCount, int feeRatePerKB) {
    return Amount(
      rawValue: BigInt.from(
          ((42 + (272 * inputCount) + (128 * outputCount)) / 4).ceil() *
              (feeRatePerKB / 1000).ceil()),
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }

  @override
  Future<void> checkSaveInitialReceivingAddress() {
    // TODO: implement checkSaveInitialReceivingAddress
    throw UnimplementedError();
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) {
    // TODO: implement confirmSend
    throw UnimplementedError();
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) {
    // TODO: implement estimateFeeFor
    throw UnimplementedError();
  }

  @override
  // TODO: implement fees
  Future<FeeObject> get fees => throw UnimplementedError();

  @override
  Future<TxData> prepareSend({required TxData txData}) {
    // TODO: implement prepareSendpu
    throw UnimplementedError();
  }

  @override
  Future<void> recover({
    required bool isRescan,
    String? serializedKeys,
    String? multisigConfig,
  }) async {
    if (serializedKeys == null || multisigConfig == null) {
      throw Exception(
        "Failed to recover $runtimeType: "
        "Missing serializedKeys and/or multisigConfig.",
      );
    }

    try {
      await refreshMutex.protect(() async {
        if (!isRescan) {
          final salt = frost
              .multisigSalt(
                multisigConfig: multisigConfig,
              )
              .toHex;
          final knownSalts = frostInfo.knownSalts;
          if (knownSalts.contains(salt)) {
            throw Exception("Known frost multisig salt found!");
          }
          knownSalts.add(salt);
          await frostInfo.updateKnownSalts(knownSalts, isar: mainDB.isar);
        }

        final keys = frost.deserializeKeys(keys: serializedKeys);
        await _saveSerializedKeys(serializedKeys);
        await _saveMultisigConfig(multisigConfig);

        final addressString = frost.addressForKeys(
          network: cryptoCurrency.network == CryptoCurrencyNetwork.main
              ? Network.Mainnet
              : Network.Testnet,
          keys: keys,
        );

        final publicKey = frost.scriptPubKeyForKeys(keys: keys);

        final address = Address(
          walletId: walletId,
          value: addressString,
          publicKey: publicKey.toUint8ListFromHex,
          derivationIndex: 0,
          derivationPath: null,
          subType: AddressSubType.receiving,
          type: AddressType.frostMS,
        );

        await mainDB.updateOrPutAddresses([address]);
      });

      unawaited(refresh());
    } catch (e, s) {
      Logging.instance.log(
        "recoverFromSerializedKeys failed: $e\n$s",
        level: LogLevel.Fatal,
      );
      rethrow;
    }
  }

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
  Future<void> updateChainHeight() async {
    final int height;
    try {
      final result = await electrumXClient.getBlockHeadTip();
      height = result["height"] as int;
    } catch (e) {
      rethrow;
    }

    await info.updateCachedChainHeight(
      newHeight: height,
      isar: mainDB.isar,
    );
  }

  @override
  Future<bool> pingCheck() async {
    try {
      final result = await electrumXClient.ping();
      return result;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> updateNode() async {
    await _updateElectrumX();
  }

  @override
  Future<bool> updateUTXOs() async {
    final address = await getCurrentReceivingAddress();

    try {
      final scriptHash = cryptoCurrency.pubKeyToScriptHash(
        pubKey: Uint8List.fromList(address!.publicKey),
      );

      final utxos = await electrumXClient.getUTXOs(scripthash: scriptHash);

      final List<UTXO> outputArray = [];

      for (int i = 0; i < utxos.length; i++) {
        final utxo = await _parseUTXO(
          jsonUTXO: utxos[i],
        );

        outputArray.add(utxo);
      }

      return await mainDB.updateUTXOs(walletId, outputArray);
    } catch (e, s) {
      Logging.instance.log(
        "Output fetch unsuccessful: $e\n$s",
        level: LogLevel.Error,
      );
      return false;
    }
  }

  // =================== Secure storage ========================================

  Future<String?> get getSerializedKeys async =>
      await secureStorageInterface.read(
        key: "{$walletId}_serializedFROSTKeys",
      );
  Future<void> _saveSerializedKeys(String keys) async {
    final current = await getSerializedKeys;

    if (current == null) {
      // do nothing
    } else if (current == keys) {
      // should never occur
    } else {
      // save current as prev gen before updating current
      await secureStorageInterface.write(
        key: "{$walletId}_serializedFROSTKeysPrevGen",
        value: current,
      );
    }

    await secureStorageInterface.write(
      key: "{$walletId}_serializedFROSTKeys",
      value: keys,
    );
  }

  Future<String?> get getSerializedKeysPrevGen async =>
      await secureStorageInterface.read(
        key: "{$walletId}_serializedFROSTKeysPrevGen",
      );

  Future<String?> get multisigConfig async => await secureStorageInterface.read(
        key: "{$walletId}_multisigConfig",
      );
  Future<String?> get multisigConfigPrevGen async =>
      await secureStorageInterface.read(
        key: "{$walletId}_multisigConfigPrevGen",
      );
  Future<void> _saveMultisigConfig(String multisigConfig) async {
    final current = await this.multisigConfig;

    if (current == null) {
      // do nothing
    } else if (current == multisigConfig) {
      // should never occur
    } else {
      // save current as prev gen before updating current
      await secureStorageInterface.write(
        key: "{$walletId}_multisigConfigPrevGen",
        value: current,
      );
    }

    await secureStorageInterface.write(
      key: "{$walletId}_multisigConfig",
      value: multisigConfig,
    );
  }

  Future<Uint8List?> get multisigId async {
    final id = await secureStorageInterface.read(
      key: "{$walletId}_multisigIdFROST",
    );
    if (id == null) {
      return null;
    } else {
      return id.toUint8ListFromHex;
    }
  }

  Future<void> saveMultisigId(Uint8List id) async =>
      await secureStorageInterface.write(
        key: "{$walletId}_multisigIdFROST",
        value: id.toHex,
      );

  Future<String?> get recoveryString async => await secureStorageInterface.read(
        key: "{$walletId}_recoveryStringFROST",
      );
  Future<void> saveRecoveryString(String recoveryString) async =>
      await secureStorageInterface.write(
        key: "{$walletId}_recoveryStringFROST",
        value: recoveryString,
      );

  // =================== Private ===============================================

  Future<ElectrumXNode> _getCurrentElectrumXNode() async {
    final node = getCurrentNode();

    return ElectrumXNode(
      address: node.host,
      port: node.port,
      name: node.name,
      useSSL: node.useSSL,
      id: node.id,
    );
  }

  Future<void> _updateElectrumX() async {
    final failovers = nodeService
        .failoverNodesFor(coin: cryptoCurrency.coin)
        .map((e) => ElectrumXNode(
              address: e.host,
              port: e.port,
              name: e.name,
              id: e.id,
              useSSL: e.useSSL,
            ))
        .toList();

    final newNode = await _getCurrentElectrumXNode();
    electrumXClient = ElectrumXClient.from(
      node: newNode,
      prefs: prefs,
      failovers: failovers,
    );
    electrumXCachedClient = CachedElectrumXClient.from(
      electrumXClient: electrumXClient,
    );
  }

  Future<UTXO> _parseUTXO({
    required Map<String, dynamic> jsonUTXO,
  }) async {
    final txn = await electrumXCachedClient.getTransaction(
      txHash: jsonUTXO["tx_hash"] as String,
      verbose: true,
      coin: cryptoCurrency.coin,
    );

    final vout = jsonUTXO["tx_pos"] as int;

    final outputs = txn["vout"] as List;

    String? scriptPubKey;
    String? utxoOwnerAddress;
    // get UTXO owner address
    for (final output in outputs) {
      if (output["n"] == vout) {
        scriptPubKey = output["scriptPubKey"]?["hex"] as String?;
        utxoOwnerAddress =
            output["scriptPubKey"]?["addresses"]?[0] as String? ??
                output["scriptPubKey"]?["address"] as String?;
      }
    }

    final utxo = UTXO(
      walletId: walletId,
      txid: txn["txid"] as String,
      vout: vout,
      value: jsonUTXO["value"] as int,
      name: "",
      isBlocked: false,
      blockedReason: null,
      isCoinbase: txn["is_coinbase"] as bool? ?? false,
      blockHash: txn["blockhash"] as String?,
      blockHeight: jsonUTXO["height"] as int?,
      blockTime: txn["blocktime"] as int?,
      address: utxoOwnerAddress,
    );

    return utxo;
  }
}
