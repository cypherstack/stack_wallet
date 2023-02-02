import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bech32/bech32.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoindart/bitcoindart.dart';
import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:crypto/crypto.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/electrumx_rpc/cached_electrumx.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart' as isar_models;
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/mixins/electrum_x_parsing.dart';
import 'package:stackwallet/services/mixins/wallet_cache.dart';
import 'package:stackwallet/services/mixins/wallet_db.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/notifications_api.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

const int MINIMUM_CONFIRMATIONS = 1;
const int DUST_LIMIT = 294;
const int DUST_LIMIT_P2PKH = 546;

const String GENESIS_HASH_MAINNET =
    "12a765e31ffd4059bada1e25190f6e98c99d9714d334efa41a195a7e7e04bfe2";
const String GENESIS_HASH_TESTNET =
    "4966625a4b2851d9fdee139e56211a0d88575f59ed816ff5e6a63deb4e3e29a0";

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
    case 0xb0: // ltc mainnet wif
      coinType = "2"; // ltc mainnet
      break;
    case 0xef: // ltc testnet wif
      coinType = "1"; // ltc testnet
      break;
    default:
      throw Exception("Invalid Litecoin network type used!");
  }
  switch (derivePathType) {
    case DerivePathType.bip44:
      return root.derivePath("m/44'/$coinType'/0'/$chain/$index");
    case DerivePathType.bip49:
      return root.derivePath("m/49'/$coinType'/0'/$chain/$index");
    case DerivePathType.bip84:
      return root.derivePath("m/84'/$coinType'/0'/$chain/$index");
    default:
      throw Exception("DerivePathType unsupported");
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

class LitecoinWallet extends CoinServiceAPI
    with WalletCache, WalletDB, ElectrumXParsing {
  static const integrationTestFlag =
      bool.fromEnvironment("IS_INTEGRATION_TEST");

  final _prefs = Prefs.instance;

  Timer? timer;
  late final Coin _coin;

  late final TransactionNotificationTracker txTracker;

  NetworkType get _network {
    switch (coin) {
      case Coin.litecoin:
        return litecoin;
      case Coin.litecoinTestNet:
        return litecointestnet;
      default:
        throw Exception("Invalid network type!");
    }
  }

  @override
  set isFavorite(bool markFavorite) {
    _isFavorite = markFavorite;
    updateCachedIsFavorite(markFavorite);
  }

  @override
  bool get isFavorite => _isFavorite ??= getCachedIsFavorite();

  bool? _isFavorite;

  @override
  Coin get coin => _coin;

  @override
  Future<List<isar_models.UTXO>> get utxos => db.getUTXOs(walletId).findAll();

  @override
  Future<List<isar_models.Transaction>> get transactions =>
      db.getTransactions(walletId).sortByTimestampDesc().findAll();

  @override
  Future<String> get currentReceivingAddress async =>
      (await _currentReceivingAddress).value;

  Future<isar_models.Address> get _currentReceivingAddress async =>
      (await db
          .getAddresses(walletId)
          .filter()
          .typeEqualTo(isar_models.AddressType.p2wpkh)
          .subTypeEqualTo(isar_models.AddressSubType.receiving)
          .sortByDerivationIndexDesc()
          .findFirst()) ??
      await _generateAddressForChain(0, 0, DerivePathTypeExt.primaryFor(coin));

  Future<String> get currentChangeAddress async =>
      (await _currentChangeAddress).value;

  Future<isar_models.Address> get _currentChangeAddress async =>
      (await db
          .getAddresses(walletId)
          .filter()
          .typeEqualTo(isar_models.AddressType.p2wpkh)
          .subTypeEqualTo(isar_models.AddressSubType.change)
          .sortByDerivationIndexDesc()
          .findFirst()) ??
      await _generateAddressForChain(1, 0, DerivePathTypeExt.primaryFor(coin));

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
    final satsFee =
        Decimal.parse(fee) * Decimal.fromInt(Constants.satsPerCoin(coin));
    return satsFee.floor().toBigInt().toInt();
  }

  @override
  Future<List<String>> get mnemonic => _getMnemonicList();

  Future<int> get chainHeight async {
    try {
      final result = await _electrumXClient.getBlockHeadTip();
      final height = result["height"] as int;
      await updateCachedChainHeight(height);
      if (height > storedChainHeight) {
        GlobalEventBus.instance.fire(
          UpdatedInBackgroundEvent(
            "Updated current chain height in $walletId $walletName!",
            walletId,
          ),
        );
      }
      return height;
    } catch (e, s) {
      Logging.instance.log("Exception caught in chainHeight: $e\n$s",
          level: LogLevel.Error);
      return storedChainHeight;
    }
  }

  @override
  int get storedChainHeight => getCachedChainHeight();

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
        decodeBech32 = segwit.decode(address, _network.bech32!);
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
          case Coin.litecoin:
            if (features['genesis_hash'] != GENESIS_HASH_MAINNET) {
              throw Exception("genesis hash does not match main net!");
            }
            break;
          case Coin.litecoinTestNet:
            if (features['genesis_hash'] != GENESIS_HASH_TESTNET) {
              throw Exception("genesis hash does not match test net!");
            }
            break;
          default:
            throw Exception(
                "Attempted to generate a LitecoinWallet using a non litecoin coin type: ${coin.name}");
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
      int chain) async {
    List<isar_models.Address> addressArray = [];
    int returningIndex = -1;
    Map<String, Map<String, String>> derivations = {};
    int gapCounter = 0;
    for (int index = 0;
        index < maxNumberOfIndexesToCheck && gapCounter < maxUnusedAddressGap;
        index += txCountBatchSize) {
      List<String> iterationsAddressArray = [];
      Logging.instance.log(
          "index: $index, \t GapCounter $chain ${type.name}: $gapCounter",
          level: LogLevel.Info);

      final _id = "k_$index";
      Map<String, String> txCountCallArgs = {};
      final Map<String, dynamic> receivingNodes = {};

      for (int j = 0; j < txCountBatchSize; j++) {
        final node = await compute(
          getBip32NodeFromRootWrapper,
          Tuple4(
            chain,
            index + j,
            root,
            type,
          ),
        );
        String addressString;
        final data = PaymentData(pubkey: node.publicKey);
        isar_models.AddressType addrType;
        switch (type) {
          case DerivePathType.bip44:
            addressString = P2PKH(data: data, network: _network).data.address!;
            addrType = isar_models.AddressType.p2pkh;
            break;
          case DerivePathType.bip49:
            addressString = P2SH(
                    data: PaymentData(
                        redeem: P2WPKH(
                                data: data,
                                network: _network,
                                overridePrefix: _network.bech32!)
                            .data),
                    network: _network)
                .data
                .address!;
            addrType = isar_models.AddressType.p2sh;
            break;
          case DerivePathType.bip84:
            addressString = P2WPKH(
                    network: _network,
                    data: data,
                    overridePrefix: _network.bech32!)
                .data
                .address!;
            addrType = isar_models.AddressType.p2wpkh;
            break;
          default:
            throw Exception("DerivePathType unsupported");
        }

        final address = isar_models.Address(
          walletId: walletId,
          value: addressString,
          publicKey: node.publicKey,
          type: addrType,
          derivationIndex: index + j,
          subType: chain == 0
              ? isar_models.AddressSubType.receiving
              : isar_models.AddressSubType.change,
        );

        receivingNodes.addAll({
          "${_id}_$j": {
            "node": node,
            "address": address,
          }
        });
        txCountCallArgs.addAll({
          "${_id}_$j": addressString,
        });
      }

      // get address tx counts
      final counts = await _getBatchTxCount(addresses: txCountCallArgs);

      // check and add appropriate addresses
      for (int k = 0; k < txCountBatchSize; k++) {
        int count = counts["${_id}_$k"]!;
        if (count > 0) {
          final node = receivingNodes["${_id}_$k"];
          final address = node["address"] as isar_models.Address;
          // add address to array
          addressArray.add(address);
          iterationsAddressArray.add(address.value);
          // set current index
          returningIndex = index + k;
          // reset counter
          gapCounter = 0;
          // add info to derivations
          derivations[address.value] = {
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

    List<isar_models.Address> p2pkhReceiveAddressArray = [];
    List<isar_models.Address> p2shReceiveAddressArray = [];
    List<isar_models.Address> p2wpkhReceiveAddressArray = [];
    int p2pkhReceiveIndex = -1;
    int p2shReceiveIndex = -1;
    int p2wpkhReceiveIndex = -1;

    List<isar_models.Address> p2pkhChangeAddressArray = [];
    List<isar_models.Address> p2shChangeAddressArray = [];
    List<isar_models.Address> p2wpkhChangeAddressArray = [];
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
          (await resultReceive44)['addressArray'] as List<isar_models.Address>;
      p2pkhReceiveIndex = (await resultReceive44)['index'] as int;
      p2pkhReceiveDerivations = (await resultReceive44)['derivations']
          as Map<String, Map<String, String>>;

      p2shReceiveAddressArray =
          (await resultReceive49)['addressArray'] as List<isar_models.Address>;
      p2shReceiveIndex = (await resultReceive49)['index'] as int;
      p2shReceiveDerivations = (await resultReceive49)['derivations']
          as Map<String, Map<String, String>>;

      p2wpkhReceiveAddressArray =
          (await resultReceive84)['addressArray'] as List<isar_models.Address>;
      p2wpkhReceiveIndex = (await resultReceive84)['index'] as int;
      p2wpkhReceiveDerivations = (await resultReceive84)['derivations']
          as Map<String, Map<String, String>>;

      p2pkhChangeAddressArray =
          (await resultChange44)['addressArray'] as List<isar_models.Address>;
      p2pkhChangeIndex = (await resultChange44)['index'] as int;
      p2pkhChangeDerivations = (await resultChange44)['derivations']
          as Map<String, Map<String, String>>;

      p2shChangeAddressArray =
          (await resultChange49)['addressArray'] as List<isar_models.Address>;
      p2shChangeIndex = (await resultChange49)['index'] as int;
      p2shChangeDerivations = (await resultChange49)['derivations']
          as Map<String, Map<String, String>>;

      p2wpkhChangeAddressArray =
          (await resultChange84)['addressArray'] as List<isar_models.Address>;
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
      }
      if (p2shReceiveIndex == -1) {
        final address =
            await _generateAddressForChain(0, 0, DerivePathType.bip49);
        p2shReceiveAddressArray.add(address);
      }
      if (p2wpkhReceiveIndex == -1) {
        final address =
            await _generateAddressForChain(0, 0, DerivePathType.bip84);
        p2wpkhReceiveAddressArray.add(address);
      }

      // If restoring a wallet that never sent any funds with change, then set changeArray
      // manually. If we didn't do this, it'd store an empty array.
      if (p2pkhChangeIndex == -1) {
        final address =
            await _generateAddressForChain(1, 0, DerivePathType.bip44);
        p2pkhChangeAddressArray.add(address);
      }
      if (p2shChangeIndex == -1) {
        final address =
            await _generateAddressForChain(1, 0, DerivePathType.bip49);
        p2shChangeAddressArray.add(address);
      }
      if (p2wpkhChangeIndex == -1) {
        final address =
            await _generateAddressForChain(1, 0, DerivePathType.bip84);
        p2wpkhChangeAddressArray.add(address);
      }

      await db.putAddresses([
        ...p2wpkhReceiveAddressArray,
        ...p2wpkhChangeAddressArray,
        ...p2pkhReceiveAddressArray,
        ...p2pkhChangeAddressArray,
        ...p2shReceiveAddressArray,
        ...p2shChangeAddressArray,
      ]);

      await _updateUTXOs();

      await Future.wait([
        updateCachedId(walletId),
        updateCachedIsFavorite(false),
      ]);

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
        List<Map<String, dynamic>> allTxs = await _fetchHistory(
            allOwnAddresses.map((e) => e.value).toList(growable: false));
        for (Map<String, dynamic> transaction in allTxs) {
          final txid = transaction['tx_hash'] as String;
          if ((await db
                  .getTransactions(walletId)
                  .filter()
                  .txidMatches(txid)
                  .findFirst()) ==
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

  Future<void> getAllTxsToWatch() async {
    if (_hasCalledExit) return;
    List<isar_models.Transaction> unconfirmedTxnsToNotifyPending = [];
    List<isar_models.Transaction> unconfirmedTxnsToNotifyConfirmed = [];

    final currentChainHeight = await chainHeight;

    final txCount = await db.getTransactions(walletId).count();

    const paginateLimit = 50;

    for (int i = 0; i < txCount; i += paginateLimit) {
      final transactions = await db
          .getTransactions(walletId)
          .offset(i)
          .limit(paginateLimit)
          .findAll();
      for (final tx in transactions) {
        if (tx.isConfirmed(currentChainHeight, MINIMUM_CONFIRMATIONS)) {
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
      final confirmations = tx.getConfirmations(currentChainHeight);

      if (tx.type == isar_models.TransactionType.incoming) {
        unawaited(NotificationApi.showNotification(
          title: "Incoming transaction",
          body: walletName,
          walletId: walletId,
          iconAssetName: Assets.svg.iconFor(coin: coin),
          date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
          shouldWatchForUpdates: confirmations < MINIMUM_CONFIRMATIONS,
          coinName: coin.name,
          txid: tx.txid,
          confirmations: confirmations,
          requiredConfirmations: MINIMUM_CONFIRMATIONS,
        ));
        await txTracker.addNotifiedPending(tx.txid);
      } else if (tx.type == isar_models.TransactionType.outgoing) {
        unawaited(NotificationApi.showNotification(
          title: "Sending transaction",
          body: walletName,
          walletId: walletId,
          iconAssetName: Assets.svg.iconFor(coin: coin),
          date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
          shouldWatchForUpdates: confirmations < MINIMUM_CONFIRMATIONS,
          coinName: coin.name,
          txid: tx.txid,
          confirmations: confirmations,
          requiredConfirmations: MINIMUM_CONFIRMATIONS,
        ));
        await txTracker.addNotifiedPending(tx.txid);
      }
    }

    // notify on confirmed
    for (final tx in unconfirmedTxnsToNotifyConfirmed) {
      if (tx.type == isar_models.TransactionType.incoming) {
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
      } else if (tx.type == isar_models.TransactionType.outgoing) {
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
        GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.2, walletId));
        await _checkChangeAddressForTransactions();

        GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.3, walletId));
        await _checkCurrentReceivingAddressesForTransactions();

        final fetchFuture = _refreshTransactions();
        final utxosRefreshFuture = _updateUTXOs();
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.50, walletId));

        final feeObj = _getFees();
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.60, walletId));

        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.70, walletId));
        _feeObject = Future(() => feeObj);

        await utxosRefreshFuture;
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.80, walletId));

        await fetchFuture;
        await getAllTxsToWatch();
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
        if (satoshiAmount == balance.spendable) {
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

    if (getCachedId() != null) {
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
      updateCachedId(walletId),
      updateCachedIsFavorite(false),
    ]);
  }

  @override
  Future<void> initializeExisting() async {
    Logging.instance.log("Opening existing ${coin.prettyName} wallet.",
        level: LogLevel.Info);

    if (getCachedId() == null) {
      throw Exception(
          "Attempted to initialize an existing wallet using an unknown wallet ID!");
    }
    await _prefs.init();
    await _checkCurrentChangeAddressesForTransactions();
    await _checkCurrentReceivingAddressesForTransactions();
  }

  // hack to add tx to txData before refresh completes
  // required based on current app architecture where we don't properly store
  // transactions locally in a good way
  @override
  Future<void> updateSentCachedTxData(Map<String, dynamic> txData) async {
    // final priceData =
    //     await _priceAPI.getPricesAnd24hChange(baseCurrency: _prefs.currency);
    // Decimal currentPrice = priceData[coin]?.item1 ?? Decimal.zero;
    // final locale =
    //     Platform.isWindows ? "en_US" : await Devicelocale.currentLocale;
    // final String worthNow = Format.localizedStringAsFixed(
    //     value:
    //         ((currentPrice * Decimal.fromInt(txData["recipientAmt"] as int)) /
    //                 Decimal.fromInt(Constants.satsPerCoin(coin)))
    //             .toDecimal(scaleOnInfinitePrecision: 2),
    //     decimalPlaces: 2,
    //     locale: locale!);
    //
    // final tx = models.Transaction(
    //   txid: txData["txid"] as String,
    //   confirmedStatus: false,
    //   timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    //   txType: "Sent",
    //   amount: txData["recipientAmt"] as int,
    //   worthNow: worthNow,
    //   worthAtBlockTimestamp: worthNow,
    //   fees: txData["fee"] as int,
    //   inputSize: 0,
    //   outputSize: 0,
    //   inputs: [],
    //   outputs: [],
    //   address: txData["address"] as String,
    //   height: -1,
    //   confirmations: 0,
    // );
    //
    // if (cachedTxData == null) {
    //   final data = await _refreshTransactions();
    //   _transactionData = Future(() => data);
    // }
    //
    // final transactions = cachedTxData!.getAllTransactions();
    // transactions[tx.txid] = tx;
    // cachedTxData = models.TransactionData.fromMap(transactions);
    // _transactionData = Future(() => cachedTxData!);
  }

  @override
  bool validateAddress(String address) {
    return Address.validateAddress(address, _network, _network.bech32!);
  }

  @override
  String get walletId => _walletId;
  late final String _walletId;

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

  LitecoinWallet({
    required String walletId,
    required String walletName,
    required Coin coin,
    required ElectrumX client,
    required CachedElectrumX cachedClient,
    required TransactionNotificationTracker tracker,
    required SecureStorageInterface secureStore,
    MainDB? mockableOverride,
  }) {
    txTracker = tracker;
    _walletId = walletId;
    _walletName = walletName;
    _coin = coin;
    _electrumXClient = client;
    _cachedElectrumXClient = cachedClient;
    _secureStore = secureStore;
    initCache(walletId, coin);
    initWalletDB(mockableOverride: mockableOverride);
  }

  @override
  Future<void> updateNode(bool shouldRefresh) async {
    final failovers = NodeService(secureStorageInterface: _secureStore)
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
    final node = NodeService(secureStorageInterface: _secureStore)
            .getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);

    return ElectrumXNode(
      address: node.host,
      port: node.port,
      name: node.name,
      useSSL: node.useSSL,
      id: node.id,
    );
  }

  Future<List<isar_models.Address>> _fetchAllOwnAddresses() async {
    final allAddresses = await db
        .getAddresses(walletId)
        .filter()
        .not()
        .typeEqualTo(isar_models.AddressType.nonWallet)
        .and()
        .group((q) => q
            .subTypeEqualTo(isar_models.AddressSubType.receiving)
            .or()
            .subTypeEqualTo(isar_models.AddressSubType.change))
        .findAll();
    // final List<String> allAddresses = [];
    // final receivingAddresses = DB.instance.get<dynamic>(
    //     boxName: walletId, key: 'receivingAddressesP2WPKH') as List<dynamic>;
    // final changeAddresses = DB.instance.get<dynamic>(
    //     boxName: walletId, key: 'changeAddressesP2WPKH') as List<dynamic>;
    // final receivingAddressesP2PKH = DB.instance.get<dynamic>(
    //     boxName: walletId, key: 'receivingAddressesP2PKH') as List<dynamic>;
    // final changeAddressesP2PKH =
    //     DB.instance.get<dynamic>(boxName: walletId, key: 'changeAddressesP2PKH')
    //         as List<dynamic>;
    // final receivingAddressesP2SH = DB.instance.get<dynamic>(
    //     boxName: walletId, key: 'receivingAddressesP2SH') as List<dynamic>;
    // final changeAddressesP2SH =
    //     DB.instance.get<dynamic>(boxName: walletId, key: 'changeAddressesP2SH')
    //         as List<dynamic>;
    //
    // for (var i = 0; i < receivingAddresses.length; i++) {
    //   if (!allAddresses.contains(receivingAddresses[i])) {
    //     allAddresses.add(receivingAddresses[i] as String);
    //   }
    // }
    // for (var i = 0; i < changeAddresses.length; i++) {
    //   if (!allAddresses.contains(changeAddresses[i])) {
    //     allAddresses.add(changeAddresses[i] as String);
    //   }
    // }
    // for (var i = 0; i < receivingAddressesP2PKH.length; i++) {
    //   if (!allAddresses.contains(receivingAddressesP2PKH[i])) {
    //     allAddresses.add(receivingAddressesP2PKH[i] as String);
    //   }
    // }
    // for (var i = 0; i < changeAddressesP2PKH.length; i++) {
    //   if (!allAddresses.contains(changeAddressesP2PKH[i])) {
    //     allAddresses.add(changeAddressesP2PKH[i] as String);
    //   }
    // }
    // for (var i = 0; i < receivingAddressesP2SH.length; i++) {
    //   if (!allAddresses.contains(receivingAddressesP2SH[i])) {
    //     allAddresses.add(receivingAddressesP2SH[i] as String);
    //   }
    // }
    // for (var i = 0; i < changeAddressesP2SH.length; i++) {
    //   if (!allAddresses.contains(changeAddressesP2SH[i])) {
    //     allAddresses.add(changeAddressesP2SH[i] as String);
    //   }
    // }
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
        fast: Format.decimalAmountToSatoshis(fast, coin),
        medium: Format.decimalAmountToSatoshis(medium, coin),
        slow: Format.decimalAmountToSatoshis(slow, coin),
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
      try {
        final features = await electrumXClient
            .getServerFeatures()
            .timeout(const Duration(seconds: 3));
        Logging.instance.log("features: $features", level: LogLevel.Info);
        switch (coin) {
          case Coin.litecoin:
            if (features['genesis_hash'] != GENESIS_HASH_MAINNET) {
              // print(features['genesis_hash']);
              throw Exception("genesis hash does not match main net!");
            }
            break;
          case Coin.litecoinTestNet:
            if (features['genesis_hash'] != GENESIS_HASH_TESTNET) {
              throw Exception("genesis hash does not match test net!");
            }
            break;
          default:
            throw Exception(
                "Attempted to generate a LitecoinWallet using a non litecoin coin type: ${coin.name}");
        }
      } catch (e, s) {
        Logging.instance.log("$e/n$s", level: LogLevel.Info);
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

    // Generate and add addresses to relevant arrays
    final initialAddresses = await Future.wait([
      // P2WPKH
      _generateAddressForChain(0, 0, DerivePathType.bip84),
      _generateAddressForChain(1, 0, DerivePathType.bip84),

      // P2PKH
      _generateAddressForChain(0, 0, DerivePathType.bip44),
      _generateAddressForChain(1, 0, DerivePathType.bip44),

      // P2SH
      _generateAddressForChain(0, 0, DerivePathType.bip49),
      _generateAddressForChain(1, 0, DerivePathType.bip49),
    ]);

    await db.putAddresses(initialAddresses);

    Logging.instance.log("_generateNewWalletFinished", level: LogLevel.Info);
  }

  /// Generates a new internal or external chain address for the wallet using a BIP84, BIP44, or BIP49 derivation path.
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  /// [index] - This can be any integer >= 0
  Future<isar_models.Address> _generateAddressForChain(
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
    isar_models.AddressType addrType;

    switch (derivePathType) {
      case DerivePathType.bip44:
        address = P2PKH(data: data, network: _network).data.address!;
        addrType = isar_models.AddressType.p2pkh;
        break;
      case DerivePathType.bip49:
        address = P2SH(
                data: PaymentData(
                    redeem: P2WPKH(
                            data: data,
                            network: _network,
                            overridePrefix: _network.bech32!)
                        .data),
                network: _network)
            .data
            .address!;
        addrType = isar_models.AddressType.p2sh;
        break;
      case DerivePathType.bip84:
        address = P2WPKH(
                network: _network, data: data, overridePrefix: _network.bech32!)
            .data
            .address!;
        addrType = isar_models.AddressType.p2wpkh;
        break;
      default:
        throw Exception("DerivePathType unsupported");
    }

    // add generated address & info to derivations
    await addDerivation(
      chain: chain,
      address: address,
      pubKey: Format.uint8listToString(node.publicKey),
      wif: node.toWIF(),
      derivePathType: derivePathType,
    );

    return isar_models.Address(
      walletId: walletId,
      value: address,
      publicKey: node.publicKey,
      type: addrType,
      derivationIndex: index,
      subType: chain == 0
          ? isar_models.AddressSubType.receiving
          : isar_models.AddressSubType.change,
    );
  }

  /// Returns the latest receiving/change (external/internal) address for the wallet depending on [chain]
  /// and
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<String> _getCurrentAddressForChain(
    int chain,
    DerivePathType derivePathType,
  ) async {
    final subType = chain == 0 // Here, we assume that chain == 1 if it isn't 0
        ? isar_models.AddressSubType.receiving
        : isar_models.AddressSubType.change;

    isar_models.AddressType type;
    isar_models.Address? address;
    switch (derivePathType) {
      case DerivePathType.bip44:
        type = isar_models.AddressType.p2pkh;
        break;
      case DerivePathType.bip49:
        type = isar_models.AddressType.p2sh;
        break;
      case DerivePathType.bip84:
        type = isar_models.AddressType.p2wpkh;
        break;
      default:
        throw Exception("DerivePathType unsupported");
    }
    address = await db
        .getAddresses(walletId)
        .filter()
        .typeEqualTo(type)
        .subTypeEqualTo(subType)
        .sortByDerivationIndexDesc()
        .findFirst();
    return address!.value;
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
      default:
        throw Exception("DerivePathType unsupported");
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

  Future<void> _updateUTXOs() async {
    final allAddresses = await _fetchAllOwnAddresses();

    try {
      final fetchedUtxoList = <List<Map<String, dynamic>>>[];

      final Map<int, Map<String, List<dynamic>>> batches = {};
      const batchSizeMax = 100;
      int batchNumber = 0;
      for (int i = 0; i < allAddresses.length; i++) {
        if (batches[batchNumber] == null) {
          batches[batchNumber] = {};
        }
        final scripthash =
            _convertToScriptHash(allAddresses[i].value, _network);
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

      final currentChainHeight = await chainHeight;

      final List<isar_models.UTXO> outputArray = [];
      int satoshiBalanceTotal = 0;
      int satoshiBalancePending = 0;
      int satoshiBalanceSpendable = 0;
      int satoshiBalanceBlocked = 0;

      for (int i = 0; i < fetchedUtxoList.length; i++) {
        for (int j = 0; j < fetchedUtxoList[i].length; j++) {
          final txn = await cachedElectrumXClient.getTransaction(
            txHash: fetchedUtxoList[i][j]["tx_hash"] as String,
            verbose: true,
            coin: coin,
          );

          // todo check here if we should mark as blocked
          final utxo = isar_models.UTXO(
            walletId: walletId,
            txid: txn["txid"] as String,
            vout: fetchedUtxoList[i][j]["tx_pos"] as int,
            value: fetchedUtxoList[i][j]["value"] as int,
            name: "",
            isBlocked: false,
            blockedReason: null,
            isCoinbase: txn["is_coinbase"] as bool? ?? false,
            blockHash: txn["blockhash"] as String?,
            blockHeight: fetchedUtxoList[i][j]["height"] as int?,
            blockTime: txn["blocktime"] as int?,
          );

          satoshiBalanceTotal += utxo.value;

          if (utxo.isBlocked) {
            satoshiBalanceBlocked += utxo.value;
          } else {
            if (utxo.isConfirmed(currentChainHeight, MINIMUM_CONFIRMATIONS)) {
              satoshiBalanceSpendable += utxo.value;
            } else {
              satoshiBalancePending += utxo.value;
            }
          }

          outputArray.add(utxo);
        }
      }

      Logging.instance
          .log('Outputs fetched: $outputArray', level: LogLevel.Info);

      // TODO move this out of here and into IDB
      await db.isar.writeTxn(() async {
        await db.isar.utxos.where().walletIdEqualTo(walletId).deleteAll();
        await db.isar.utxos.putAll(outputArray);
      });

      // finally update balance
      _balance = Balance(
        coin: coin,
        total: satoshiBalanceTotal,
        spendable: satoshiBalanceSpendable,
        blockedTotal: satoshiBalanceBlocked,
        pendingSpendable: satoshiBalancePending,
      );
      await updateCachedBalance(_balance!);
    } catch (e, s) {
      Logging.instance
          .log("Output fetch unsuccessful: $e\n$s", level: LogLevel.Error);
    }
  }

  @override
  Balance get balance => _balance ??= getCachedBalance();
  Balance? _balance;

  // /// Takes in a list of UtxoObjects and adds a name (dependent on object index within list)
  // /// and checks for the txid associated with the utxo being blocked and marks it accordingly.
  // /// Now also checks for output labeling.
  // Future<void> _sortOutputs(List<UtxoObject> utxos) async {
  //   final blockedHashArray =
  //       DB.instance.get<dynamic>(boxName: walletId, key: 'blocked_tx_hashes')
  //           as List<dynamic>?;
  //   final List<String> lst = [];
  //   if (blockedHashArray != null) {
  //     for (var hash in blockedHashArray) {
  //       lst.add(hash as String);
  //     }
  //   }
  //   final labels =
  //       DB.instance.get<dynamic>(boxName: walletId, key: 'labels') as Map? ??
  //           {};
  //
  //   outputsList = [];
  //
  //   for (var i = 0; i < utxos.length; i++) {
  //     if (labels[utxos[i].txid] != null) {
  //       utxos[i].txName = labels[utxos[i].txid] as String? ?? "";
  //     } else {
  //       utxos[i].txName = 'Output #$i';
  //     }
  //
  //     if (utxos[i].status.confirmed == false) {
  //       outputsList.add(utxos[i]);
  //     } else {
  //       if (lst.contains(utxos[i].txid)) {
  //         utxos[i].blocked = true;
  //         outputsList.add(utxos[i]);
  //       } else if (!lst.contains(utxos[i].txid)) {
  //         outputsList.add(utxos[i]);
  //       }
  //     }
  //   }
  // }

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

  Future<void> _checkReceivingAddressForTransactions() async {
    try {
      final currentReceiving = await _currentReceivingAddress;

      final int txCount = await getTxCount(address: currentReceiving.value);
      Logging.instance.log(
          'Number of txs for current receiving address $currentReceiving: $txCount',
          level: LogLevel.Info);

      if (txCount >= 1 || currentReceiving.derivationIndex < 0) {
        // First increment the receiving index
        final newReceivingIndex = currentReceiving.derivationIndex + 1;

        // Use new index to derive a new receiving address
        final newReceivingAddress = await _generateAddressForChain(
            0, newReceivingIndex, DerivePathTypeExt.primaryFor(coin));

        final existing = await db
            .getAddresses(walletId)
            .filter()
            .valueEqualTo(newReceivingAddress.value)
            .findFirst();
        if (existing == null) {
          // Add that new change address
          await db.putAddress(newReceivingAddress);
        } else {
          // we need to update the address
          await db.updateAddress(existing, newReceivingAddress);
        }
        // keep checking until address with no tx history is set as current
        await _checkReceivingAddressForTransactions();
      }
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _checkReceivingAddressForTransactions(${DerivePathTypeExt.primaryFor(coin)}): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _checkChangeAddressForTransactions() async {
    try {
      final currentChange = await _currentChangeAddress;
      final int txCount = await getTxCount(address: currentChange.value);
      Logging.instance.log(
          'Number of txs for current change address $currentChange: $txCount',
          level: LogLevel.Info);

      if (txCount >= 1 || currentChange.derivationIndex < 0) {
        // First increment the change index
        final newChangeIndex = currentChange.derivationIndex + 1;

        // Use new index to derive a new change address
        final newChangeAddress = await _generateAddressForChain(
            1, newChangeIndex, DerivePathTypeExt.primaryFor(coin));

        final existing = await db
            .getAddresses(walletId)
            .filter()
            .valueEqualTo(newChangeAddress.value)
            .findFirst();
        if (existing == null) {
          // Add that new change address
          await db.putAddress(newChangeAddress);
        } else {
          // we need to update the address
          await db.updateAddress(existing, newChangeAddress);
        }
        // keep checking until address with no tx history is set as current
        await _checkChangeAddressForTransactions();
      }
    } on SocketException catch (se, s) {
      Logging.instance.log(
          "SocketException caught in _checkReceivingAddressForTransactions(${DerivePathTypeExt.primaryFor(coin)}): $se\n$s",
          level: LogLevel.Error);
      return;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _checkReceivingAddressForTransactions(${DerivePathTypeExt.primaryFor(coin)}): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _checkCurrentReceivingAddressesForTransactions() async {
    try {
      // for (final type in DerivePathType.values) {
      await _checkReceivingAddressForTransactions();
      // }
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
      // for (final type in DerivePathType.values) {
      await _checkChangeAddressForTransactions();
      // }
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
  /// Returns the scripthash or throws an exception on invalid litecoin address
  String _convertToScriptHash(String litecoinAddress, NetworkType network) {
    try {
      final output = Address.addressToOutputScript(
          litecoinAddress, network, _network.bech32!);
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

  bool _duplicateTxCheck(
      List<Map<String, dynamic>> allTransactions, String txid) {
    for (int i = 0; i < allTransactions.length; i++) {
      if (allTransactions[i]["txid"] == txid) {
        return true;
      }
    }
    return false;
  }

  Future<void> _refreshTransactions() async {
    final List<isar_models.Address> allAddresses =
        await _fetchAllOwnAddresses();

    final List<Map<String, dynamic>> allTxHashes =
        await _fetchHistory(allAddresses.map((e) => e.value).toList());

    Set<String> hashes = {};
    for (var element in allTxHashes) {
      hashes.add(element['tx_hash'] as String);
    }
    await fastFetch(hashes.toList());

    List<Map<String, dynamic>> allTransactions = [];
    final currentHeight = await chainHeight;

    for (final txHash in allTxHashes) {
      final storedTx = await db
          .getTransactions(walletId)
          .filter()
          .txidEqualTo(txHash["tx_hash"] as String)
          .findFirst();

      if (storedTx == null ||
          !storedTx.isConfirmed(currentHeight, MINIMUM_CONFIRMATIONS)) {
        final tx = await cachedElectrumXClient.getTransaction(
          txHash: txHash["tx_hash"] as String,
          verbose: true,
          coin: coin,
        );

        // Logging.instance.log("TRANSACTION: ${jsonEncode(tx)}");
        if (!_duplicateTxCheck(allTransactions, tx["txid"] as String)) {
          tx["address"] = await db
              .getAddresses(walletId)
              .filter()
              .valueEqualTo(txHash["address"] as String)
              .findFirst();
          tx["height"] = txHash["height"];
          allTransactions.add(tx);
        }
      }
    }

    // prefetch/cache
    Set<String> vHashes = {};
    for (final txObject in allTransactions) {
      for (int i = 0; i < (txObject["vin"] as List).length; i++) {
        final input = txObject["vin"]![i] as Map;
        final prevTxid = input["txid"] as String;
        vHashes.add(prevTxid);
      }
    }
    await fastFetch(vHashes.toList());

    final List<
        Tuple4<isar_models.Transaction, List<isar_models.Output>,
            List<isar_models.Input>, isar_models.Address?>> txnsData = [];

    for (final txObject in allTransactions) {
      final data = await parseTransaction(
        txObject,
        cachedElectrumXClient,
        allAddresses,
        coin,
        MINIMUM_CONFIRMATIONS,
        walletId,
      );

      txnsData.add(data);
    }
    await db.addNewTransactionData(txnsData, walletId);

    // quick hack to notify manager to call notifyListeners if
    // transactions changed
    if (txnsData.isNotEmpty) {
      GlobalEventBus.instance.fire(
        UpdatedInBackgroundEvent(
          "Transactions updated/added for: $walletId $walletName  ",
          walletId,
        ),
      );
    }
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
    List<isar_models.UTXO>? utxos,
  }) async {
    Logging.instance
        .log("Starting coinSelection ----------", level: LogLevel.Info);
    final List<isar_models.UTXO> availableOutputs = utxos ?? await this.utxos;
    final currentChainHeight = await chainHeight;
    final List<isar_models.UTXO> spendableOutputs = [];
    int spendableSatoshiValue = 0;

    // Build list of spendable outputs and totaling their satoshi amount
    for (var i = 0; i < availableOutputs.length; i++) {
      if (availableOutputs[i].isBlocked == false &&
          availableOutputs[i]
                  .isConfirmed(currentChainHeight, MINIMUM_CONFIRMATIONS) ==
              true) {
        spendableOutputs.add(availableOutputs[i]);
        spendableSatoshiValue += availableOutputs[i].value;
      }
    }

    // sort spendable by age (oldest first)
    spendableOutputs.sort((a, b) => b.blockTime!.compareTo(a.blockTime!));

    Logging.instance.log("spendableOutputs.length: ${spendableOutputs.length}",
        level: LogLevel.Info);
    Logging.instance
        .log("spendableOutputs: $spendableOutputs", level: LogLevel.Info);
    Logging.instance.log("spendableSatoshiValue: $spendableSatoshiValue",
        level: LogLevel.Info);
    Logging.instance
        .log("satoshiAmountToSend: $satoshiAmountToSend", level: LogLevel.Info);
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
    List<isar_models.UTXO> utxoObjectsToUse = [];

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

    Logging.instance
        .log("satoshisBeingUsed: $satoshisBeingUsed", level: LogLevel.Info);
    Logging.instance
        .log("inputsBeingConsumed: $inputsBeingConsumed", level: LogLevel.Info);
    Logging.instance
        .log('utxoObjectsToUse: $utxoObjectsToUse', level: LogLevel.Info);

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
        await _getCurrentAddressForChain(1, DerivePathTypeExt.primaryFor(coin)),
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
          await _checkChangeAddressForTransactions();
          final String newChangeAddress = await _getCurrentAddressForChain(
              1, DerivePathTypeExt.primaryFor(coin));

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
    List<isar_models.UTXO> utxosToUse,
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
              default:
                throw Exception("DerivePathType unsupported");
            }
          }
        }
      }

      // p2pkh / bip44
      final p2pkhLength = addressesP2PKH.length;
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
                    overridePrefix: _network.bech32!)
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
                      network: _network,
                      overridePrefix: _network.bech32!)
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
                    overridePrefix: _network.bech32!)
                .data;

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
                      overridePrefix: _network.bech32!)
                  .data;

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
    required List<isar_models.UTXO> utxosToUse,
    required Map<String, dynamic> utxoSigningData,
    required List<String> recipients,
    required List<int> satoshiAmounts,
  }) async {
    Logging.instance
        .log("Starting buildTransaction ----------", level: LogLevel.Info);

    final txb = TransactionBuilder(network: _network);
    txb.setVersion(1);

    // Add transaction inputs
    for (var i = 0; i < utxosToUse.length; i++) {
      final txid = utxosToUse[i].txid;
      txb.addInput(txid, utxosToUse[i].vout, null,
          utxoSigningData[txid]["output"] as Uint8List, _network.bech32!);
    }

    // Add transaction output
    for (var i = 0; i < recipients.length; i++) {
      txb.addOutput(recipients[i], satoshiAmounts[i], _network.bech32!);
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
            overridePrefix: _network.bech32!);
      }
    } catch (e, s) {
      Logging.instance.log("Caught exception while signing transaction: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }

    final builtTx = txb.build(_network.bech32!);
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
    // await _rescanBackup();

    // clear blockchain info
    await db.deleteWalletBlockchainData(walletId);
    await _deleteDerivations();

    try {
      final mnemonic = await _secureStore.read(key: '${_walletId}_mnemonic');
      await _recoverWalletFromBIP32SeedPhrase(
        mnemonic: mnemonic!,
        maxUnusedAddressGap: maxUnusedAddressGap,
        maxNumberOfIndexesToCheck: maxNumberOfIndexesToCheck,
      );

      longMutex = false;
      await refresh();
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
      // await _rescanRestore();

      longMutex = false;
      Logging.instance.log("Exception rethrown from fullRescan(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _deleteDerivations() async {
    // P2PKH derivations
    await _secureStore.delete(key: "${walletId}_receiveDerivationsP2PKH");
    await _secureStore.delete(key: "${walletId}_changeDerivationsP2PKH");

    // P2SH derivations
    await _secureStore.delete(key: "${walletId}_receiveDerivationsP2SH");
    await _secureStore.delete(key: "${walletId}_changeDerivationsP2SH");

    // P2WPKH derivations
    await _secureStore.delete(key: "${walletId}_receiveDerivationsP2WPKH");
    await _secureStore.delete(key: "${walletId}_changeDerivationsP2WPKH");
  }

  // Future<void> _rescanRestore() async {
  //   Logging.instance.log("starting rescan restore", level: LogLevel.Info);
  //
  //   // restore from backup
  //   // p2pkh
  //   final tempReceivingAddressesP2PKH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'receivingAddressesP2PKH_BACKUP');
  //   final tempChangeAddressesP2PKH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'changeAddressesP2PKH_BACKUP');
  //   final tempReceivingIndexP2PKH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'receivingIndexP2PKH_BACKUP');
  //   final tempChangeIndexP2PKH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'changeIndexP2PKH_BACKUP');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'receivingAddressesP2PKH',
  //       value: tempReceivingAddressesP2PKH);
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'changeAddressesP2PKH',
  //       value: tempChangeAddressesP2PKH);
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'receivingIndexP2PKH',
  //       value: tempReceivingIndexP2PKH);
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'changeIndexP2PKH',
  //       value: tempChangeIndexP2PKH);
  //   await DB.instance.delete<dynamic>(
  //       key: 'receivingAddressesP2PKH_BACKUP', boxName: walletId);
  //   await DB.instance
  //       .delete<dynamic>(key: 'changeAddressesP2PKH_BACKUP', boxName: walletId);
  //   await DB.instance
  //       .delete<dynamic>(key: 'receivingIndexP2PKH_BACKUP', boxName: walletId);
  //   await DB.instance
  //       .delete<dynamic>(key: 'changeIndexP2PKH_BACKUP', boxName: walletId);
  //
  //   // p2Sh
  //   final tempReceivingAddressesP2SH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'receivingAddressesP2SH_BACKUP');
  //   final tempChangeAddressesP2SH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'changeAddressesP2SH_BACKUP');
  //   final tempReceivingIndexP2SH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'receivingIndexP2SH_BACKUP');
  //   final tempChangeIndexP2SH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'changeIndexP2SH_BACKUP');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'receivingAddressesP2SH',
  //       value: tempReceivingAddressesP2SH);
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'changeAddressesP2SH',
  //       value: tempChangeAddressesP2SH);
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'receivingIndexP2SH',
  //       value: tempReceivingIndexP2SH);
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId, key: 'changeIndexP2SH', value: tempChangeIndexP2SH);
  //   await DB.instance.delete<dynamic>(
  //       key: 'receivingAddressesP2SH_BACKUP', boxName: walletId);
  //   await DB.instance
  //       .delete<dynamic>(key: 'changeAddressesP2SH_BACKUP', boxName: walletId);
  //   await DB.instance
  //       .delete<dynamic>(key: 'receivingIndexP2SH_BACKUP', boxName: walletId);
  //   await DB.instance
  //       .delete<dynamic>(key: 'changeIndexP2SH_BACKUP', boxName: walletId);
  //
  //   // p2wpkh
  //   final tempReceivingAddressesP2WPKH = DB.instance.get<dynamic>(
  //       boxName: walletId, key: 'receivingAddressesP2WPKH_BACKUP');
  //   final tempChangeAddressesP2WPKH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'changeAddressesP2WPKH_BACKUP');
  //   final tempReceivingIndexP2WPKH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'receivingIndexP2WPKH_BACKUP');
  //   final tempChangeIndexP2WPKH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'changeIndexP2WPKH_BACKUP');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'receivingAddressesP2WPKH',
  //       value: tempReceivingAddressesP2WPKH);
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'changeAddressesP2WPKH',
  //       value: tempChangeAddressesP2WPKH);
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'receivingIndexP2WPKH',
  //       value: tempReceivingIndexP2WPKH);
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'changeIndexP2WPKH',
  //       value: tempChangeIndexP2WPKH);
  //   await DB.instance.delete<dynamic>(
  //       key: 'receivingAddressesP2WPKH_BACKUP', boxName: walletId);
  //   await DB.instance.delete<dynamic>(
  //       key: 'changeAddressesP2WPKH_BACKUP', boxName: walletId);
  //   await DB.instance
  //       .delete<dynamic>(key: 'receivingIndexP2WPKH_BACKUP', boxName: walletId);
  //   await DB.instance
  //       .delete<dynamic>(key: 'changeIndexP2WPKH_BACKUP', boxName: walletId);
  //
  //   // P2PKH derivations
  //   final p2pkhReceiveDerivationsString = await _secureStore.read(
  //       key: "${walletId}_receiveDerivationsP2PKH_BACKUP");
  //   final p2pkhChangeDerivationsString = await _secureStore.read(
  //       key: "${walletId}_changeDerivationsP2PKH_BACKUP");
  //
  //   await _secureStore.write(
  //       key: "${walletId}_receiveDerivationsP2PKH",
  //       value: p2pkhReceiveDerivationsString);
  //   await _secureStore.write(
  //       key: "${walletId}_changeDerivationsP2PKH",
  //       value: p2pkhChangeDerivationsString);
  //
  //   await _secureStore.delete(
  //       key: "${walletId}_receiveDerivationsP2PKH_BACKUP");
  //   await _secureStore.delete(key: "${walletId}_changeDerivationsP2PKH_BACKUP");
  //
  //   // P2SH derivations
  //   final p2shReceiveDerivationsString = await _secureStore.read(
  //       key: "${walletId}_receiveDerivationsP2SH_BACKUP");
  //   final p2shChangeDerivationsString = await _secureStore.read(
  //       key: "${walletId}_changeDerivationsP2SH_BACKUP");
  //
  //   await _secureStore.write(
  //       key: "${walletId}_receiveDerivationsP2SH",
  //       value: p2shReceiveDerivationsString);
  //   await _secureStore.write(
  //       key: "${walletId}_changeDerivationsP2SH",
  //       value: p2shChangeDerivationsString);
  //
  //   await _secureStore.delete(key: "${walletId}_receiveDerivationsP2SH_BACKUP");
  //   await _secureStore.delete(key: "${walletId}_changeDerivationsP2SH_BACKUP");
  //
  //   // P2WPKH derivations
  //   final p2wpkhReceiveDerivationsString = await _secureStore.read(
  //       key: "${walletId}_receiveDerivationsP2WPKH_BACKUP");
  //   final p2wpkhChangeDerivationsString = await _secureStore.read(
  //       key: "${walletId}_changeDerivationsP2WPKH_BACKUP");
  //
  //   await _secureStore.write(
  //       key: "${walletId}_receiveDerivationsP2WPKH",
  //       value: p2wpkhReceiveDerivationsString);
  //   await _secureStore.write(
  //       key: "${walletId}_changeDerivationsP2WPKH",
  //       value: p2wpkhChangeDerivationsString);
  //
  //   await _secureStore.delete(
  //       key: "${walletId}_receiveDerivationsP2WPKH_BACKUP");
  //   await _secureStore.delete(
  //       key: "${walletId}_changeDerivationsP2WPKH_BACKUP");
  //
  //   // UTXOs
  //   final utxoData = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'latest_utxo_model_BACKUP');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId, key: 'latest_utxo_model', value: utxoData);
  //   await DB.instance
  //       .delete<dynamic>(key: 'latest_utxo_model_BACKUP', boxName: walletId);
  //
  //   Logging.instance.log("rescan restore  complete", level: LogLevel.Info);
  // }
  //
  // Future<void> _rescanBackup() async {
  //   Logging.instance.log("starting rescan backup", level: LogLevel.Info);
  //
  //   // backup current and clear data
  //   // p2pkh
  //   final tempReceivingAddressesP2PKH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'receivingAddressesP2PKH');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'receivingAddressesP2PKH_BACKUP',
  //       value: tempReceivingAddressesP2PKH);
  //   await DB.instance
  //       .delete<dynamic>(key: 'receivingAddressesP2PKH', boxName: walletId);
  //
  //   final tempChangeAddressesP2PKH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'changeAddressesP2PKH');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'changeAddressesP2PKH_BACKUP',
  //       value: tempChangeAddressesP2PKH);
  //   await DB.instance
  //       .delete<dynamic>(key: 'changeAddressesP2PKH', boxName: walletId);
  //
  //   final tempReceivingIndexP2PKH =
  //       DB.instance.get<dynamic>(boxName: walletId, key: 'receivingIndexP2PKH');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'receivingIndexP2PKH_BACKUP',
  //       value: tempReceivingIndexP2PKH);
  //   await DB.instance
  //       .delete<dynamic>(key: 'receivingIndexP2PKH', boxName: walletId);
  //
  //   final tempChangeIndexP2PKH =
  //       DB.instance.get<dynamic>(boxName: walletId, key: 'changeIndexP2PKH');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'changeIndexP2PKH_BACKUP',
  //       value: tempChangeIndexP2PKH);
  //   await DB.instance
  //       .delete<dynamic>(key: 'changeIndexP2PKH', boxName: walletId);
  //
  //   // p2sh
  //   final tempReceivingAddressesP2SH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'receivingAddressesP2SH');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'receivingAddressesP2SH_BACKUP',
  //       value: tempReceivingAddressesP2SH);
  //   await DB.instance
  //       .delete<dynamic>(key: 'receivingAddressesP2SH', boxName: walletId);
  //
  //   final tempChangeAddressesP2SH =
  //       DB.instance.get<dynamic>(boxName: walletId, key: 'changeAddressesP2SH');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'changeAddressesP2SH_BACKUP',
  //       value: tempChangeAddressesP2SH);
  //   await DB.instance
  //       .delete<dynamic>(key: 'changeAddressesP2SH', boxName: walletId);
  //
  //   final tempReceivingIndexP2SH =
  //       DB.instance.get<dynamic>(boxName: walletId, key: 'receivingIndexP2SH');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'receivingIndexP2SH_BACKUP',
  //       value: tempReceivingIndexP2SH);
  //   await DB.instance
  //       .delete<dynamic>(key: 'receivingIndexP2SH', boxName: walletId);
  //
  //   final tempChangeIndexP2SH =
  //       DB.instance.get<dynamic>(boxName: walletId, key: 'changeIndexP2SH');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'changeIndexP2SH_BACKUP',
  //       value: tempChangeIndexP2SH);
  //   await DB.instance
  //       .delete<dynamic>(key: 'changeIndexP2SH', boxName: walletId);
  //
  //   // p2wpkh
  //   final tempReceivingAddressesP2WPKH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'receivingAddressesP2WPKH');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'receivingAddressesP2WPKH_BACKUP',
  //       value: tempReceivingAddressesP2WPKH);
  //   await DB.instance
  //       .delete<dynamic>(key: 'receivingAddressesP2WPKH', boxName: walletId);
  //
  //   final tempChangeAddressesP2WPKH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'changeAddressesP2WPKH');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'changeAddressesP2WPKH_BACKUP',
  //       value: tempChangeAddressesP2WPKH);
  //   await DB.instance
  //       .delete<dynamic>(key: 'changeAddressesP2WPKH', boxName: walletId);
  //
  //   final tempReceivingIndexP2WPKH = DB.instance
  //       .get<dynamic>(boxName: walletId, key: 'receivingIndexP2WPKH');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'receivingIndexP2WPKH_BACKUP',
  //       value: tempReceivingIndexP2WPKH);
  //   await DB.instance
  //       .delete<dynamic>(key: 'receivingIndexP2WPKH', boxName: walletId);
  //
  //   final tempChangeIndexP2WPKH =
  //       DB.instance.get<dynamic>(boxName: walletId, key: 'changeIndexP2WPKH');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId,
  //       key: 'changeIndexP2WPKH_BACKUP',
  //       value: tempChangeIndexP2WPKH);
  //   await DB.instance
  //       .delete<dynamic>(key: 'changeIndexP2WPKH', boxName: walletId);
  //
  //   // P2PKH derivations
  //   final p2pkhReceiveDerivationsString =
  //       await _secureStore.read(key: "${walletId}_receiveDerivationsP2PKH");
  //   final p2pkhChangeDerivationsString =
  //       await _secureStore.read(key: "${walletId}_changeDerivationsP2PKH");
  //
  //   await _secureStore.write(
  //       key: "${walletId}_receiveDerivationsP2PKH_BACKUP",
  //       value: p2pkhReceiveDerivationsString);
  //   await _secureStore.write(
  //       key: "${walletId}_changeDerivationsP2PKH_BACKUP",
  //       value: p2pkhChangeDerivationsString);
  //
  //   await _secureStore.delete(key: "${walletId}_receiveDerivationsP2PKH");
  //   await _secureStore.delete(key: "${walletId}_changeDerivationsP2PKH");
  //
  //   // P2SH derivations
  //   final p2shReceiveDerivationsString =
  //       await _secureStore.read(key: "${walletId}_receiveDerivationsP2SH");
  //   final p2shChangeDerivationsString =
  //       await _secureStore.read(key: "${walletId}_changeDerivationsP2SH");
  //
  //   await _secureStore.write(
  //       key: "${walletId}_receiveDerivationsP2SH_BACKUP",
  //       value: p2shReceiveDerivationsString);
  //   await _secureStore.write(
  //       key: "${walletId}_changeDerivationsP2SH_BACKUP",
  //       value: p2shChangeDerivationsString);
  //
  //   await _secureStore.delete(key: "${walletId}_receiveDerivationsP2SH");
  //   await _secureStore.delete(key: "${walletId}_changeDerivationsP2SH");
  //
  //   // P2WPKH derivations
  //   final p2wpkhReceiveDerivationsString =
  //       await _secureStore.read(key: "${walletId}_receiveDerivationsP2WPKH");
  //   final p2wpkhChangeDerivationsString =
  //       await _secureStore.read(key: "${walletId}_changeDerivationsP2WPKH");
  //
  //   await _secureStore.write(
  //       key: "${walletId}_receiveDerivationsP2WPKH_BACKUP",
  //       value: p2wpkhReceiveDerivationsString);
  //   await _secureStore.write(
  //       key: "${walletId}_changeDerivationsP2WPKH_BACKUP",
  //       value: p2wpkhChangeDerivationsString);
  //
  //   await _secureStore.delete(key: "${walletId}_receiveDerivationsP2WPKH");
  //   await _secureStore.delete(key: "${walletId}_changeDerivationsP2WPKH");
  //
  //   // UTXOs
  //   final utxoData =
  //       DB.instance.get<dynamic>(boxName: walletId, key: 'latest_utxo_model');
  //   await DB.instance.put<dynamic>(
  //       boxName: walletId, key: 'latest_utxo_model_BACKUP', value: utxoData);
  //   await DB.instance
  //       .delete<dynamic>(key: 'latest_utxo_model', boxName: walletId);
  //
  //   Logging.instance.log("rescan backup complete", level: LogLevel.Info);
  // }

  bool isActive = false;

  @override
  void Function(bool)? get onIsActiveWalletChanged =>
      (isActive) => this.isActive = isActive;

  @override
  Future<int> estimateFeeFor(int satoshiAmount, int feeRate) async {
    final available = balance.spendable;

    if (available == satoshiAmount) {
      return satoshiAmount - (await sweepAllEstimate(feeRate));
    } else if (satoshiAmount <= 0 || satoshiAmount > available) {
      return roughFeeEstimate(1, 2, feeRate);
    }

    int runningBalance = 0;
    int inputCount = 0;
    for (final output in (await utxos)) {
      if (!output.isBlocked) {
        runningBalance += output.value;
        inputCount++;
        if (runningBalance > satoshiAmount) {
          break;
        }
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

  Future<int> sweepAllEstimate(int feeRate) async {
    int available = 0;
    int inputCount = 0;
    for (final output in (await utxos)) {
      if (!output.isBlocked &&
          output.isConfirmed(storedChainHeight, MINIMUM_CONFIRMATIONS)) {
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
      final currentReceiving = await _currentReceivingAddress;

      final newReceivingIndex = currentReceiving.derivationIndex + 1;

      // Use new index to derive a new receiving address
      final newReceivingAddress = await _generateAddressForChain(
          0, newReceivingIndex, DerivePathTypeExt.primaryFor(coin));

      // Add that new receiving address
      await db.putAddress(newReceivingAddress);

      return true;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from generateNewAddress(): $e\n$s",
          level: LogLevel.Error);
      return false;
    }
  }
}

final litecoin = NetworkType(
    messagePrefix: '\x19Litecoin Signed Message:\n',
    bech32: 'ltc',
    bip32: Bip32Type(public: 0x0488b21e, private: 0x0488ade4),
    pubKeyHash: 0x30,
    scriptHash: 0x32,
    wif: 0xb0);

final litecointestnet = NetworkType(
    messagePrefix: '\x19Litecoin Signed Message:\n',
    bech32: 'tltc',
    bip32: Bip32Type(public: 0x043587cf, private: 0x04358394),
    pubKeyHash: 0x6f,
    scriptHash: 0x3a,
    wif: 0xef);
