import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bech32/bech32.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoindart/bitcoindart.dart';
import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:crypto/crypto.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:stackwallet/electrumx_rpc/cached_electrumx.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/models.dart' as models;
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart';
import 'package:stackwallet/models/paymint/utxo_model.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/notifications_api.dart';
import 'package:stackwallet/services/price.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

const int MINIMUM_CONFIRMATIONS = 1;
const int DUST_LIMIT = 294;

const String GENESIS_HASH_MAINNET =
    "0000ee0784c195317ac95623e22fddb8c7b8825dc3998e0bb924d66866eccf4c";
const String GENESIS_HASH_TESTNET =
    "0000594ada5310b367443ee0afd4fa3d0bbd5850ea4e33cdc7d6a904a7ec7c90";

enum DerivePathType { bip44, bip49, bip84 }

bip32.BIP32 getBip32Node(
  int chain,
  int index,
  String mnemonic,
  NetworkType network,
  DerivePathType derivePathType,
) {
  final root = getBip32Root(mnemonic, network);

  final node = getBip32NodeFromRoot(chain, index, root, derivePathType);
  return node;
}

/// wrapper for compute()
bip32.BIP32 getBip32NodeWrapper(
  Tuple5<int, int, String, NetworkType, DerivePathType> args,
) {
  return getBip32Node(
    args.item1,
    args.item2,
    args.item3,
    args.item4,
    args.item5,
  );
}

bip32.BIP32 getBip32NodeFromRoot(
  int chain,
  int index,
  bip32.BIP32 root,
  DerivePathType derivePathType,
) {
  String coinType;
  switch (root.network.wif) {
    case 0x6c: // PART mainnet wif
      coinType = "44"; // PART mainnet
      break;
    default:
      throw Exception("Invalid Particl network type used!");
  }
  switch (derivePathType) {
    case DerivePathType.bip44:
      return root.derivePath("m/44'/$coinType'/0'/$chain/$index");
    case DerivePathType.bip49:
      return root.derivePath("m/49'/$coinType'/0'/$chain/$index");
    case DerivePathType.bip84:
      return root.derivePath("m/84'/$coinType'/0'/$chain/$index");
    default:
      throw Exception("DerivePathType must not be null.");
  }
}

/// wrapper for compute()
bip32.BIP32 getBip32NodeFromRootWrapper(
  Tuple4<int, int, bip32.BIP32, DerivePathType> args,
) {
  return getBip32NodeFromRoot(
    args.item1,
    args.item2,
    args.item3,
    args.item4,
  );
}

bip32.BIP32 getBip32Root(String mnemonic, NetworkType network) {
  final seed = bip39.mnemonicToSeed(mnemonic);
  final networkType = bip32.NetworkType(
    wif: network.wif,
    bip32: bip32.Bip32Type(
      public: network.bip32.public,
      private: network.bip32.private,
    ),
  );

  final root = bip32.BIP32.fromSeed(seed, networkType);
  return root;
}

/// wrapper for compute()
bip32.BIP32 getBip32RootWrapper(Tuple2<String, NetworkType> args) {
  return getBip32Root(args.item1, args.item2);
}

class ParticlWallet extends CoinServiceAPI {
  static const integrationTestFlag =
      bool.fromEnvironment("IS_INTEGRATION_TEST");

  final _prefs = Prefs.instance;

  Timer? timer;
  late Coin _coin;

  late final TransactionNotificationTracker txTracker;

  NetworkType get _network {
    switch (coin) {
      case Coin.particl:
        return particl;
      default:
        throw Exception("Invalid network type!");
    }
  }

  List<UtxoObject> outputsList = [];

  @override
  set isFavorite(bool markFavorite) {
    DB.instance.put<dynamic>(
        boxName: walletId, key: "isFavorite", value: markFavorite);
  }

  @override
  bool get isFavorite {
    try {
      return DB.instance.get<dynamic>(boxName: walletId, key: "isFavorite")
          as bool;
    } catch (e, s) {
      Logging.instance
          .log("isFavorite fetch failed: $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Coin get coin => _coin;

  @override
  Future<List<String>> get allOwnAddresses =>
      _allOwnAddresses ??= _fetchAllOwnAddresses();
  Future<List<String>>? _allOwnAddresses;

  Future<UtxoData>? _utxoData;
  Future<UtxoData> get utxoData => _utxoData ??= _fetchUtxoData();

  @override
  Future<List<UtxoObject>> get unspentOutputs async =>
      (await utxoData).unspentOutputArray;

  @override
  Future<Decimal> get availableBalance async {
    final data = await utxoData;
    return Format.satoshisToAmount(
        data.satoshiBalance - data.satoshiBalanceUnconfirmed);
  }

  @override
  Future<Decimal> get pendingBalance async {
    final data = await utxoData;
    return Format.satoshisToAmount(data.satoshiBalanceUnconfirmed);
  }

  @override
  Future<Decimal> get balanceMinusMaxFee async =>
      (await availableBalance) -
      (Decimal.fromInt((await maxFee)) / Decimal.fromInt(Constants.satsPerCoin))
          .toDecimal();

  @override
  Future<Decimal> get totalBalance async {
    if (!isActive) {
      final totalBalance = DB.instance
          .get<dynamic>(boxName: walletId, key: 'totalBalance') as int?;
      if (totalBalance == null) {
        final data = await utxoData;
        return Format.satoshisToAmount(data.satoshiBalance);
      } else {
        return Format.satoshisToAmount(totalBalance);
      }
    }
    final data = await utxoData;
    return Format.satoshisToAmount(data.satoshiBalance);
  }

  @override
  Future<String> get currentReceivingAddress => _currentReceivingAddress ??=
      _getCurrentAddressForChain(0, DerivePathType.bip84);
  Future<String>? _currentReceivingAddress;

  Future<String> get currentLegacyReceivingAddress =>
      _currentReceivingAddressP2PKH ??=
          _getCurrentAddressForChain(0, DerivePathType.bip44);
  Future<String>? _currentReceivingAddressP2PKH;

  Future<String> get currentReceivingAddressP2SH =>
      _currentReceivingAddressP2SH ??=
          _getCurrentAddressForChain(0, DerivePathType.bip49);
  Future<String>? _currentReceivingAddressP2SH;

  @override
  Future<void> exit() async {
    _hasCalledExit = true;
    timer?.cancel();
    timer = null;
    stopNetworkAlivePinging();
  }

  bool _hasCalledExit = false;

  @override
  bool get hasCalledExit => _hasCalledExit;

  @override
  Future<FeeObject> get fees => _feeObject ??= _getFees();
  Future<FeeObject>? _feeObject;

  @override
  Future<int> get maxFee async {
    final fee = (await fees).fast as String;
    final satsFee = Decimal.parse(fee) * Decimal.fromInt(Constants.satsPerCoin);
    return satsFee.floor().toBigInt().toInt();
  }

  @override
  Future<List<String>> get mnemonic => _getMnemonicList();

  Future<int> get chainHeight async {
    try {
      final result = await _electrumXClient.getBlockHeadTip();
      return result["height"] as int;
    } catch (e, s) {
      Logging.instance.log("Exception caught in chainHeight: $e\n$s",
          level: LogLevel.Error);
      return -1;
    }
  }

  int get storedChainHeight {
    final storedHeight = DB.instance
        .get<dynamic>(boxName: walletId, key: "storedChainHeight") as int?;
    return storedHeight ?? 0;
  }

  Future<void> updateStoredChainHeight({required int newHeight}) async {
    await DB.instance.put<dynamic>(
        boxName: walletId, key: "storedChainHeight", value: newHeight);
  }

  DerivePathType addressType({required String address}) {
    Uint8List? decodeBase58;
    Segwit? decodeBech32;
    try {
      decodeBase58 = bs58check.decode(address);
    } catch (err) {
      // Base58check decode fail
    }
    if (decodeBase58 != null) {
      if (decodeBase58[0] == _network.pubKeyHash) {
        // P2PKH
        return DerivePathType.bip44;
      }
      if (decodeBase58[0] == _network.scriptHash) {
        // P2SH
        return DerivePathType.bip49;
      }
      throw ArgumentError('Invalid version or Network mismatch');
    } else {
      try {
        decodeBech32 = segwit.decode(address);
      } catch (err) {
        // Bech32 decode fail
      }
      if (_network.bech32 != decodeBech32!.hrp) {
        throw ArgumentError('Invalid prefix or Network mismatch');
      }
      if (decodeBech32.version != 0) {
        throw ArgumentError('Invalid address version');
      }
      // P2WPKH
      return DerivePathType.bip84;
    }
  }

  bool longMutex = false;

  @override
  Future<void> recoverFromMnemonic({
    required String mnemonic,
    required int maxUnusedAddressGap,
    required int maxNumberOfIndexesToCheck,
    required int height,
  }) async {
    longMutex = true;
    final start = DateTime.now();
    try {
      Logging.instance.log("IS_INTEGRATION_TEST: $integrationTestFlag",
          level: LogLevel.Info);
      if (!integrationTestFlag) {
        final features = await electrumXClient.getServerFeatures();
        Logging.instance.log("features: $features", level: LogLevel.Info);
        switch (coin) {
          case Coin.particl:
            if (features['genesis_hash'] != GENESIS_HASH_MAINNET) {
              throw Exception("genesis hash does not match main net!");
            }
            break;
            break;
          default:
            throw Exception(
                "Attempted to generate a ParticlWallet using a non particl coin type: ${coin.name}");
        }
        // if (_networkType == BasicNetworkType.main) {
        //   if (features['genesis_hash'] != GENESIS_HASH_MAINNET) {
        //     throw Exception("genesis hash does not match main net!");
        //   }
        // } else if (_networkType == BasicNetworkType.test) {
        //   if (features['genesis_hash'] != GENESIS_HASH_TESTNET) {
        //     throw Exception("genesis hash does not match test net!");
        //   }
        // }
      }
      // check to make sure we aren't overwriting a mnemonic
      // this should never fail
      if ((await _secureStore.read(key: '${_walletId}_mnemonic')) != null) {
        longMutex = false;
        throw Exception("Attempted to overwrite mnemonic on restore!");
      }
      await _secureStore.write(
          key: '${_walletId}_mnemonic', value: mnemonic.trim());
      await _recoverWalletFromBIP32SeedPhrase(
        mnemonic: mnemonic.trim(),
        maxUnusedAddressGap: maxUnusedAddressGap,
        maxNumberOfIndexesToCheck: maxNumberOfIndexesToCheck,
      );
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from recoverFromMnemonic(): $e\n$s",
          level: LogLevel.Error);
      longMutex = false;
      rethrow;
    }
    longMutex = false;

    final end = DateTime.now();
    Logging.instance.log(
        "$walletName recovery time: ${end.difference(start).inMilliseconds} millis",
        level: LogLevel.Info);
  }

  Future<Map<String, dynamic>> _checkGaps(
      int maxNumberOfIndexesToCheck,
      int maxUnusedAddressGap,
      int txCountBatchSize,
      bip32.BIP32 root,
      DerivePathType type,
      int account) async {
    List<String> addressArray = [];
    int returningIndex = -1;
    Map<String, Map<String, String>> derivations = {};
    int gapCounter = 0;
    for (int index = 0;
        index < maxNumberOfIndexesToCheck && gapCounter < maxUnusedAddressGap;
        index += txCountBatchSize) {
      List<String> iterationsAddressArray = [];
      Logging.instance.log(
          "index: $index, \t GapCounter $account ${type.name}: $gapCounter",
          level: LogLevel.Info);

      final _id = "k_$index";
      Map<String, String> txCountCallArgs = {};
      final Map<String, dynamic> receivingNodes = {};

      for (int j = 0; j < txCountBatchSize; j++) {
        final node = await compute(
          getBip32NodeFromRootWrapper,
          Tuple4(
            account,
            index + j,
            root,
            type,
          ),
        );
        String? address;
        switch (type) {
          case DerivePathType.bip44:
            address = P2PKH(
                    data: PaymentData(pubkey: node.publicKey),
                    network: _network)
                .data
                .address!;
            break;
          case DerivePathType.bip49:
            address = P2SH(
                    data: PaymentData(
                        redeem: P2WPKH(
                                data: PaymentData(pubkey: node.publicKey),
                                network: _network,
                                overridePrefix: particl.bech32!)
                            .data),
                    network: _network)
                .data
                .address!;
            break;
          case DerivePathType.bip84:
            address = P2WPKH(
                    network: _network,
                    data: PaymentData(pubkey: node.publicKey))
                .data
                .address!;
            break;
          default:
            throw Exception("No Path type $type exists");
        }
        receivingNodes.addAll({
          "${_id}_$j": {
            "node": node,
            "address": address,
          }
        });
        txCountCallArgs.addAll({
          "${_id}_$j": address,
        });
      }

      // get address tx counts
      final counts = await _getBatchTxCount(addresses: txCountCallArgs);

      // check and add appropriate addresses
      for (int k = 0; k < txCountBatchSize; k++) {
        int count = counts["${_id}_$k"]!;
        if (count > 0) {
          final node = receivingNodes["${_id}_$k"];
          // add address to array
          addressArray.add(node["address"] as String);
          iterationsAddressArray.add(node["address"] as String);
          // set current index
          returningIndex = index + k;
          // reset counter
          gapCounter = 0;
          // add info to derivations
          derivations[node["address"] as String] = {
            "pubKey": Format.uint8listToString(
                (node["node"] as bip32.BIP32).publicKey),
            "wif": (node["node"] as bip32.BIP32).toWIF(),
          };
        }

        // increase counter when no tx history found
        if (count == 0) {
          gapCounter++;
        }
      }
      // cache all the transactions while waiting for the current function to finish.
      unawaited(getTransactionCacheEarly(iterationsAddressArray));
    }
    return {
      "addressArray": addressArray,
      "index": returningIndex,
      "derivations": derivations
    };
  }

  Future<void> getTransactionCacheEarly(List<String> allAddresses) async {
    try {
      final List<Map<String, dynamic>> allTxHashes =
          await _fetchHistory(allAddresses);
      for (final txHash in allTxHashes) {
        try {
          unawaited(cachedElectrumXClient.getTransaction(
            txHash: txHash["tx_hash"] as String,
            verbose: true,
            coin: coin,
          ));
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      //
    }
  }

  Future<void> _recoverWalletFromBIP32SeedPhrase({
    required String mnemonic,
    int maxUnusedAddressGap = 20,
    int maxNumberOfIndexesToCheck = 1000,
  }) async {
    longMutex = true;

    Map<String, Map<String, String>> p2pkhReceiveDerivations = {};
    Map<String, Map<String, String>> p2shReceiveDerivations = {};
    Map<String, Map<String, String>> p2wpkhReceiveDerivations = {};
    Map<String, Map<String, String>> p2pkhChangeDerivations = {};
    Map<String, Map<String, String>> p2shChangeDerivations = {};
    Map<String, Map<String, String>> p2wpkhChangeDerivations = {};

    final root = await compute(getBip32RootWrapper, Tuple2(mnemonic, _network));

    List<String> p2pkhReceiveAddressArray = [];
    List<String> p2shReceiveAddressArray = [];
    List<String> p2wpkhReceiveAddressArray = [];
    int p2pkhReceiveIndex = -1;
    int p2shReceiveIndex = -1;
    int p2wpkhReceiveIndex = -1;

    List<String> p2pkhChangeAddressArray = [];
    List<String> p2shChangeAddressArray = [];
    List<String> p2wpkhChangeAddressArray = [];
    int p2pkhChangeIndex = -1;
    int p2shChangeIndex = -1;
    int p2wpkhChangeIndex = -1;

    // actual size is 36 due to p2pkh, p2sh, and p2wpkh so 12x3
    const txCountBatchSize = 12;

    try {
      // receiving addresses
      Logging.instance
          .log("checking receiving addresses...", level: LogLevel.Info);
      final resultReceive44 = _checkGaps(maxNumberOfIndexesToCheck,
          maxUnusedAddressGap, txCountBatchSize, root, DerivePathType.bip44, 0);

      final resultReceive49 = _checkGaps(maxNumberOfIndexesToCheck,
          maxUnusedAddressGap, txCountBatchSize, root, DerivePathType.bip49, 0);

      final resultReceive84 = _checkGaps(maxNumberOfIndexesToCheck,
          maxUnusedAddressGap, txCountBatchSize, root, DerivePathType.bip84, 0);

      Logging.instance
          .log("checking change addresses...", level: LogLevel.Info);
      // change addresses
      final resultChange44 = _checkGaps(maxNumberOfIndexesToCheck,
          maxUnusedAddressGap, txCountBatchSize, root, DerivePathType.bip44, 1);

      final resultChange49 = _checkGaps(maxNumberOfIndexesToCheck,
          maxUnusedAddressGap, txCountBatchSize, root, DerivePathType.bip49, 1);

      final resultChange84 = _checkGaps(maxNumberOfIndexesToCheck,
          maxUnusedAddressGap, txCountBatchSize, root, DerivePathType.bip84, 1);

      await Future.wait([
        resultReceive44,
        resultReceive49,
        resultReceive84,
        resultChange44,
        resultChange49,
        resultChange84
      ]);

      p2pkhReceiveAddressArray =
          (await resultReceive44)['addressArray'] as List<String>;
      p2pkhReceiveIndex = (await resultReceive44)['index'] as int;
      p2pkhReceiveDerivations = (await resultReceive44)['derivations']
          as Map<String, Map<String, String>>;

      p2shReceiveAddressArray =
          (await resultReceive49)['addressArray'] as List<String>;
      p2shReceiveIndex = (await resultReceive49)['index'] as int;
      p2shReceiveDerivations = (await resultReceive49)['derivations']
          as Map<String, Map<String, String>>;

      p2wpkhReceiveAddressArray =
          (await resultReceive84)['addressArray'] as List<String>;
      p2wpkhReceiveIndex = (await resultReceive84)['index'] as int;
      p2wpkhReceiveDerivations = (await resultReceive84)['derivations']
          as Map<String, Map<String, String>>;

      p2pkhChangeAddressArray =
          (await resultChange44)['addressArray'] as List<String>;
      p2pkhChangeIndex = (await resultChange44)['index'] as int;
      p2pkhChangeDerivations = (await resultChange44)['derivations']
          as Map<String, Map<String, String>>;

      p2shChangeAddressArray =
          (await resultChange49)['addressArray'] as List<String>;
      p2shChangeIndex = (await resultChange49)['index'] as int;
      p2shChangeDerivations = (await resultChange49)['derivations']
          as Map<String, Map<String, String>>;

      p2wpkhChangeAddressArray =
          (await resultChange84)['addressArray'] as List<String>;
      p2wpkhChangeIndex = (await resultChange84)['index'] as int;
      p2wpkhChangeDerivations = (await resultChange84)['derivations']
          as Map<String, Map<String, String>>;

      // save the derivations (if any)
      if (p2pkhReceiveDerivations.isNotEmpty) {
        await addDerivations(
            chain: 0,
            derivePathType: DerivePathType.bip44,
            derivationsToAdd: p2pkhReceiveDerivations);
      }
      if (p2shReceiveDerivations.isNotEmpty) {
        await addDerivations(
            chain: 0,
            derivePathType: DerivePathType.bip49,
            derivationsToAdd: p2shReceiveDerivations);
      }
      if (p2wpkhReceiveDerivations.isNotEmpty) {
        await addDerivations(
            chain: 0,
            derivePathType: DerivePathType.bip84,
            derivationsToAdd: p2wpkhReceiveDerivations);
      }
      if (p2pkhChangeDerivations.isNotEmpty) {
        await addDerivations(
            chain: 1,
            derivePathType: DerivePathType.bip44,
            derivationsToAdd: p2pkhChangeDerivations);
      }
      if (p2shChangeDerivations.isNotEmpty) {
        await addDerivations(
            chain: 1,
            derivePathType: DerivePathType.bip49,
            derivationsToAdd: p2shChangeDerivations);
      }
      if (p2wpkhChangeDerivations.isNotEmpty) {
        await addDerivations(
            chain: 1,
            derivePathType: DerivePathType.bip84,
            derivationsToAdd: p2wpkhChangeDerivations);
      }

      // If restoring a wallet that never received any funds, then set receivingArray manually
      // If we didn't do this, it'd store an empty array
      if (p2pkhReceiveIndex == -1) {
        final address =
            await _generateAddressForChain(0, 0, DerivePathType.bip44);
        p2pkhReceiveAddressArray.add(address);
        p2pkhReceiveIndex = 0;
      }
      if (p2shReceiveIndex == -1) {
        final address =
            await _generateAddressForChain(0, 0, DerivePathType.bip49);
        p2shReceiveAddressArray.add(address);
        p2shReceiveIndex = 0;
      }
      if (p2wpkhReceiveIndex == -1) {
        final address =
            await _generateAddressForChain(0, 0, DerivePathType.bip84);
        p2wpkhReceiveAddressArray.add(address);
        p2wpkhReceiveIndex = 0;
      }

      // If restoring a wallet that never sent any funds with change, then set changeArray
      // manually. If we didn't do this, it'd store an empty array.
      if (p2pkhChangeIndex == -1) {
        final address =
            await _generateAddressForChain(1, 0, DerivePathType.bip44);
        p2pkhChangeAddressArray.add(address);
        p2pkhChangeIndex = 0;
      }
      if (p2shChangeIndex == -1) {
        final address =
            await _generateAddressForChain(1, 0, DerivePathType.bip49);
        p2shChangeAddressArray.add(address);
        p2shChangeIndex = 0;
      }
      if (p2wpkhChangeIndex == -1) {
        final address =
            await _generateAddressForChain(1, 0, DerivePathType.bip84);
        p2wpkhChangeAddressArray.add(address);
        p2wpkhChangeIndex = 0;
      }

      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: 'receivingAddressesP2WPKH',
          value: p2wpkhReceiveAddressArray);
      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: 'changeAddressesP2WPKH',
          value: p2wpkhChangeAddressArray);
      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: 'receivingAddressesP2PKH',
          value: p2pkhReceiveAddressArray);
      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: 'changeAddressesP2PKH',
          value: p2pkhChangeAddressArray);
      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: 'receivingAddressesP2SH',
          value: p2shReceiveAddressArray);
      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: 'changeAddressesP2SH',
          value: p2shChangeAddressArray);
      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: 'receivingIndexP2WPKH',
          value: p2wpkhReceiveIndex);
      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: 'changeIndexP2WPKH',
          value: p2wpkhChangeIndex);
      await DB.instance.put<dynamic>(
          boxName: walletId, key: 'changeIndexP2PKH', value: p2pkhChangeIndex);
      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: 'receivingIndexP2PKH',
          value: p2pkhReceiveIndex);
      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: 'receivingIndexP2SH',
          value: p2shReceiveIndex);
      await DB.instance.put<dynamic>(
          boxName: walletId, key: 'changeIndexP2SH', value: p2shChangeIndex);
      await DB.instance
          .put<dynamic>(boxName: walletId, key: "id", value: _walletId);
      await DB.instance
          .put<dynamic>(boxName: walletId, key: "isFavorite", value: false);

      longMutex = false;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _recoverWalletFromBIP32SeedPhrase(): $e\n$s",
          level: LogLevel.Error);

      longMutex = false;
      rethrow;
    }
  }

  Future<bool> refreshIfThereIsNewData() async {
    if (longMutex) return false;
    if (_hasCalledExit) return false;
    Logging.instance.log("refreshIfThereIsNewData", level: LogLevel.Info);

    try {
      bool needsRefresh = false;
      Set<String> txnsToCheck = {};

      for (final String txid in txTracker.pendings) {
        if (!txTracker.wasNotifiedConfirmed(txid)) {
          txnsToCheck.add(txid);
        }
      }

      for (String txid in txnsToCheck) {
        final txn = await electrumXClient.getTransaction(txHash: txid);
        int confirmations = txn["confirmations"] as int? ?? 0;
        bool isUnconfirmed = confirmations < MINIMUM_CONFIRMATIONS;
        if (!isUnconfirmed) {
          // unconfirmedTxs = {};
          needsRefresh = true;
          break;
        }
      }
      if (!needsRefresh) {
        var allOwnAddresses = await _fetchAllOwnAddresses();
        List<Map<String, dynamic>> allTxs =
            await _fetchHistory(allOwnAddresses);
        final txData = await transactionData;
        for (Map<String, dynamic> transaction in allTxs) {
          if (txData.findTransaction(transaction['tx_hash'] as String) ==
              null) {
            Logging.instance.log(
                " txid not found in address history already ${transaction['tx_hash']}",
                level: LogLevel.Info);
            needsRefresh = true;
            break;
          }
        }
      }
      return needsRefresh;
    } catch (e, s) {
      Logging.instance.log(
          "Exception caught in refreshIfThereIsNewData: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> getAllTxsToWatch(
    TransactionData txData,
  ) async {
    if (_hasCalledExit) return;
    List<models.Transaction> unconfirmedTxnsToNotifyPending = [];
    List<models.Transaction> unconfirmedTxnsToNotifyConfirmed = [];

    for (final chunk in txData.txChunks) {
      for (final tx in chunk.transactions) {
        if (tx.confirmedStatus) {
          // get all transactions that were notified as pending but not as confirmed
          if (txTracker.wasNotifiedPending(tx.txid) &&
              !txTracker.wasNotifiedConfirmed(tx.txid)) {
            unconfirmedTxnsToNotifyConfirmed.add(tx);
          }
        } else {
          // get all transactions that were not notified as pending yet
          if (!txTracker.wasNotifiedPending(tx.txid)) {
            unconfirmedTxnsToNotifyPending.add(tx);
          }
        }
      }
    }

    // notify on unconfirmed transactions
    for (final tx in unconfirmedTxnsToNotifyPending) {
      if (tx.txType == "Received") {
        unawaited(NotificationApi.showNotification(
          title: "Incoming transaction",
          body: walletName,
          walletId: walletId,
          iconAssetName: Assets.svg.iconFor(coin: coin),
          date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
          shouldWatchForUpdates: tx.confirmations < MINIMUM_CONFIRMATIONS,
          coinName: coin.name,
          txid: tx.txid,
          confirmations: tx.confirmations,
          requiredConfirmations: MINIMUM_CONFIRMATIONS,
        ));
        await txTracker.addNotifiedPending(tx.txid);
      } else if (tx.txType == "Sent") {
        unawaited(NotificationApi.showNotification(
          title: "Sending transaction",
          body: walletName,
          walletId: walletId,
          iconAssetName: Assets.svg.iconFor(coin: coin),
          date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
          shouldWatchForUpdates: tx.confirmations < MINIMUM_CONFIRMATIONS,
          coinName: coin.name,
          txid: tx.txid,
          confirmations: tx.confirmations,
          requiredConfirmations: MINIMUM_CONFIRMATIONS,
        ));
        await txTracker.addNotifiedPending(tx.txid);
      }
    }

    // notify on confirmed
    for (final tx in unconfirmedTxnsToNotifyConfirmed) {
      if (tx.txType == "Received") {
        unawaited(NotificationApi.showNotification(
          title: "Incoming transaction confirmed",
          body: walletName,
          walletId: walletId,
          iconAssetName: Assets.svg.iconFor(coin: coin),
          date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
          shouldWatchForUpdates: false,
          coinName: coin.name,
        ));
        await txTracker.addNotifiedConfirmed(tx.txid);
      } else if (tx.txType == "Sent") {
        unawaited(NotificationApi.showNotification(
          title: "Outgoing transaction confirmed",
          body: walletName,
          walletId: walletId,
          iconAssetName: Assets.svg.iconFor(coin: coin),
          date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
          shouldWatchForUpdates: false,
          coinName: coin.name,
        ));
        await txTracker.addNotifiedConfirmed(tx.txid);
      }
    }
  }

  bool _shouldAutoSync = false;

  @override
  bool get shouldAutoSync => _shouldAutoSync;

  @override
  set shouldAutoSync(bool shouldAutoSync) {
    if (_shouldAutoSync != shouldAutoSync) {
      _shouldAutoSync = shouldAutoSync;
      if (!shouldAutoSync) {
        timer?.cancel();
        timer = null;
        stopNetworkAlivePinging();
      } else {
        startNetworkAlivePinging();
        refresh();
      }
    }
  }

  @override
  bool get isRefreshing => refreshMutex;

  bool refreshMutex = false;

  //TODO Show percentages properly/more consistently
  /// Refreshes display data for the wallet
  @override
  Future<void> refresh() async {
    if (refreshMutex) {
      Logging.instance.log("$walletId $walletName refreshMutex denied",
          level: LogLevel.Info);
      return;
    } else {
      refreshMutex = true;
    }

    try {
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.syncing,
          walletId,
          coin,
        ),
      );

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.0, walletId));

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.1, walletId));

      final currentHeight = await chainHeight;
      const storedHeight = 1; //await storedChainHeight;

      Logging.instance
          .log("chain height: $currentHeight", level: LogLevel.Info);
      Logging.instance
          .log("cached height: $storedHeight", level: LogLevel.Info);

      if (currentHeight != storedHeight) {
        if (currentHeight != -1) {
          Logging.instance
              .log("Can update chain: $currentHeight", level: LogLevel.Info);
          // -1 failed to fetch current height
          unawaited(updateStoredChainHeight(newHeight: currentHeight));
        }

        GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.2, walletId));
        final changeAddressForTransactions =
            _checkChangeAddressForTransactions(DerivePathType.bip84);

        GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.3, walletId));
        final currentReceivingAddressesForTransactions =
            _checkCurrentReceivingAddressesForTransactions();

        final newTxData = _fetchTransactionData();
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.50, walletId));

        final newUtxoData = _fetchUtxoData();
        final feeObj = _getFees();
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.60, walletId));

        _transactionData = Future(() => newTxData);

        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.70, walletId));
        _feeObject = Future(() => feeObj);
        _utxoData = Future(() => newUtxoData);
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.80, walletId));

        final allTxsToWatch = getAllTxsToWatch(await newTxData);
        await Future.wait([
          newTxData,
          changeAddressForTransactions,
          currentReceivingAddressesForTransactions,
          newUtxoData,
          feeObj,
          allTxsToWatch,
        ]);
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.90, walletId));
      }

      refreshMutex = false;
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(1.0, walletId));
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          coin,
        ),
      );

      if (shouldAutoSync) {
        timer ??= Timer.periodic(const Duration(seconds: 30), (timer) async {
          Logging.instance.log(
              "Periodic refresh check for $walletId $walletName in object instance: $hashCode",
              level: LogLevel.Info);
          // chain height check currently broken
          // if ((await chainHeight) != (await storedChainHeight)) {
          if (await refreshIfThereIsNewData()) {
            await refresh();
            GlobalEventBus.instance.fire(UpdatedInBackgroundEvent(
                "New data found in $walletId $walletName in background!",
                walletId));
          }
          // }
        });
      }
    } catch (error, strace) {
      refreshMutex = false;
      GlobalEventBus.instance.fire(
        NodeConnectionStatusChangedEvent(
          NodeConnectionStatus.disconnected,
          walletId,
          coin,
        ),
      );
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.unableToSync,
          walletId,
          coin,
        ),
      );
      Logging.instance.log(
          "Caught exception in refreshWalletData(): $error\n$strace",
          level: LogLevel.Error);
    }
  }

  @override
  Future<Map<String, dynamic>> prepareSend({
    required String address,
    required int satoshiAmount,
    Map<String, dynamic>? args,
  }) async {
    try {
      final feeRateType = args?["feeRate"];
      final feeRateAmount = args?["feeRateAmount"];
      if (feeRateType is FeeRateType || feeRateAmount is int) {
        late final int rate;
        if (feeRateType is FeeRateType) {
          int fee = 0;
          final feeObject = await fees;
          switch (feeRateType) {
            case FeeRateType.fast:
              fee = feeObject.fast;
              break;
            case FeeRateType.average:
              fee = feeObject.medium;
              break;
            case FeeRateType.slow:
              fee = feeObject.slow;
              break;
          }
          rate = fee;
        } else {
          rate = feeRateAmount as int;
        }

        // check for send all
        bool isSendAll = false;
        final balance = Format.decimalAmountToSatoshis(await availableBalance);
        if (satoshiAmount == balance) {
          isSendAll = true;
        }

        final txData =
            await coinSelection(satoshiAmount, rate, address, isSendAll);

        Logging.instance.log("prepare send: $txData", level: LogLevel.Info);
        try {
          if (txData is int) {
            switch (txData) {
              case 1:
                throw Exception("Insufficient balance!");
              case 2:
                throw Exception(
                    "Insufficient funds to pay for transaction fee!");
              default:
                throw Exception("Transaction failed with error code $txData");
            }
          } else {
            final hex = txData["hex"];

            if (hex is String) {
              final fee = txData["fee"] as int;
              final vSize = txData["vSize"] as int;

              Logging.instance
                  .log("prepared txHex: $hex", level: LogLevel.Info);
              Logging.instance.log("prepared fee: $fee", level: LogLevel.Info);
              Logging.instance
                  .log("prepared vSize: $vSize", level: LogLevel.Info);

              // fee should never be less than vSize sanity check
              if (fee < vSize) {
                throw Exception(
                    "Error in fee calculation: Transaction fee cannot be less than vSize");
              }

              return txData as Map<String, dynamic>;
            } else {
              throw Exception("prepared hex is not a String!!!");
            }
          }
        } catch (e, s) {
          Logging.instance.log("Exception rethrown from prepareSend(): $e\n$s",
              level: LogLevel.Error);
          rethrow;
        }
      } else {
        throw ArgumentError("Invalid fee rate argument provided!");
      }
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from prepareSend(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    try {
      Logging.instance.log("confirmSend txData: $txData", level: LogLevel.Info);

      final hex = txData["hex"] as String;

      final txHash = await _electrumXClient.broadcastTransaction(rawTx: hex);
      Logging.instance.log("Sent txHash: $txHash", level: LogLevel.Info);

      return txHash;
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from confirmSend(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<String> send({
    required String toAddress,
    required int amount,
    Map<String, String> args = const {},
  }) async {
    try {
      final txData = await prepareSend(
          address: toAddress, satoshiAmount: amount, args: args);
      final txHash = await confirmSend(txData: txData);
      return txHash;
    } catch (e, s) {
      Logging.instance
          .log("Exception rethrown from send(): $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<bool> testNetworkConnection() async {
    try {
      final result = await _electrumXClient.ping();
      return result;
    } catch (_) {
      return false;
    }
  }

  Timer? _networkAliveTimer;

  void startNetworkAlivePinging() {
    // call once on start right away
    _periodicPingCheck();

    // then periodically check
    _networkAliveTimer = Timer.periodic(
      Constants.networkAliveTimerDuration,
      (_) async {
        _periodicPingCheck();
      },
    );
  }

  void _periodicPingCheck() async {
    bool hasNetwork = await testNetworkConnection();
    _isConnected = hasNetwork;
    if (_isConnected != hasNetwork) {
      NodeConnectionStatus status = hasNetwork
          ? NodeConnectionStatus.connected
          : NodeConnectionStatus.disconnected;
      GlobalEventBus.instance
          .fire(NodeConnectionStatusChangedEvent(status, walletId, coin));
    }
  }

  void stopNetworkAlivePinging() {
    _networkAliveTimer?.cancel();
    _networkAliveTimer = null;
  }

  bool _isConnected = false;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> initializeNew() async {
    Logging.instance
        .log("Generating new ${coin.prettyName} wallet.", level: LogLevel.Info);

    if ((DB.instance.get<dynamic>(boxName: walletId, key: "id")) != null) {
      throw Exception(
          "Attempted to initialize a new wallet using an existing wallet ID!");
    }

    await _prefs.init();
    try {
      await _generateNewWallet();
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from initializeNew(): $e\n$s",
          level: LogLevel.Fatal);
      rethrow;
    }
    await Future.wait([
      DB.instance.put<dynamic>(boxName: walletId, key: "id", value: walletId),
      DB.instance
          .put<dynamic>(boxName: walletId, key: "isFavorite", value: false),
    ]);
  }

  @override
  Future<void> initializeExisting() async {
    Logging.instance.log("Opening existing ${coin.prettyName} wallet.",
        level: LogLevel.Info);

    if ((DB.instance.get<dynamic>(boxName: walletId, key: "id")) == null) {
      throw Exception(
          "Attempted to initialize an existing wallet using an unknown wallet ID!");
    }
    await _prefs.init();
    final data =
        DB.instance.get<dynamic>(boxName: walletId, key: "latest_tx_model")
            as TransactionData?;
    if (data != null) {
      _transactionData = Future(() => data);
    }
  }

  @override
  Future<TransactionData> get transactionData =>
      _transactionData ??= _fetchTransactionData();
  Future<TransactionData>? _transactionData;

  @override
  bool validateAddress(String address) {
    return Address.validateAddress(address, _network, particl.bech32!);
  }

  @override
  String get walletId => _walletId;
  late String _walletId;

  @override
  String get walletName => _walletName;
  late String _walletName;

  // setter for updating on rename
  @override
  set walletName(String newName) => _walletName = newName;

  late ElectrumX _electrumXClient;

  ElectrumX get electrumXClient => _electrumXClient;

  late CachedElectrumX _cachedElectrumXClient;

  CachedElectrumX get cachedElectrumXClient => _cachedElectrumXClient;

  late SecureStorageInterface _secureStore;

  late PriceAPI _priceAPI;

  ParticlWallet({
    required String walletId,
    required String walletName,
    required Coin coin,
    required ElectrumX client,
    required CachedElectrumX cachedClient,
    required TransactionNotificationTracker tracker,
    PriceAPI? priceAPI,
    SecureStorageInterface? secureStore,
  }) {
    txTracker = tracker;
    _walletId = walletId;
    _walletName = walletName;
    _coin = coin;
    _electrumXClient = client;
    _cachedElectrumXClient = cachedClient;

    _priceAPI = priceAPI ?? PriceAPI(Client());
    _secureStore =
        secureStore ?? const SecureStorageWrapper(FlutterSecureStorage());
  }

  @override
  Future<void> updateNode(bool shouldRefresh) async {
    final failovers = NodeService()
        .failoverNodesFor(coin: coin)
        .map((e) => ElectrumXNode(
              address: e.host,
              port: e.port,
              name: e.name,
              id: e.id,
              useSSL: e.useSSL,
            ))
        .toList();
    final newNode = await getCurrentNode();
    _cachedElectrumXClient = CachedElectrumX.from(
      node: newNode,
      prefs: _prefs,
      failovers: failovers,
    );
    _electrumXClient = ElectrumX.from(
      node: newNode,
      prefs: _prefs,
      failovers: failovers,
    );

    if (shouldRefresh) {
      unawaited(refresh());
    }
  }

  Future<List<String>> _getMnemonicList() async {
    final mnemonicString =
        await _secureStore.read(key: '${_walletId}_mnemonic');
    if (mnemonicString == null) {
      return [];
    }
    final List<String> data = mnemonicString.split(' ');
    return data;
  }

  Future<ElectrumXNode> getCurrentNode() async {
    final node = NodeService().getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);

    return ElectrumXNode(
      address: node.host,
      port: node.port,
      name: node.name,
      useSSL: node.useSSL,
      id: node.id,
    );
  }

  Future<List<String>> _fetchAllOwnAddresses() async {
    final List<String> allAddresses = [];
    final receivingAddresses = DB.instance.get<dynamic>(
        boxName: walletId, key: 'receivingAddressesP2WPKH') as List<dynamic>;
    final changeAddresses = DB.instance.get<dynamic>(
        boxName: walletId, key: 'changeAddressesP2WPKH') as List<dynamic>;
    final receivingAddressesP2PKH = DB.instance.get<dynamic>(
        boxName: walletId, key: 'receivingAddressesP2PKH') as List<dynamic>;
    final changeAddressesP2PKH =
        DB.instance.get<dynamic>(boxName: walletId, key: 'changeAddressesP2PKH')
            as List<dynamic>;
    final receivingAddressesP2SH = DB.instance.get<dynamic>(
        boxName: walletId, key: 'receivingAddressesP2SH') as List<dynamic>;
    final changeAddressesP2SH =
        DB.instance.get<dynamic>(boxName: walletId, key: 'changeAddressesP2SH')
            as List<dynamic>;

    for (var i = 0; i < receivingAddresses.length; i++) {
      if (!allAddresses.contains(receivingAddresses[i])) {
        allAddresses.add(receivingAddresses[i] as String);
      }
    }
    for (var i = 0; i < changeAddresses.length; i++) {
      if (!allAddresses.contains(changeAddresses[i])) {
        allAddresses.add(changeAddresses[i] as String);
      }
    }
    for (var i = 0; i < receivingAddressesP2PKH.length; i++) {
      if (!allAddresses.contains(receivingAddressesP2PKH[i])) {
        allAddresses.add(receivingAddressesP2PKH[i] as String);
      }
    }
    for (var i = 0; i < changeAddressesP2PKH.length; i++) {
      if (!allAddresses.contains(changeAddressesP2PKH[i])) {
        allAddresses.add(changeAddressesP2PKH[i] as String);
      }
    }
    for (var i = 0; i < receivingAddressesP2SH.length; i++) {
      if (!allAddresses.contains(receivingAddressesP2SH[i])) {
        allAddresses.add(receivingAddressesP2SH[i] as String);
      }
    }
    for (var i = 0; i < changeAddressesP2SH.length; i++) {
      if (!allAddresses.contains(changeAddressesP2SH[i])) {
        allAddresses.add(changeAddressesP2SH[i] as String);
      }
    }
    return allAddresses;
  }

  Future<FeeObject> _getFees() async {
    try {
      //TODO adjust numbers for different speeds?
      const int f = 1, m = 5, s = 20;

      final fast = await electrumXClient.estimateFee(blocks: f);
      final medium = await electrumXClient.estimateFee(blocks: m);
      final slow = await electrumXClient.estimateFee(blocks: s);

      final feeObject = FeeObject(
        numberOfBlocksFast: f,
        numberOfBlocksAverage: m,
        numberOfBlocksSlow: s,
        fast: Format.decimalAmountToSatoshis(fast),
        medium: Format.decimalAmountToSatoshis(medium),
        slow: Format.decimalAmountToSatoshis(slow),
      );

      Logging.instance.log("fetched fees: $feeObject", level: LogLevel.Info);
      return feeObject;
    } catch (e) {
      Logging.instance
          .log("Exception rethrown from _getFees(): $e", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _generateNewWallet() async {
    Logging.instance
        .log("IS_INTEGRATION_TEST: $integrationTestFlag", level: LogLevel.Info);
    if (!integrationTestFlag) {
      final features = await electrumXClient.getServerFeatures();
      Logging.instance.log("features: $features", level: LogLevel.Info);
      switch (coin) {
        case Coin.particl:
          if (features['genesis_hash'] != GENESIS_HASH_MAINNET) {
            throw Exception("genesis hash does not match main net!");
          }
          break;
        default:
          throw Exception(
              "Attempted to generate a ParticlWallet using a non particl coin type: ${coin.name}");
      }
    }

    // this should never fail
    if ((await _secureStore.read(key: '${_walletId}_mnemonic')) != null) {
      throw Exception(
          "Attempted to overwrite mnemonic on generate new wallet!");
    }
    await _secureStore.write(
        key: '${_walletId}_mnemonic',
        value: bip39.generateMnemonic(strength: 256));

    // Set relevant indexes
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "receivingIndexP2WPKH", value: 0);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "changeIndexP2WPKH", value: 0);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "receivingIndexP2PKH", value: 0);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "changeIndexP2PKH", value: 0);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "receivingIndexP2SH", value: 0);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "changeIndexP2SH", value: 0);
    await DB.instance.put<dynamic>(
      boxName: walletId,
      key: 'blocked_tx_hashes',
      value: ["0xdefault"],
    ); // A list of transaction hashes to represent frozen utxos in wallet
    // initialize address book entries
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'addressBookEntries',
        value: <String, String>{});

    // Generate and add addresses to relevant arrays
    await Future.wait([
      // P2WPKH
      _generateAddressForChain(0, 0, DerivePathType.bip84).then(
        (initialReceivingAddressP2WPKH) {
          _addToAddressesArrayForChain(
              initialReceivingAddressP2WPKH, 0, DerivePathType.bip84);
          _currentReceivingAddress =
              Future(() => initialReceivingAddressP2WPKH);
        },
      ),
      _generateAddressForChain(1, 0, DerivePathType.bip84).then(
        (initialChangeAddressP2WPKH) => _addToAddressesArrayForChain(
          initialChangeAddressP2WPKH,
          1,
          DerivePathType.bip84,
        ),
      ),

      // P2PKH
      _generateAddressForChain(0, 0, DerivePathType.bip44).then(
        (initialReceivingAddressP2PKH) {
          _addToAddressesArrayForChain(
              initialReceivingAddressP2PKH, 0, DerivePathType.bip44);
          _currentReceivingAddressP2PKH =
              Future(() => initialReceivingAddressP2PKH);
        },
      ),
      _generateAddressForChain(1, 0, DerivePathType.bip44).then(
        (initialChangeAddressP2PKH) => _addToAddressesArrayForChain(
          initialChangeAddressP2PKH,
          1,
          DerivePathType.bip44,
        ),
      ),

      // P2SH
      _generateAddressForChain(0, 0, DerivePathType.bip49).then(
        (initialReceivingAddressP2SH) {
          _addToAddressesArrayForChain(
              initialReceivingAddressP2SH, 0, DerivePathType.bip49);
          _currentReceivingAddressP2SH =
              Future(() => initialReceivingAddressP2SH);
        },
      ),
      _generateAddressForChain(1, 0, DerivePathType.bip49).then(
        (initialChangeAddressP2SH) => _addToAddressesArrayForChain(
          initialChangeAddressP2SH,
          1,
          DerivePathType.bip49,
        ),
      ),
    ]);

    // // P2PKH
    // _generateAddressForChain(0, 0, DerivePathType.bip44).then(
    //   (initialReceivingAddressP2PKH) {
    //     _addToAddressesArrayForChain(
    //         initialReceivingAddressP2PKH, 0, DerivePathType.bip44);
    //     this._currentReceivingAddressP2PKH =
    //         Future(() => initialReceivingAddressP2PKH);
    //   },
    // );
    // _generateAddressForChain(1, 0, DerivePathType.bip44)
    //     .then((initialChangeAddressP2PKH) => _addToAddressesArrayForChain(
    //           initialChangeAddressP2PKH,
    //           1,
    //           DerivePathType.bip44,
    //         ));
    //
    // // P2SH
    // _generateAddressForChain(0, 0, DerivePathType.bip49).then(
    //   (initialReceivingAddressP2SH) {
    //     _addToAddressesArrayForChain(
    //         initialReceivingAddressP2SH, 0, DerivePathType.bip49);
    //     this._currentReceivingAddressP2SH =
    //         Future(() => initialReceivingAddressP2SH);
    //   },
    // );
    // _generateAddressForChain(1, 0, DerivePathType.bip49)
    //     .then((initialChangeAddressP2SH) => _addToAddressesArrayForChain(
    //           initialChangeAddressP2SH,
    //           1,
    //           DerivePathType.bip49,
    //         ));

    Logging.instance.log("_generateNewWalletFinished", level: LogLevel.Info);
  }

  /// Generates a new internal or external chain address for the wallet using a BIP84, BIP44, or BIP49 derivation path.
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  /// [index] - This can be any integer >= 0
  Future<String> _generateAddressForChain(
    int chain,
    int index,
    DerivePathType derivePathType,
  ) async {
    final mnemonic = await _secureStore.read(key: '${_walletId}_mnemonic');
    final node = await compute(
      getBip32NodeWrapper,
      Tuple5(
        chain,
        index,
        mnemonic!,
        _network,
        derivePathType,
      ),
    );
    final data = PaymentData(pubkey: node.publicKey);
    String address;

    switch (derivePathType) {
      case DerivePathType.bip44:
        address = P2PKH(data: data, network: _network).data.address!;
        break;
      case DerivePathType.bip49:
        address = P2SH(
                data: PaymentData(
                    redeem: P2WPKH(
                            data: data,
                            network: _network,
                            overridePrefix: particl.bech32!)
                        .data),
                network: _network)
            .data
            .address!;
        break;
      case DerivePathType.bip84:
        address = P2WPKH(network: _network, data: data).data.address!;
        break;
    }

    // add generated address & info to derivations
    await addDerivation(
      chain: chain,
      address: address,
      pubKey: Format.uint8listToString(node.publicKey),
      wif: node.toWIF(),
      derivePathType: derivePathType,
    );

    return address;
  }

  /// Increases the index for either the internal or external chain, depending on [chain].
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<void> _incrementAddressIndexForChain(
      int chain, DerivePathType derivePathType) async {
    // Here we assume chain == 1 if it isn't 0
    String indexKey = chain == 0 ? "receivingIndex" : "changeIndex";
    switch (derivePathType) {
      case DerivePathType.bip44:
        indexKey += "P2PKH";
        break;
      case DerivePathType.bip49:
        indexKey += "P2SH";
        break;
      case DerivePathType.bip84:
        indexKey += "P2WPKH";
        break;
    }

    final newIndex =
        (DB.instance.get<dynamic>(boxName: walletId, key: indexKey)) + 1;
    await DB.instance
        .put<dynamic>(boxName: walletId, key: indexKey, value: newIndex);
  }

  /// Adds [address] to the relevant chain's address array, which is determined by [chain].
  /// [address] - Expects a standard native segwit address
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<void> _addToAddressesArrayForChain(
      String address, int chain, DerivePathType derivePathType) async {
    String chainArray = '';
    if (chain == 0) {
      chainArray = 'receivingAddresses';
    } else {
      chainArray = 'changeAddresses';
    }
    switch (derivePathType) {
      case DerivePathType.bip44:
        chainArray += "P2PKH";
        break;
      case DerivePathType.bip49:
        chainArray += "P2SH";
        break;
      case DerivePathType.bip84:
        chainArray += "P2WPKH";
        break;
    }

    final addressArray =
        DB.instance.get<dynamic>(boxName: walletId, key: chainArray);
    if (addressArray == null) {
      Logging.instance.log(
          'Attempting to add the following to $chainArray array for chain $chain:${[
            address
          ]}',
          level: LogLevel.Info);
      await DB.instance
          .put<dynamic>(boxName: walletId, key: chainArray, value: [address]);
    } else {
      // Make a deep copy of the existing list
      final List<String> newArray = [];
      addressArray
          .forEach((dynamic _address) => newArray.add(_address as String));
      newArray.add(address); // Add the address passed into the method
      await DB.instance
          .put<dynamic>(boxName: walletId, key: chainArray, value: newArray);
    }
  }

  /// Returns the latest receiving/change (external/internal) address for the wallet depending on [chain]
  /// and
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<String> _getCurrentAddressForChain(
      int chain, DerivePathType derivePathType) async {
    // Here, we assume that chain == 1 if it isn't 0
    String arrayKey = chain == 0 ? "receivingAddresses" : "changeAddresses";
    switch (derivePathType) {
      case DerivePathType.bip44:
        arrayKey += "P2PKH";
        break;
      case DerivePathType.bip49:
        arrayKey += "P2SH";
        break;
      case DerivePathType.bip84:
        arrayKey += "P2WPKH";
        break;
    }
    final internalChainArray =
        DB.instance.get<dynamic>(boxName: walletId, key: arrayKey);
    return internalChainArray.last as String;
  }

  String _buildDerivationStorageKey({
    required int chain,
    required DerivePathType derivePathType,
  }) {
    String key;
    String chainId = chain == 0 ? "receive" : "change";
    switch (derivePathType) {
      case DerivePathType.bip44:
        key = "${walletId}_${chainId}DerivationsP2PKH";
        break;
      case DerivePathType.bip49:
        key = "${walletId}_${chainId}DerivationsP2SH";
        break;
      case DerivePathType.bip84:
        key = "${walletId}_${chainId}DerivationsP2WPKH";
        break;
    }
    return key;
  }

  Future<Map<String, dynamic>> _fetchDerivations({
    required int chain,
    required DerivePathType derivePathType,
  }) async {
    // build lookup key
    final key = _buildDerivationStorageKey(
        chain: chain, derivePathType: derivePathType);

    // fetch current derivations
    final derivationsString = await _secureStore.read(key: key);
    return Map<String, dynamic>.from(
        jsonDecode(derivationsString ?? "{}") as Map);
  }

  /// Add a single derivation to the local secure storage for [chain] and
  /// [derivePathType] where [chain] must either be 1 for change or 0 for receive.
  /// This will overwrite a previous entry where the address of the new derivation
  /// matches a derivation currently stored.
  Future<void> addDerivation({
    required int chain,
    required String address,
    required String pubKey,
    required String wif,
    required DerivePathType derivePathType,
  }) async {
    // build lookup key
    final key = _buildDerivationStorageKey(
        chain: chain, derivePathType: derivePathType);

    // fetch current derivations
    final derivationsString = await _secureStore.read(key: key);
    final derivations =
        Map<String, dynamic>.from(jsonDecode(derivationsString ?? "{}") as Map);

    // add derivation
    derivations[address] = {
      "pubKey": pubKey,
      "wif": wif,
    };

    // save derivations
    final newReceiveDerivationsString = jsonEncode(derivations);
    await _secureStore.write(key: key, value: newReceiveDerivationsString);
  }

  /// Add multiple derivations to the local secure storage for [chain] and
  /// [derivePathType] where [chain] must either be 1 for change or 0 for receive.
  /// This will overwrite any previous entries where the address of the new derivation
  /// matches a derivation currently stored.
  /// The [derivationsToAdd] must be in the format of:
  /// {
  ///   addressA : {
  ///     "pubKey": <the pubKey string>,
  ///     "wif": <the wif string>,
  ///   },
  ///   addressB : {
  ///     "pubKey": <the pubKey string>,
  ///     "wif": <the wif string>,
  ///   },
  /// }
  Future<void> addDerivations({
    required int chain,
    required DerivePathType derivePathType,
    required Map<String, dynamic> derivationsToAdd,
  }) async {
    // build lookup key
    final key = _buildDerivationStorageKey(
        chain: chain, derivePathType: derivePathType);

    // fetch current derivations
    final derivationsString = await _secureStore.read(key: key);
    final derivations =
        Map<String, dynamic>.from(jsonDecode(derivationsString ?? "{}") as Map);

    // add derivation
    derivations.addAll(derivationsToAdd);

    // save derivations
    final newReceiveDerivationsString = jsonEncode(derivations);
    await _secureStore.write(key: key, value: newReceiveDerivationsString);
  }

  Future<UtxoData> _fetchUtxoData() async {
    final List<String> allAddresses = await _fetchAllOwnAddresses();

    try {
      final fetchedUtxoList = <List<Map<String, dynamic>>>[];

      final Map<int, Map<String, List<dynamic>>> batches = {};
      const batchSizeMax = 100;
      int batchNumber = 0;
      for (int i = 0; i < allAddresses.length; i++) {
        if (batches[batchNumber] == null) {
          batches[batchNumber] = {};
        }
        final scripthash = _convertToScriptHash(allAddresses[i], _network);
        batches[batchNumber]!.addAll({
          scripthash: [scripthash]
        });
        if (i % batchSizeMax == batchSizeMax - 1) {
          batchNumber++;
        }
      }

      for (int i = 0; i < batches.length; i++) {
        final response =
            await _electrumXClient.getBatchUTXOs(args: batches[i]!);
        for (final entry in response.entries) {
          if (entry.value.isNotEmpty) {
            fetchedUtxoList.add(entry.value);
          }
        }
      }
      final priceData =
          await _priceAPI.getPricesAnd24hChange(baseCurrency: _prefs.currency);
      Decimal currentPrice = priceData[coin]?.item1 ?? Decimal.zero;
      final List<Map<String, dynamic>> outputArray = [];
      int satoshiBalance = 0;
      int satoshiBalancePending = 0;

      for (int i = 0; i < fetchedUtxoList.length; i++) {
        for (int j = 0; j < fetchedUtxoList[i].length; j++) {
          int value = fetchedUtxoList[i][j]["value"] as int;
          satoshiBalance += value;

          final txn = await cachedElectrumXClient.getTransaction(
            txHash: fetchedUtxoList[i][j]["tx_hash"] as String,
            verbose: true,
            coin: coin,
          );

          final Map<String, dynamic> utxo = {};
          final int confirmations = txn["confirmations"] as int? ?? 0;
          final bool confirmed = confirmations >= MINIMUM_CONFIRMATIONS;
          if (!confirmed) {
            satoshiBalancePending += value;
          }

          utxo["txid"] = txn["txid"];
          utxo["vout"] = fetchedUtxoList[i][j]["tx_pos"];
          utxo["value"] = value;

          utxo["status"] = <String, dynamic>{};
          utxo["status"]["confirmed"] = confirmed;
          utxo["status"]["confirmations"] = confirmations;
          utxo["status"]["block_height"] = fetchedUtxoList[i][j]["height"];
          utxo["status"]["block_hash"] = txn["blockhash"];
          utxo["status"]["block_time"] = txn["blocktime"];

          final fiatValue = ((Decimal.fromInt(value) * currentPrice) /
                  Decimal.fromInt(Constants.satsPerCoin))
              .toDecimal(scaleOnInfinitePrecision: 2);
          utxo["rawWorth"] = fiatValue;
          utxo["fiatWorth"] = fiatValue.toString();
          outputArray.add(utxo);
        }
      }

      Decimal currencyBalanceRaw =
          ((Decimal.fromInt(satoshiBalance) * currentPrice) /
                  Decimal.fromInt(Constants.satsPerCoin))
              .toDecimal(scaleOnInfinitePrecision: 2);

      final Map<String, dynamic> result = {
        "total_user_currency": currencyBalanceRaw.toString(),
        "total_sats": satoshiBalance,
        "total_btc": (Decimal.fromInt(satoshiBalance) /
                Decimal.fromInt(Constants.satsPerCoin))
            .toDecimal(scaleOnInfinitePrecision: Constants.decimalPlaces)
            .toString(),
        "outputArray": outputArray,
        "unconfirmed": satoshiBalancePending,
      };

      final dataModel = UtxoData.fromJson(result);

      final List<UtxoObject> allOutputs = dataModel.unspentOutputArray;
      Logging.instance
          .log('Outputs fetched: $allOutputs', level: LogLevel.Info);
      await _sortOutputs(allOutputs);
      await DB.instance.put<dynamic>(
          boxName: walletId, key: 'latest_utxo_model', value: dataModel);
      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: 'totalBalance',
          value: dataModel.satoshiBalance);
      return dataModel;
    } catch (e, s) {
      Logging.instance
          .log("Output fetch unsuccessful: $e\n$s", level: LogLevel.Error);
      final latestTxModel =
          DB.instance.get<dynamic>(boxName: walletId, key: 'latest_utxo_model')
              as models.UtxoData?;

      if (latestTxModel == null) {
        final emptyModel = {
          "total_user_currency": "0.00",
          "total_sats": 0,
          "total_btc": "0",
          "outputArray": <dynamic>[]
        };
        return UtxoData.fromJson(emptyModel);
      } else {
        Logging.instance
            .log("Old output model located", level: LogLevel.Warning);
        return latestTxModel;
      }
    }
  }

  /// Takes in a list of UtxoObjects and adds a name (dependent on object index within list)
  /// and checks for the txid associated with the utxo being blocked and marks it accordingly.
  /// Now also checks for output labeling.
  Future<void> _sortOutputs(List<UtxoObject> utxos) async {
    final blockedHashArray =
        DB.instance.get<dynamic>(boxName: walletId, key: 'blocked_tx_hashes')
            as List<dynamic>?;
    final List<String> lst = [];
    if (blockedHashArray != null) {
      for (var hash in blockedHashArray) {
        lst.add(hash as String);
      }
    }
    final labels =
        DB.instance.get<dynamic>(boxName: walletId, key: 'labels') as Map? ??
            {};

    outputsList = [];

    for (var i = 0; i < utxos.length; i++) {
      if (labels[utxos[i].txid] != null) {
        utxos[i].txName = labels[utxos[i].txid] as String? ?? "";
      } else {
        utxos[i].txName = 'Output #$i';
      }

      if (utxos[i].status.confirmed == false) {
        outputsList.add(utxos[i]);
      } else {
        if (lst.contains(utxos[i].txid)) {
          utxos[i].blocked = true;
          outputsList.add(utxos[i]);
        } else if (!lst.contains(utxos[i].txid)) {
          outputsList.add(utxos[i]);
        }
      }
    }
  }

  Future<int> getTxCount({required String address}) async {
    String? scripthash;
    try {
      scripthash = _convertToScriptHash(address, _network);
      final transactions =
          await electrumXClient.getHistory(scripthash: scripthash);
      return transactions.length;
    } catch (e) {
      Logging.instance.log(
          "Exception rethrown in _getTxCount(address: $address, scripthash: $scripthash): $e",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<Map<String, int>> _getBatchTxCount({
    required Map<String, String> addresses,
  }) async {
    try {
      final Map<String, List<dynamic>> args = {};
      for (final entry in addresses.entries) {
        args[entry.key] = [_convertToScriptHash(entry.value, _network)];
      }
      final response = await electrumXClient.getBatchHistory(args: args);

      final Map<String, int> result = {};
      for (final entry in response.entries) {
        result[entry.key] = entry.value.length;
      }
      return result;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown in _getBatchTxCount(address: $addresses: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _checkReceivingAddressForTransactions(
      DerivePathType derivePathType) async {
    try {
      final String currentExternalAddr =
          await _getCurrentAddressForChain(0, derivePathType);
      final int txCount = await getTxCount(address: currentExternalAddr);
      Logging.instance.log(
          'Number of txs for current receiving address $currentExternalAddr: $txCount',
          level: LogLevel.Info);

      if (txCount >= 1) {
        // First increment the receiving index
        await _incrementAddressIndexForChain(0, derivePathType);

        // Check the new receiving index
        String indexKey = "receivingIndex";
        switch (derivePathType) {
          case DerivePathType.bip44:
            indexKey += "P2PKH";
            break;
          case DerivePathType.bip49:
            indexKey += "P2SH";
            break;
          case DerivePathType.bip84:
            indexKey += "P2WPKH";
            break;
        }
        final newReceivingIndex =
            DB.instance.get<dynamic>(boxName: walletId, key: indexKey) as int;

        // Use new index to derive a new receiving address
        final newReceivingAddress = await _generateAddressForChain(
            0, newReceivingIndex, derivePathType);

        // Add that new receiving address to the array of receiving addresses
        await _addToAddressesArrayForChain(
            newReceivingAddress, 0, derivePathType);

        // Set the new receiving address that the service

        switch (derivePathType) {
          case DerivePathType.bip44:
            _currentReceivingAddressP2PKH = Future(() => newReceivingAddress);
            break;
          case DerivePathType.bip49:
            _currentReceivingAddressP2SH = Future(() => newReceivingAddress);
            break;
          case DerivePathType.bip84:
            _currentReceivingAddress = Future(() => newReceivingAddress);
            break;
        }
      }
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _checkReceivingAddressForTransactions($derivePathType): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _checkChangeAddressForTransactions(
      DerivePathType derivePathType) async {
    try {
      final String currentExternalAddr =
          await _getCurrentAddressForChain(1, derivePathType);
      final int txCount = await getTxCount(address: currentExternalAddr);
      Logging.instance.log(
          'Number of txs for current change address $currentExternalAddr: $txCount',
          level: LogLevel.Info);

      if (txCount >= 1) {
        // First increment the change index
        await _incrementAddressIndexForChain(1, derivePathType);

        // Check the new change index
        String indexKey = "changeIndex";
        switch (derivePathType) {
          case DerivePathType.bip44:
            indexKey += "P2PKH";
            break;
          case DerivePathType.bip49:
            indexKey += "P2SH";
            break;
          case DerivePathType.bip84:
            indexKey += "P2WPKH";
            break;
        }
        final newChangeIndex =
            DB.instance.get<dynamic>(boxName: walletId, key: indexKey) as int;

        // Use new index to derive a new change address
        final newChangeAddress =
            await _generateAddressForChain(1, newChangeIndex, derivePathType);

        // Add that new receiving address to the array of change addresses
        await _addToAddressesArrayForChain(newChangeAddress, 1, derivePathType);
      }
    } on SocketException catch (se, s) {
      Logging.instance.log(
          "SocketException caught in _checkReceivingAddressForTransactions($derivePathType): $se\n$s",
          level: LogLevel.Error);
      return;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _checkReceivingAddressForTransactions($derivePathType): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _checkCurrentReceivingAddressesForTransactions() async {
    try {
      for (final type in DerivePathType.values) {
        await _checkReceivingAddressForTransactions(type);
      }
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _checkCurrentReceivingAddressesForTransactions(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  /// public wrapper because dart can't test private...
  Future<void> checkCurrentReceivingAddressesForTransactions() async {
    if (Platform.environment["FLUTTER_TEST"] == "true") {
      try {
        return _checkCurrentReceivingAddressesForTransactions();
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<void> _checkCurrentChangeAddressesForTransactions() async {
    try {
      for (final type in DerivePathType.values) {
        await _checkChangeAddressForTransactions(type);
      }
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _checkCurrentChangeAddressesForTransactions(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  /// public wrapper because dart can't test private...
  Future<void> checkCurrentChangeAddressesForTransactions() async {
    if (Platform.environment["FLUTTER_TEST"] == "true") {
      try {
        return _checkCurrentChangeAddressesForTransactions();
      } catch (_) {
        rethrow;
      }
    }
  }

  /// attempts to convert a string to a valid scripthash
  ///
  /// Returns the scripthash or throws an exception on invalid particl address
  String _convertToScriptHash(String particlAddress, NetworkType network) {
    try {
      final output = Address.addressToOutputScript(particlAddress, network);
      final hash = sha256.convert(output.toList(growable: false)).toString();

      final chars = hash.split("");
      final reversedPairs = <String>[];
      var i = chars.length - 1;
      while (i > 0) {
        reversedPairs.add(chars[i - 1]);
        reversedPairs.add(chars[i]);
        i -= 2;
      }
      return reversedPairs.join("");
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchHistory(
      List<String> allAddresses) async {
    try {
      List<Map<String, dynamic>> allTxHashes = [];

      final Map<int, Map<String, List<dynamic>>> batches = {};
      final Map<String, String> requestIdToAddressMap = {};
      const batchSizeMax = 100;
      int batchNumber = 0;
      for (int i = 0; i < allAddresses.length; i++) {
        if (batches[batchNumber] == null) {
          batches[batchNumber] = {};
        }
        final scripthash = _convertToScriptHash(allAddresses[i], _network);
        final id = Logger.isTestEnv ? "$i" : const Uuid().v1();
        requestIdToAddressMap[id] = allAddresses[i];
        batches[batchNumber]!.addAll({
          id: [scripthash]
        });
        if (i % batchSizeMax == batchSizeMax - 1) {
          batchNumber++;
        }
      }

      for (int i = 0; i < batches.length; i++) {
        final response =
            await _electrumXClient.getBatchHistory(args: batches[i]!);
        for (final entry in response.entries) {
          for (int j = 0; j < entry.value.length; j++) {
            entry.value[j]["address"] = requestIdToAddressMap[entry.key];
            if (!allTxHashes.contains(entry.value[j])) {
              allTxHashes.add(entry.value[j]);
            }
          }
        }
      }

      return allTxHashes;
    } catch (e, s) {
      Logging.instance.log("_fetchHistory: $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  bool _duplicateTxCheck(
      List<Map<String, dynamic>> allTransactions, String txid) {
    for (int i = 0; i < allTransactions.length; i++) {
      if (allTransactions[i]["txid"] == txid) {
        return true;
      }
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> fastFetch(List<String> allTxHashes) async {
    List<Map<String, dynamic>> allTransactions = [];

    const futureLimit = 30;
    List<Future<Map<String, dynamic>>> transactionFutures = [];
    int currentFutureCount = 0;
    for (final txHash in allTxHashes) {
      Future<Map<String, dynamic>> transactionFuture =
          cachedElectrumXClient.getTransaction(
        txHash: txHash,
        verbose: true,
        coin: coin,
      );
      transactionFutures.add(transactionFuture);
      currentFutureCount++;
      if (currentFutureCount > futureLimit) {
        currentFutureCount = 0;
        await Future.wait(transactionFutures);
        for (final fTx in transactionFutures) {
          final tx = await fTx;

          allTransactions.add(tx);
        }
      }
    }
    if (currentFutureCount != 0) {
      currentFutureCount = 0;
      await Future.wait(transactionFutures);
      for (final fTx in transactionFutures) {
        final tx = await fTx;

        allTransactions.add(tx);
      }
    }
    return allTransactions;
  }

  Future<TransactionData> _fetchTransactionData() async {
    final List<String> allAddresses = await _fetchAllOwnAddresses();

    final changeAddresses = DB.instance.get<dynamic>(
        boxName: walletId, key: 'changeAddressesP2WPKH') as List<dynamic>;
    final changeAddressesP2PKH =
        DB.instance.get<dynamic>(boxName: walletId, key: 'changeAddressesP2PKH')
            as List<dynamic>;
    final changeAddressesP2SH =
        DB.instance.get<dynamic>(boxName: walletId, key: 'changeAddressesP2SH')
            as List<dynamic>;

    for (var i = 0; i < changeAddressesP2PKH.length; i++) {
      changeAddresses.add(changeAddressesP2PKH[i] as String);
    }
    for (var i = 0; i < changeAddressesP2SH.length; i++) {
      changeAddresses.add(changeAddressesP2SH[i] as String);
    }

    final List<Map<String, dynamic>> allTxHashes =
        await _fetchHistory(allAddresses);

    final cachedTransactions =
        DB.instance.get<dynamic>(boxName: walletId, key: 'latest_tx_model')
            as TransactionData?;
    int latestTxnBlockHeight =
        DB.instance.get<dynamic>(boxName: walletId, key: "storedTxnDataHeight")
                as int? ??
            0;

    final unconfirmedCachedTransactions =
        cachedTransactions?.getAllTransactions() ?? {};
    unconfirmedCachedTransactions
        .removeWhere((key, value) => value.confirmedStatus);

    if (cachedTransactions != null) {
      for (final tx in allTxHashes.toList(growable: false)) {
        final txHeight = tx["height"] as int;
        if (txHeight > 0 &&
            txHeight < latestTxnBlockHeight - MINIMUM_CONFIRMATIONS) {
          if (unconfirmedCachedTransactions[tx["tx_hash"] as String] == null) {
            allTxHashes.remove(tx);
          }
        }
      }
    }

    Set<String> hashes = {};
    for (var element in allTxHashes) {
      hashes.add(element['tx_hash'] as String);
    }
    await fastFetch(hashes.toList());
    List<Map<String, dynamic>> allTransactions = [];

    for (final txHash in allTxHashes) {
      final tx = await cachedElectrumXClient.getTransaction(
        txHash: txHash["tx_hash"] as String,
        verbose: true,
        coin: coin,
      );

      // Logging.instance.log("TRANSACTION: ${jsonEncode(tx)}");
      // TODO fix this for sent to self transactions?
      if (!_duplicateTxCheck(allTransactions, tx["txid"] as String)) {
        tx["address"] = txHash["address"];
        tx["height"] = txHash["height"];
        allTransactions.add(tx);
      }
    }

    Logging.instance.log("addAddresses: $allAddresses", level: LogLevel.Info);
    Logging.instance.log("allTxHashes: $allTxHashes", level: LogLevel.Info);

    Logging.instance.log("allTransactions length: ${allTransactions.length}",
        level: LogLevel.Info);

    final priceData =
        await _priceAPI.getPricesAnd24hChange(baseCurrency: _prefs.currency);
    Decimal currentPrice = priceData[coin]?.item1 ?? Decimal.zero;
    final List<Map<String, dynamic>> midSortedArray = [];

    Set<String> vHashes = {};
    for (final txObject in allTransactions) {
      for (int i = 0; i < (txObject["vin"] as List).length; i++) {
        final input = txObject["vin"]![i] as Map;
        final prevTxid = input["txid"] as String;
        vHashes.add(prevTxid);
      }
    }
    await fastFetch(vHashes.toList());

    for (final txObject in allTransactions) {
      List<String> sendersArray = [];
      List<String> recipientsArray = [];

      // Usually only has value when txType = 'Send'
      int inputAmtSentFromWallet = 0;
      // Usually has value regardless of txType due to change addresses
      int outputAmtAddressedToWallet = 0;
      int fee = 0;

      Map<String, dynamic> midSortedTx = {};

      for (int i = 0; i < (txObject["vin"] as List).length; i++) {
        final input = txObject["vin"]![i] as Map;
        final prevTxid = input["txid"] as String;
        final prevOut = input["vout"] as int;

        final tx = await _cachedElectrumXClient.getTransaction(
          txHash: prevTxid,
          coin: coin,
        );

        Logging.instance
            .log("RECEIVED TX IS : ${tx["vout"]}", level: LogLevel.Info);

        for (final out in tx["vout"] as List) {
          if (prevOut == out["n"]) {
            final address = out["scriptPubKey"]["address"] as String?;
            if (address != null) {
              sendersArray.add(address);
            }
          }
        }
      }

      Logging.instance.log("sendersArray: $sendersArray", level: LogLevel.Info);

      for (final output in txObject["vout"] as List) {
        final address = output["scriptPubKey"]["address"] as String?;
        if (address != null) {
          recipientsArray.add(address);
        }
      }

      Logging.instance
          .log("recipientsArray: $recipientsArray", level: LogLevel.Info);

      final foundInSenders =
          allAddresses.any((element) => sendersArray.contains(element));
      Logging.instance
          .log("foundInSenders: $foundInSenders", level: LogLevel.Info);

      // If txType = Sent, then calculate inputAmtSentFromWallet
      if (foundInSenders) {
        int totalInput = 0;
        for (int i = 0; i < (txObject["vin"] as List).length; i++) {
          final input = txObject["vin"]![i] as Map;
          final prevTxid = input["txid"] as String;
          final prevOut = input["vout"] as int;
          final tx = await _cachedElectrumXClient.getTransaction(
            txHash: prevTxid,
            coin: coin,
          );

          for (final out in tx["vout"] as List) {
            if (prevOut == out["n"]) {
              inputAmtSentFromWallet +=
                  (Decimal.parse(out["value"]!.toString()) *
                          Decimal.fromInt(Constants.satsPerCoin))
                      .toBigInt()
                      .toInt();
            }
          }
        }
        totalInput = inputAmtSentFromWallet;
        int totalOutput = 0;

        for (final output in txObject["vout"] as List) {
          final String address = output["scriptPubKey"]!["address"] as String;
          final value = output["value"]!;
          final _value = (Decimal.parse(value.toString()) *
                  Decimal.fromInt(Constants.satsPerCoin))
              .toBigInt()
              .toInt();
          totalOutput += _value;
          if (changeAddresses.contains(address)) {
            inputAmtSentFromWallet -= _value;
          } else {
            // change address from 'sent from' to the 'sent to' address
            txObject["address"] = address;
          }
        }
        // calculate transaction fee
        fee = totalInput - totalOutput;
        // subtract fee from sent to calculate correct value of sent tx
        inputAmtSentFromWallet -= fee;
      } else {
        // counters for fee calculation
        int totalOut = 0;
        int totalIn = 0;

        // add up received tx value
        for (final output in txObject["vout"] as List) {
          final address = output["scriptPubKey"]["address"];
          if (address != null) {
            final value = (Decimal.parse(output["value"].toString()) *
                    Decimal.fromInt(Constants.satsPerCoin))
                .toBigInt()
                .toInt();
            totalOut += value;
            if (allAddresses.contains(address)) {
              outputAmtAddressedToWallet += value;
            }
          }
        }

        // calculate fee for received tx
        for (int i = 0; i < (txObject["vin"] as List).length; i++) {
          final input = txObject["vin"][i] as Map;
          final prevTxid = input["txid"] as String;
          final prevOut = input["vout"] as int;
          final tx = await _cachedElectrumXClient.getTransaction(
            txHash: prevTxid,
            coin: coin,
          );

          for (final out in tx["vout"] as List) {
            if (prevOut == out["n"]) {
              totalIn += (Decimal.parse(out["value"].toString()) *
                      Decimal.fromInt(Constants.satsPerCoin))
                  .toBigInt()
                  .toInt();
            }
          }
        }
        fee = totalIn - totalOut;
      }

      // create final tx map
      midSortedTx["txid"] = txObject["txid"];
      midSortedTx["confirmed_status"] = (txObject["confirmations"] != null) &&
          (txObject["confirmations"] as int >= MINIMUM_CONFIRMATIONS);
      midSortedTx["confirmations"] = txObject["confirmations"] ?? 0;
      midSortedTx["timestamp"] = txObject["blocktime"] ??
          (DateTime.now().millisecondsSinceEpoch ~/ 1000);

      if (foundInSenders) {
        midSortedTx["txType"] = "Sent";
        midSortedTx["amount"] = inputAmtSentFromWallet;
        final String worthNow =
            ((currentPrice * Decimal.fromInt(inputAmtSentFromWallet)) /
                    Decimal.fromInt(Constants.satsPerCoin))
                .toDecimal(scaleOnInfinitePrecision: 2)
                .toStringAsFixed(2);
        midSortedTx["worthNow"] = worthNow;
        midSortedTx["worthAtBlockTimestamp"] = worthNow;
      } else {
        midSortedTx["txType"] = "Received";
        midSortedTx["amount"] = outputAmtAddressedToWallet;
        final worthNow =
            ((currentPrice * Decimal.fromInt(outputAmtAddressedToWallet)) /
                    Decimal.fromInt(Constants.satsPerCoin))
                .toDecimal(scaleOnInfinitePrecision: 2)
                .toStringAsFixed(2);
        midSortedTx["worthNow"] = worthNow;
      }
      midSortedTx["aliens"] = <dynamic>[];
      midSortedTx["fees"] = fee;
      midSortedTx["address"] = txObject["address"];
      midSortedTx["inputSize"] = txObject["vin"].length;
      midSortedTx["outputSize"] = txObject["vout"].length;
      midSortedTx["inputs"] = txObject["vin"];
      midSortedTx["outputs"] = txObject["vout"];

      final int height = txObject["height"] as int;
      midSortedTx["height"] = height;

      if (height >= latestTxnBlockHeight) {
        latestTxnBlockHeight = height;
      }

      midSortedArray.add(midSortedTx);
    }

    // sort by date  ----  //TODO not sure if needed
    // shouldn't be any issues with a null timestamp but I got one at some point?
    midSortedArray
        .sort((a, b) => (b["timestamp"] as int) - (a["timestamp"] as int));
    // {
    //   final aT = a["timestamp"];
    //   final bT = b["timestamp"];
    //
    //   if (aT == null && bT == null) {
    //     return 0;
    //   } else if (aT == null) {
    //     return -1;
    //   } else if (bT == null) {
    //     return 1;
    //   } else {
    //     return bT - aT;
    //   }
    // });

    // buildDateTimeChunks
    final Map<String, dynamic> result = {"dateTimeChunks": <dynamic>[]};
    final dateArray = <dynamic>[];

    for (int i = 0; i < midSortedArray.length; i++) {
      final txObject = midSortedArray[i];
      final date = extractDateFromTimestamp(txObject["timestamp"] as int);
      final txTimeArray = [txObject["timestamp"], date];

      if (dateArray.contains(txTimeArray[1])) {
        result["dateTimeChunks"].forEach((dynamic chunk) {
          if (extractDateFromTimestamp(chunk["timestamp"] as int) ==
              txTimeArray[1]) {
            if (chunk["transactions"] == null) {
              chunk["transactions"] = <Map<String, dynamic>>[];
            }
            chunk["transactions"].add(txObject);
          }
        });
      } else {
        dateArray.add(txTimeArray[1]);
        final chunk = {
          "timestamp": txTimeArray[0],
          "transactions": [txObject],
        };
        result["dateTimeChunks"].add(chunk);
      }
    }

    final transactionsMap = cachedTransactions?.getAllTransactions() ?? {};
    transactionsMap
        .addAll(TransactionData.fromJson(result).getAllTransactions());

    final txModel = TransactionData.fromMap(transactionsMap);

    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'storedTxnDataHeight',
        value: latestTxnBlockHeight);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'latest_tx_model', value: txModel);

    return txModel;
  }

  int estimateTxFee({required int vSize, required int feeRatePerKB}) {
    return vSize * (feeRatePerKB / 1000).ceil();
  }

  /// The coinselection algorithm decides whether or not the user is eligible to make the transaction
  /// with [satoshiAmountToSend] and [selectedTxFeeRate]. If so, it will call buildTrasaction() and return
  /// a map containing the tx hex along with other important information. If not, then it will return
  /// an integer (1 or 2)
  dynamic coinSelection(
    int satoshiAmountToSend,
    int selectedTxFeeRate,
    String _recipientAddress,
    bool isSendAll, {
    int additionalOutputs = 0,
    List<UtxoObject>? utxos,
  }) async {
    Logging.instance
        .log("Starting coinSelection ----------", level: LogLevel.Info);
    final List<UtxoObject> availableOutputs = utxos ?? outputsList;
    final List<UtxoObject> spendableOutputs = [];
    int spendableSatoshiValue = 0;

    // Build list of spendable outputs and totaling their satoshi amount
    for (var i = 0; i < availableOutputs.length; i++) {
      if (availableOutputs[i].blocked == false &&
          availableOutputs[i].status.confirmed == true) {
        spendableOutputs.add(availableOutputs[i]);
        spendableSatoshiValue += availableOutputs[i].value;
      }
    }

    // sort spendable by age (oldest first)
    spendableOutputs.sort(
        (a, b) => b.status.confirmations.compareTo(a.status.confirmations));

    // If the amount the user is trying to send is smaller than the amount that they have spendable,
    // then return 1, which indicates that they have an insufficient balance.
    if (spendableSatoshiValue < satoshiAmountToSend) {
      return 1;
      // If the amount the user wants to send is exactly equal to the amount they can spend, then return
      // 2, which indicates that they are not leaving enough over to pay the transaction fee
    } else if (spendableSatoshiValue == satoshiAmountToSend && !isSendAll) {
      return 2;
    }
    // If neither of these statements pass, we assume that the user has a spendable balance greater
    // than the amount they're attempting to send. Note that this value still does not account for
    // the added transaction fee, which may require an extra input and will need to be checked for
    // later on.

    // Possible situation right here
    int satoshisBeingUsed = 0;
    int inputsBeingConsumed = 0;
    List<UtxoObject> utxoObjectsToUse = [];

    for (var i = 0;
        satoshisBeingUsed < satoshiAmountToSend && i < spendableOutputs.length;
        i++) {
      utxoObjectsToUse.add(spendableOutputs[i]);
      satoshisBeingUsed += spendableOutputs[i].value;
      inputsBeingConsumed += 1;
    }
    for (int i = 0;
        i < additionalOutputs && inputsBeingConsumed < spendableOutputs.length;
        i++) {
      utxoObjectsToUse.add(spendableOutputs[inputsBeingConsumed]);
      satoshisBeingUsed += spendableOutputs[inputsBeingConsumed].value;
      inputsBeingConsumed += 1;
    }

    // numberOfOutputs' length must always be equal to that of recipientsArray and recipientsAmtArray
    List<String> recipientsArray = [_recipientAddress];
    List<int> recipientsAmtArray = [satoshiAmountToSend];

    // gather required signing data
    final utxoSigningData = await fetchBuildTxData(utxoObjectsToUse);

    if (isSendAll) {
      Logging.instance
          .log("Attempting to send all $coin", level: LogLevel.Info);

      final int vSizeForOneOutput = (await buildTransaction(
        utxosToUse: utxoObjectsToUse,
        utxoSigningData: utxoSigningData,
        recipients: [_recipientAddress],
        satoshiAmounts: [satoshisBeingUsed - 1],
      ))["vSize"] as int;
      int feeForOneOutput = estimateTxFee(
        vSize: vSizeForOneOutput,
        feeRatePerKB: selectedTxFeeRate,
      );

      final int roughEstimate =
          roughFeeEstimate(spendableOutputs.length, 1, selectedTxFeeRate);
      if (feeForOneOutput < roughEstimate) {
        feeForOneOutput = roughEstimate;
      }

      final int amount = satoshiAmountToSend - feeForOneOutput;
      dynamic txn = await buildTransaction(
        utxosToUse: utxoObjectsToUse,
        utxoSigningData: utxoSigningData,
        recipients: recipientsArray,
        satoshiAmounts: [amount],
      );
      Map<String, dynamic> transactionObject = {
        "hex": txn["hex"],
        "recipient": recipientsArray[0],
        "recipientAmt": amount,
        "fee": feeForOneOutput,
        "vSize": txn["vSize"],
      };
      return transactionObject;
    }

    final int vSizeForOneOutput = (await buildTransaction(
      utxosToUse: utxoObjectsToUse,
      utxoSigningData: utxoSigningData,
      recipients: [_recipientAddress],
      satoshiAmounts: [satoshisBeingUsed - 1],
    ))["vSize"] as int;
    final int vSizeForTwoOutPuts = (await buildTransaction(
      utxosToUse: utxoObjectsToUse,
      utxoSigningData: utxoSigningData,
      recipients: [
        _recipientAddress,
        await _getCurrentAddressForChain(1, DerivePathType.bip84),
      ],
      satoshiAmounts: [
        satoshiAmountToSend,
        satoshisBeingUsed - satoshiAmountToSend - 1
      ], // dust limit is the minimum amount a change output should be
    ))["vSize"] as int;

    // Assume 1 output, only for recipient and no change
    final feeForOneOutput = estimateTxFee(
      vSize: vSizeForOneOutput,
      feeRatePerKB: selectedTxFeeRate,
    );
    // Assume 2 outputs, one for recipient and one for change
    final feeForTwoOutputs = estimateTxFee(
      vSize: vSizeForTwoOutPuts,
      feeRatePerKB: selectedTxFeeRate,
    );

    Logging.instance
        .log("feeForTwoOutputs: $feeForTwoOutputs", level: LogLevel.Info);
    Logging.instance
        .log("feeForOneOutput: $feeForOneOutput", level: LogLevel.Info);

    if (satoshisBeingUsed - satoshiAmountToSend > feeForOneOutput) {
      if (satoshisBeingUsed - satoshiAmountToSend >
          feeForOneOutput + DUST_LIMIT) {
        // Here, we know that theoretically, we may be able to include another output(change) but we first need to
        // factor in the value of this output in satoshis.
        int changeOutputSize =
            satoshisBeingUsed - satoshiAmountToSend - feeForTwoOutputs;
        // We check to see if the user can pay for the new transaction with 2 outputs instead of one. If they can and
        // the second output's size > DUST_LIMIT satoshis, we perform the mechanics required to properly generate and use a new
        // change address.
        if (changeOutputSize > DUST_LIMIT &&
            satoshisBeingUsed - satoshiAmountToSend - changeOutputSize ==
                feeForTwoOutputs) {
          // generate new change address if current change address has been used
          await _checkChangeAddressForTransactions(DerivePathType.bip84);
          final String newChangeAddress =
              await _getCurrentAddressForChain(1, DerivePathType.bip84);

          int feeBeingPaid =
              satoshisBeingUsed - satoshiAmountToSend - changeOutputSize;

          recipientsArray.add(newChangeAddress);
          recipientsAmtArray.add(changeOutputSize);
          // At this point, we have the outputs we're going to use, the amounts to send along with which addresses
          // we intend to send these amounts to. We have enough to send instructions to build the transaction.
          Logging.instance.log('2 outputs in tx', level: LogLevel.Info);
          Logging.instance
              .log('Input size: $satoshisBeingUsed', level: LogLevel.Info);
          Logging.instance.log('Recipient output size: $satoshiAmountToSend',
              level: LogLevel.Info);
          Logging.instance.log('Change Output Size: $changeOutputSize',
              level: LogLevel.Info);
          Logging.instance.log(
              'Difference (fee being paid): $feeBeingPaid sats',
              level: LogLevel.Info);
          Logging.instance
              .log('Estimated fee: $feeForTwoOutputs', level: LogLevel.Info);
          dynamic txn = await buildTransaction(
            utxosToUse: utxoObjectsToUse,
            utxoSigningData: utxoSigningData,
            recipients: recipientsArray,
            satoshiAmounts: recipientsAmtArray,
          );

          // make sure minimum fee is accurate if that is being used
          if (txn["vSize"] - feeBeingPaid == 1) {
            int changeOutputSize =
                satoshisBeingUsed - satoshiAmountToSend - (txn["vSize"] as int);
            feeBeingPaid =
                satoshisBeingUsed - satoshiAmountToSend - changeOutputSize;
            recipientsAmtArray.removeLast();
            recipientsAmtArray.add(changeOutputSize);
            Logging.instance.log('Adjusted Input size: $satoshisBeingUsed',
                level: LogLevel.Info);
            Logging.instance.log(
                'Adjusted Recipient output size: $satoshiAmountToSend',
                level: LogLevel.Info);
            Logging.instance.log(
                'Adjusted Change Output Size: $changeOutputSize',
                level: LogLevel.Info);
            Logging.instance.log(
                'Adjusted Difference (fee being paid): $feeBeingPaid sats',
                level: LogLevel.Info);
            Logging.instance.log('Adjusted Estimated fee: $feeForTwoOutputs',
                level: LogLevel.Info);
            txn = await buildTransaction(
              utxosToUse: utxoObjectsToUse,
              utxoSigningData: utxoSigningData,
              recipients: recipientsArray,
              satoshiAmounts: recipientsAmtArray,
            );
          }

          Map<String, dynamic> transactionObject = {
            "hex": txn["hex"],
            "recipient": recipientsArray[0],
            "recipientAmt": recipientsAmtArray[0],
            "fee": feeBeingPaid,
            "vSize": txn["vSize"],
          };
          return transactionObject;
        } else {
          // Something went wrong here. It either overshot or undershot the estimated fee amount or the changeOutputSize
          // is smaller than or equal to DUST_LIMIT. Revert to single output transaction.
          Logging.instance.log('1 output in tx', level: LogLevel.Info);
          Logging.instance
              .log('Input size: $satoshisBeingUsed', level: LogLevel.Info);
          Logging.instance.log('Recipient output size: $satoshiAmountToSend',
              level: LogLevel.Info);
          Logging.instance.log(
              'Difference (fee being paid): ${satoshisBeingUsed - satoshiAmountToSend} sats',
              level: LogLevel.Info);
          Logging.instance
              .log('Estimated fee: $feeForOneOutput', level: LogLevel.Info);
          dynamic txn = await buildTransaction(
            utxosToUse: utxoObjectsToUse,
            utxoSigningData: utxoSigningData,
            recipients: recipientsArray,
            satoshiAmounts: recipientsAmtArray,
          );
          Map<String, dynamic> transactionObject = {
            "hex": txn["hex"],
            "recipient": recipientsArray[0],
            "recipientAmt": recipientsAmtArray[0],
            "fee": satoshisBeingUsed - satoshiAmountToSend,
            "vSize": txn["vSize"],
          };
          return transactionObject;
        }
      } else {
        // No additional outputs needed since adding one would mean that it'd be smaller than DUST_LIMIT sats
        // which makes it uneconomical to add to the transaction. Here, we pass data directly to instruct
        // the wallet to begin crafting the transaction that the user requested.
        Logging.instance.log('1 output in tx', level: LogLevel.Info);
        Logging.instance
            .log('Input size: $satoshisBeingUsed', level: LogLevel.Info);
        Logging.instance.log('Recipient output size: $satoshiAmountToSend',
            level: LogLevel.Info);
        Logging.instance.log(
            'Difference (fee being paid): ${satoshisBeingUsed - satoshiAmountToSend} sats',
            level: LogLevel.Info);
        Logging.instance
            .log('Estimated fee: $feeForOneOutput', level: LogLevel.Info);
        dynamic txn = await buildTransaction(
          utxosToUse: utxoObjectsToUse,
          utxoSigningData: utxoSigningData,
          recipients: recipientsArray,
          satoshiAmounts: recipientsAmtArray,
        );
        Map<String, dynamic> transactionObject = {
          "hex": txn["hex"],
          "recipient": recipientsArray[0],
          "recipientAmt": recipientsAmtArray[0],
          "fee": satoshisBeingUsed - satoshiAmountToSend,
          "vSize": txn["vSize"],
        };
        return transactionObject;
      }
    } else if (satoshisBeingUsed - satoshiAmountToSend == feeForOneOutput) {
      // In this scenario, no additional change output is needed since inputs - outputs equal exactly
      // what we need to pay for fees. Here, we pass data directly to instruct the wallet to begin
      // crafting the transaction that the user requested.
      Logging.instance.log('1 output in tx', level: LogLevel.Info);
      Logging.instance
          .log('Input size: $satoshisBeingUsed', level: LogLevel.Info);
      Logging.instance.log('Recipient output size: $satoshiAmountToSend',
          level: LogLevel.Info);
      Logging.instance.log(
          'Fee being paid: ${satoshisBeingUsed - satoshiAmountToSend} sats',
          level: LogLevel.Info);
      Logging.instance
          .log('Estimated fee: $feeForOneOutput', level: LogLevel.Info);
      dynamic txn = await buildTransaction(
        utxosToUse: utxoObjectsToUse,
        utxoSigningData: utxoSigningData,
        recipients: recipientsArray,
        satoshiAmounts: recipientsAmtArray,
      );
      Map<String, dynamic> transactionObject = {
        "hex": txn["hex"],
        "recipient": recipientsArray[0],
        "recipientAmt": recipientsAmtArray[0],
        "fee": feeForOneOutput,
        "vSize": txn["vSize"],
      };
      return transactionObject;
    } else {
      // Remember that returning 2 indicates that the user does not have a sufficient balance to
      // pay for the transaction fee. Ideally, at this stage, we should check if the user has any
      // additional outputs they're able to spend and then recalculate fees.
      Logging.instance.log(
          'Cannot pay tx fee - checking for more outputs and trying again',
          level: LogLevel.Warning);
      // try adding more outputs
      if (spendableOutputs.length > inputsBeingConsumed) {
        return coinSelection(satoshiAmountToSend, selectedTxFeeRate,
            _recipientAddress, isSendAll,
            additionalOutputs: additionalOutputs + 1, utxos: utxos);
      }
      return 2;
    }
  }

  Future<Map<String, dynamic>> fetchBuildTxData(
    List<UtxoObject> utxosToUse,
  ) async {
    // return data
    Map<String, dynamic> results = {};
    Map<String, List<String>> addressTxid = {};

    // addresses to check
    List<String> addressesP2PKH = [];
    List<String> addressesP2SH = [];
    List<String> addressesP2WPKH = [];

    try {
      // Populating the addresses to check
      for (var i = 0; i < utxosToUse.length; i++) {
        final txid = utxosToUse[i].txid;
        final tx = await _cachedElectrumXClient.getTransaction(
          txHash: txid,
          coin: coin,
        );

        for (final output in tx["vout"] as List) {
          final n = output["n"];
          if (n != null && n == utxosToUse[i].vout) {
            Logging.instance.log("THIS OUTPUT IS  ${output["scriptPubKey"]}",
                level: LogLevel.Info, printFullLength: true);
            final address = output["scriptPubKey"]["addresses"][0] as String;
            if (!addressTxid.containsKey(address)) {
              addressTxid[address] = <String>[];
            }
            (addressTxid[address] as List).add(txid);
            switch (addressType(address: address)) {
              case DerivePathType.bip44:
                addressesP2PKH.add(address);
                break;
              case DerivePathType.bip49:
                addressesP2SH.add(address);
                break;
              case DerivePathType.bip84:
                addressesP2WPKH.add(address);
                break;
            }
          }
        }
      }

      // p2pkh / bip44
      final p2pkhLength = addressesP2PKH.length;
      Logging.instance
          .log("THE BIP44 LENGTH IS $p2pkhLength", level: LogLevel.Info);

      if (p2pkhLength > 0) {
        final receiveDerivations = await _fetchDerivations(
          chain: 0,
          derivePathType: DerivePathType.bip44,
        );
        final changeDerivations = await _fetchDerivations(
          chain: 1,
          derivePathType: DerivePathType.bip44,
        );
        for (int i = 0; i < p2pkhLength; i++) {
          // receives
          final receiveDerivation = receiveDerivations[addressesP2PKH[i]];
          // if a match exists it will not be null
          if (receiveDerivation != null) {
            final data = P2PKH(
              data: PaymentData(
                  pubkey: Format.stringToUint8List(
                      receiveDerivation["pubKey"] as String)),
              network: _network,
            ).data;

            for (String tx in addressTxid[addressesP2PKH[i]]!) {
              results[tx] = {
                "output": data.output,
                "keyPair": ECPair.fromWIF(
                  receiveDerivation["wif"] as String,
                  network: _network,
                ),
              };
            }
          } else {
            // if its not a receive, check change
            final changeDerivation = changeDerivations[addressesP2PKH[i]];
            // if a match exists it will not be null
            if (changeDerivation != null) {
              final data = P2PKH(
                data: PaymentData(
                    pubkey: Format.stringToUint8List(
                        changeDerivation["pubKey"] as String)),
                network: _network,
              ).data;

              for (String tx in addressTxid[addressesP2PKH[i]]!) {
                results[tx] = {
                  "output": data.output,
                  "keyPair": ECPair.fromWIF(
                    changeDerivation["wif"] as String,
                    network: _network,
                  ),
                };
              }
            }
          }
        }
      }

      // p2sh / bip49
      final p2shLength = addressesP2SH.length;
      Logging.instance
          .log("THE BIP49 LENGTH IS $p2pkhLength", level: LogLevel.Info);
      if (p2shLength > 0) {
        final receiveDerivations = await _fetchDerivations(
          chain: 0,
          derivePathType: DerivePathType.bip49,
        );
        final changeDerivations = await _fetchDerivations(
          chain: 1,
          derivePathType: DerivePathType.bip49,
        );
        for (int i = 0; i < p2shLength; i++) {
          // receives
          final receiveDerivation = receiveDerivations[addressesP2SH[i]];
          // if a match exists it will not be null
          if (receiveDerivation != null) {
            final p2wpkh = P2WPKH(
                    data: PaymentData(
                        pubkey: Format.stringToUint8List(
                            receiveDerivation["pubKey"] as String)),
                    network: _network,
                    overridePrefix: particl.bech32!)
                .data;

            final redeemScript = p2wpkh.output;

            final data =
                P2SH(data: PaymentData(redeem: p2wpkh), network: _network).data;

            for (String tx in addressTxid[addressesP2SH[i]]!) {
              results[tx] = {
                "output": data.output,
                "keyPair": ECPair.fromWIF(
                  receiveDerivation["wif"] as String,
                  network: _network,
                ),
                "redeemScript": redeemScript,
              };
            }
          } else {
            // if its not a receive, check change
            final changeDerivation = changeDerivations[addressesP2SH[i]];
            // if a match exists it will not be null
            if (changeDerivation != null) {
              final p2wpkh = P2WPKH(
                      data: PaymentData(
                          pubkey: Format.stringToUint8List(
                              changeDerivation["pubKey"] as String)),
                      network: _network)
                  .data;

              final redeemScript = p2wpkh.output;

              final data =
                  P2SH(data: PaymentData(redeem: p2wpkh), network: _network)
                      .data;

              for (String tx in addressTxid[addressesP2SH[i]]!) {
                results[tx] = {
                  "output": data.output,
                  "keyPair": ECPair.fromWIF(
                    changeDerivation["wif"] as String,
                    network: _network,
                  ),
                  "redeemScript": redeemScript,
                };
              }
            }
          }
        }
      }

      // p2wpkh / bip84
      final p2wpkhLength = addressesP2WPKH.length;
      if (p2wpkhLength > 0) {
        final receiveDerivations = await _fetchDerivations(
          chain: 0,
          derivePathType: DerivePathType.bip84,
        );
        final changeDerivations = await _fetchDerivations(
          chain: 1,
          derivePathType: DerivePathType.bip84,
        );

        for (int i = 0; i < p2wpkhLength; i++) {
          // receives
          final receiveDerivation = receiveDerivations[addressesP2WPKH[i]];
          // if a match exists it will not be null
          if (receiveDerivation != null) {
            final data = P2WPKH(
              data: PaymentData(
                  pubkey: Format.stringToUint8List(
                      receiveDerivation["pubKey"] as String)),
              network: _network,
            ).data;

            for (String tx in addressTxid[addressesP2WPKH[i]]!) {
              results[tx] = {
                "output": data.output,
                "keyPair": ECPair.fromWIF(
                  receiveDerivation["wif"] as String,
                  network: _network,
                ),
              };
            }
          } else {
            // if its not a receive, check change
            final changeDerivation = changeDerivations[addressesP2WPKH[i]];
            // if a match exists it will not be null
            if (changeDerivation != null) {
              final data = P2WPKH(
                data: PaymentData(
                    pubkey: Format.stringToUint8List(
                        changeDerivation["pubKey"] as String)),
                network: _network,
              ).data;

              for (String tx in addressTxid[addressesP2WPKH[i]]!) {
                results[tx] = {
                  "output": data.output,
                  "keyPair": ECPair.fromWIF(
                    changeDerivation["wif"] as String,
                    network: _network,
                  ),
                };
              }
            }
          }
        }
      }

      return results;
    } catch (e, s) {
      Logging.instance
          .log("fetchBuildTxData() threw: $e,\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  /// Builds and signs a transaction
  Future<Map<String, dynamic>> buildTransaction({
    required List<UtxoObject> utxosToUse,
    required Map<String, dynamic> utxoSigningData,
    required List<String> recipients,
    required List<int> satoshiAmounts,
  }) async {
    Logging.instance
        .log("Starting buildTransaction ----------", level: LogLevel.Info);

    final txb = TransactionBuilder(network: _network);
    txb.setVersion(160);

    // Add transaction inputs
    for (var i = 0; i < utxosToUse.length; i++) {
      final txid = utxosToUse[i].txid;
      txb.addInput(txid, utxosToUse[i].vout, null,
          utxoSigningData[txid]["output"] as Uint8List);
    }

    // Add transaction output
    for (var i = 0; i < recipients.length; i++) {
      txb.addOutput(recipients[i], satoshiAmounts[i], particl.bech32!);
    }

    try {
      // Sign the transaction accordingly
      for (var i = 0; i < utxosToUse.length; i++) {
        final txid = utxosToUse[i].txid;

        txb.sign(
            vin: i,
            keyPair: utxoSigningData[txid]["keyPair"] as ECPair,
            witnessValue: utxosToUse[i].value,
            redeemScript: utxoSigningData[txid]["redeemScript"] as Uint8List?,
            overridePrefix: particl.bech32!);
      }
    } catch (e, s) {
      Logging.instance.log("Caught exception while signing transaction: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }

    final builtTx = txb.build(particl.bech32!);
    print("BUILT TX IS $builtTx");
    final vSize = builtTx.virtualSize();

    return {"hex": builtTx.toHex(), "vSize": vSize};
  }

  @override
  Future<void> fullRescan(
    int maxUnusedAddressGap,
    int maxNumberOfIndexesToCheck,
  ) async {
    Logging.instance.log("Starting full rescan!", level: LogLevel.Info);
    longMutex = true;
    GlobalEventBus.instance.fire(
      WalletSyncStatusChangedEvent(
        WalletSyncStatus.syncing,
        walletId,
        coin,
      ),
    );

    // clear cache
    await _cachedElectrumXClient.clearSharedTransactionCache(coin: coin);

    // back up data
    await _rescanBackup();

    try {
      final mnemonic = await _secureStore.read(key: '${_walletId}_mnemonic');
      await _recoverWalletFromBIP32SeedPhrase(
        mnemonic: mnemonic!,
        maxUnusedAddressGap: maxUnusedAddressGap,
        maxNumberOfIndexesToCheck: maxNumberOfIndexesToCheck,
      );

      longMutex = false;
      Logging.instance.log("Full rescan complete!", level: LogLevel.Info);
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          coin,
        ),
      );
    } catch (e, s) {
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.unableToSync,
          walletId,
          coin,
        ),
      );

      // restore from backup
      await _rescanRestore();

      longMutex = false;
      Logging.instance.log("Exception rethrown from fullRescan(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _rescanRestore() async {
    Logging.instance.log("starting rescan restore", level: LogLevel.Info);

    // restore from backup
    // p2pkh
    final tempReceivingAddressesP2PKH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'receivingAddressesP2PKH_BACKUP');
    final tempChangeAddressesP2PKH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'changeAddressesP2PKH_BACKUP');
    final tempReceivingIndexP2PKH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'receivingIndexP2PKH_BACKUP');
    final tempChangeIndexP2PKH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'changeIndexP2PKH_BACKUP');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingAddressesP2PKH',
        value: tempReceivingAddressesP2PKH);
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'changeAddressesP2PKH',
        value: tempChangeAddressesP2PKH);
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingIndexP2PKH',
        value: tempReceivingIndexP2PKH);
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'changeIndexP2PKH',
        value: tempChangeIndexP2PKH);
    await DB.instance.delete<dynamic>(
        key: 'receivingAddressesP2PKH_BACKUP', boxName: walletId);
    await DB.instance
        .delete<dynamic>(key: 'changeAddressesP2PKH_BACKUP', boxName: walletId);
    await DB.instance
        .delete<dynamic>(key: 'receivingIndexP2PKH_BACKUP', boxName: walletId);
    await DB.instance
        .delete<dynamic>(key: 'changeIndexP2PKH_BACKUP', boxName: walletId);

    // p2Sh
    final tempReceivingAddressesP2SH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'receivingAddressesP2SH_BACKUP');
    final tempChangeAddressesP2SH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'changeAddressesP2SH_BACKUP');
    final tempReceivingIndexP2SH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'receivingIndexP2SH_BACKUP');
    final tempChangeIndexP2SH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'changeIndexP2SH_BACKUP');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingAddressesP2SH',
        value: tempReceivingAddressesP2SH);
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'changeAddressesP2SH',
        value: tempChangeAddressesP2SH);
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingIndexP2SH',
        value: tempReceivingIndexP2SH);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'changeIndexP2SH', value: tempChangeIndexP2SH);
    await DB.instance.delete<dynamic>(
        key: 'receivingAddressesP2SH_BACKUP', boxName: walletId);
    await DB.instance
        .delete<dynamic>(key: 'changeAddressesP2SH_BACKUP', boxName: walletId);
    await DB.instance
        .delete<dynamic>(key: 'receivingIndexP2SH_BACKUP', boxName: walletId);
    await DB.instance
        .delete<dynamic>(key: 'changeIndexP2SH_BACKUP', boxName: walletId);

    // p2wpkh
    final tempReceivingAddressesP2WPKH = DB.instance.get<dynamic>(
        boxName: walletId, key: 'receivingAddressesP2WPKH_BACKUP');
    final tempChangeAddressesP2WPKH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'changeAddressesP2WPKH_BACKUP');
    final tempReceivingIndexP2WPKH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'receivingIndexP2WPKH_BACKUP');
    final tempChangeIndexP2WPKH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'changeIndexP2WPKH_BACKUP');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingAddressesP2WPKH',
        value: tempReceivingAddressesP2WPKH);
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'changeAddressesP2WPKH',
        value: tempChangeAddressesP2WPKH);
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingIndexP2WPKH',
        value: tempReceivingIndexP2WPKH);
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'changeIndexP2WPKH',
        value: tempChangeIndexP2WPKH);
    await DB.instance.delete<dynamic>(
        key: 'receivingAddressesP2WPKH_BACKUP', boxName: walletId);
    await DB.instance.delete<dynamic>(
        key: 'changeAddressesP2WPKH_BACKUP', boxName: walletId);
    await DB.instance
        .delete<dynamic>(key: 'receivingIndexP2WPKH_BACKUP', boxName: walletId);
    await DB.instance
        .delete<dynamic>(key: 'changeIndexP2WPKH_BACKUP', boxName: walletId);

    // P2PKH derivations
    final p2pkhReceiveDerivationsString = await _secureStore.read(
        key: "${walletId}_receiveDerivationsP2PKH_BACKUP");
    final p2pkhChangeDerivationsString = await _secureStore.read(
        key: "${walletId}_changeDerivationsP2PKH_BACKUP");

    await _secureStore.write(
        key: "${walletId}_receiveDerivationsP2PKH",
        value: p2pkhReceiveDerivationsString);
    await _secureStore.write(
        key: "${walletId}_changeDerivationsP2PKH",
        value: p2pkhChangeDerivationsString);

    await _secureStore.delete(
        key: "${walletId}_receiveDerivationsP2PKH_BACKUP");
    await _secureStore.delete(key: "${walletId}_changeDerivationsP2PKH_BACKUP");

    // P2SH derivations
    final p2shReceiveDerivationsString = await _secureStore.read(
        key: "${walletId}_receiveDerivationsP2SH_BACKUP");
    final p2shChangeDerivationsString = await _secureStore.read(
        key: "${walletId}_changeDerivationsP2SH_BACKUP");

    await _secureStore.write(
        key: "${walletId}_receiveDerivationsP2SH",
        value: p2shReceiveDerivationsString);
    await _secureStore.write(
        key: "${walletId}_changeDerivationsP2SH",
        value: p2shChangeDerivationsString);

    await _secureStore.delete(key: "${walletId}_receiveDerivationsP2SH_BACKUP");
    await _secureStore.delete(key: "${walletId}_changeDerivationsP2SH_BACKUP");

    // P2WPKH derivations
    final p2wpkhReceiveDerivationsString = await _secureStore.read(
        key: "${walletId}_receiveDerivationsP2WPKH_BACKUP");
    final p2wpkhChangeDerivationsString = await _secureStore.read(
        key: "${walletId}_changeDerivationsP2WPKH_BACKUP");

    await _secureStore.write(
        key: "${walletId}_receiveDerivationsP2WPKH",
        value: p2wpkhReceiveDerivationsString);
    await _secureStore.write(
        key: "${walletId}_changeDerivationsP2WPKH",
        value: p2wpkhChangeDerivationsString);

    await _secureStore.delete(
        key: "${walletId}_receiveDerivationsP2WPKH_BACKUP");
    await _secureStore.delete(
        key: "${walletId}_changeDerivationsP2WPKH_BACKUP");

    // UTXOs
    final utxoData = DB.instance
        .get<dynamic>(boxName: walletId, key: 'latest_utxo_model_BACKUP');
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'latest_utxo_model', value: utxoData);
    await DB.instance
        .delete<dynamic>(key: 'latest_utxo_model_BACKUP', boxName: walletId);

    Logging.instance.log("rescan restore  complete", level: LogLevel.Info);
  }

  Future<void> _rescanBackup() async {
    Logging.instance.log("starting rescan backup", level: LogLevel.Info);

    // backup current and clear data
    // p2pkh
    final tempReceivingAddressesP2PKH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'receivingAddressesP2PKH');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingAddressesP2PKH_BACKUP',
        value: tempReceivingAddressesP2PKH);
    await DB.instance
        .delete<dynamic>(key: 'receivingAddressesP2PKH', boxName: walletId);

    final tempChangeAddressesP2PKH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'changeAddressesP2PKH');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'changeAddressesP2PKH_BACKUP',
        value: tempChangeAddressesP2PKH);
    await DB.instance
        .delete<dynamic>(key: 'changeAddressesP2PKH', boxName: walletId);

    final tempReceivingIndexP2PKH =
        DB.instance.get<dynamic>(boxName: walletId, key: 'receivingIndexP2PKH');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingIndexP2PKH_BACKUP',
        value: tempReceivingIndexP2PKH);
    await DB.instance
        .delete<dynamic>(key: 'receivingIndexP2PKH', boxName: walletId);

    final tempChangeIndexP2PKH =
        DB.instance.get<dynamic>(boxName: walletId, key: 'changeIndexP2PKH');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'changeIndexP2PKH_BACKUP',
        value: tempChangeIndexP2PKH);
    await DB.instance
        .delete<dynamic>(key: 'changeIndexP2PKH', boxName: walletId);

    // p2sh
    final tempReceivingAddressesP2SH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'receivingAddressesP2SH');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingAddressesP2SH_BACKUP',
        value: tempReceivingAddressesP2SH);
    await DB.instance
        .delete<dynamic>(key: 'receivingAddressesP2SH', boxName: walletId);

    final tempChangeAddressesP2SH =
        DB.instance.get<dynamic>(boxName: walletId, key: 'changeAddressesP2SH');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'changeAddressesP2SH_BACKUP',
        value: tempChangeAddressesP2SH);
    await DB.instance
        .delete<dynamic>(key: 'changeAddressesP2SH', boxName: walletId);

    final tempReceivingIndexP2SH =
        DB.instance.get<dynamic>(boxName: walletId, key: 'receivingIndexP2SH');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingIndexP2SH_BACKUP',
        value: tempReceivingIndexP2SH);
    await DB.instance
        .delete<dynamic>(key: 'receivingIndexP2SH', boxName: walletId);

    final tempChangeIndexP2SH =
        DB.instance.get<dynamic>(boxName: walletId, key: 'changeIndexP2SH');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'changeIndexP2SH_BACKUP',
        value: tempChangeIndexP2SH);
    await DB.instance
        .delete<dynamic>(key: 'changeIndexP2SH', boxName: walletId);

    // p2wpkh
    final tempReceivingAddressesP2WPKH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'receivingAddressesP2WPKH');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingAddressesP2WPKH_BACKUP',
        value: tempReceivingAddressesP2WPKH);
    await DB.instance
        .delete<dynamic>(key: 'receivingAddressesP2WPKH', boxName: walletId);

    final tempChangeAddressesP2WPKH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'changeAddressesP2WPKH');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'changeAddressesP2WPKH_BACKUP',
        value: tempChangeAddressesP2WPKH);
    await DB.instance
        .delete<dynamic>(key: 'changeAddressesP2WPKH', boxName: walletId);

    final tempReceivingIndexP2WPKH = DB.instance
        .get<dynamic>(boxName: walletId, key: 'receivingIndexP2WPKH');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingIndexP2WPKH_BACKUP',
        value: tempReceivingIndexP2WPKH);
    await DB.instance
        .delete<dynamic>(key: 'receivingIndexP2WPKH', boxName: walletId);

    final tempChangeIndexP2WPKH =
        DB.instance.get<dynamic>(boxName: walletId, key: 'changeIndexP2WPKH');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'changeIndexP2WPKH_BACKUP',
        value: tempChangeIndexP2WPKH);
    await DB.instance
        .delete<dynamic>(key: 'changeIndexP2WPKH', boxName: walletId);

    // P2PKH derivations
    final p2pkhReceiveDerivationsString =
        await _secureStore.read(key: "${walletId}_receiveDerivationsP2PKH");
    final p2pkhChangeDerivationsString =
        await _secureStore.read(key: "${walletId}_changeDerivationsP2PKH");

    await _secureStore.write(
        key: "${walletId}_receiveDerivationsP2PKH_BACKUP",
        value: p2pkhReceiveDerivationsString);
    await _secureStore.write(
        key: "${walletId}_changeDerivationsP2PKH_BACKUP",
        value: p2pkhChangeDerivationsString);

    await _secureStore.delete(key: "${walletId}_receiveDerivationsP2PKH");
    await _secureStore.delete(key: "${walletId}_changeDerivationsP2PKH");

    // P2SH derivations
    final p2shReceiveDerivationsString =
        await _secureStore.read(key: "${walletId}_receiveDerivationsP2SH");
    final p2shChangeDerivationsString =
        await _secureStore.read(key: "${walletId}_changeDerivationsP2SH");

    await _secureStore.write(
        key: "${walletId}_receiveDerivationsP2SH_BACKUP",
        value: p2shReceiveDerivationsString);
    await _secureStore.write(
        key: "${walletId}_changeDerivationsP2SH_BACKUP",
        value: p2shChangeDerivationsString);

    await _secureStore.delete(key: "${walletId}_receiveDerivationsP2SH");
    await _secureStore.delete(key: "${walletId}_changeDerivationsP2SH");

    // P2WPKH derivations
    final p2wpkhReceiveDerivationsString =
        await _secureStore.read(key: "${walletId}_receiveDerivationsP2WPKH");
    final p2wpkhChangeDerivationsString =
        await _secureStore.read(key: "${walletId}_changeDerivationsP2WPKH");

    await _secureStore.write(
        key: "${walletId}_receiveDerivationsP2WPKH_BACKUP",
        value: p2wpkhReceiveDerivationsString);
    await _secureStore.write(
        key: "${walletId}_changeDerivationsP2WPKH_BACKUP",
        value: p2wpkhChangeDerivationsString);

    await _secureStore.delete(key: "${walletId}_receiveDerivationsP2WPKH");
    await _secureStore.delete(key: "${walletId}_changeDerivationsP2WPKH");

    // UTXOs
    final utxoData =
        DB.instance.get<dynamic>(boxName: walletId, key: 'latest_utxo_model');
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'latest_utxo_model_BACKUP', value: utxoData);
    await DB.instance
        .delete<dynamic>(key: 'latest_utxo_model', boxName: walletId);

    Logging.instance.log("rescan backup complete", level: LogLevel.Info);
  }

  bool isActive = false;

  @override
  void Function(bool)? get onIsActiveWalletChanged =>
      (isActive) => this.isActive = isActive;

  @override
  Future<int> estimateFeeFor(int satoshiAmount, int feeRate) async {
    final available = Format.decimalAmountToSatoshis(await availableBalance);

    if (available == satoshiAmount) {
      return satoshiAmount - sweepAllEstimate(feeRate);
    } else if (satoshiAmount <= 0 || satoshiAmount > available) {
      return roughFeeEstimate(1, 2, feeRate);
    }

    int runningBalance = 0;
    int inputCount = 0;
    for (final output in outputsList) {
      runningBalance += output.value;
      inputCount++;
      if (runningBalance > satoshiAmount) {
        break;
      }
    }

    final oneOutPutFee = roughFeeEstimate(inputCount, 1, feeRate);
    final twoOutPutFee = roughFeeEstimate(inputCount, 2, feeRate);

    if (runningBalance - satoshiAmount > oneOutPutFee) {
      if (runningBalance - satoshiAmount > oneOutPutFee + DUST_LIMIT) {
        final change = runningBalance - satoshiAmount - twoOutPutFee;
        if (change > DUST_LIMIT &&
            runningBalance - satoshiAmount - change == twoOutPutFee) {
          return runningBalance - satoshiAmount - change;
        } else {
          return runningBalance - satoshiAmount;
        }
      } else {
        return runningBalance - satoshiAmount;
      }
    } else if (runningBalance - satoshiAmount == oneOutPutFee) {
      return oneOutPutFee;
    } else {
      return twoOutPutFee;
    }
  }

  int roughFeeEstimate(int inputCount, int outputCount, int feeRatePerKB) {
    return ((42 + (272 * inputCount) + (128 * outputCount)) / 4).ceil() *
        (feeRatePerKB / 1000).ceil();
  }

  int sweepAllEstimate(int feeRate) {
    int available = 0;
    int inputCount = 0;
    for (final output in outputsList) {
      if (output.status.confirmed) {
        available += output.value;
        inputCount++;
      }
    }

    // transaction will only have 1 output minus the fee
    final estimatedFee = roughFeeEstimate(inputCount, 1, feeRate);

    return available - estimatedFee;
  }

  @override
  Future<bool> generateNewAddress() async {
    try {
      await _incrementAddressIndexForChain(
          0, DerivePathType.bip84); // First increment the receiving index
      final newReceivingIndex = DB.instance.get<dynamic>(
          boxName: walletId,
          key: 'receivingIndexP2WPKH') as int; // Check the new receiving index
      final newReceivingAddress = await _generateAddressForChain(
          0,
          newReceivingIndex,
          DerivePathType
              .bip84); // Use new index to derive a new receiving address
      await _addToAddressesArrayForChain(
          newReceivingAddress,
          0,
          DerivePathType
              .bip84); // Add that new receiving address to the array of receiving addresses
      _currentReceivingAddress = Future(() =>
          newReceivingAddress); // Set the new receiving address that the service

      return true;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from generateNewAddress(): $e\n$s",
          level: LogLevel.Error);
      return false;
    }
  }
}

// Particl Network
final particl = NetworkType(
    messagePrefix: '\x18Bitcoin Signed Message:\n',
    bech32: 'pw',
    bip32: Bip32Type(public: 0x696e82d1, private: 0x8f1daeb8),
    pubKeyHash: 0x38,
    scriptHash: 0x3c,
    wif: 0x6c);
