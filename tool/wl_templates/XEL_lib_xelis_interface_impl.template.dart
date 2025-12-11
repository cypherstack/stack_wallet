//ON
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as xelis_sdk;
import 'package:xelis_flutter/src/api/api.dart' as xelis_api;
import 'package:xelis_flutter/src/api/logger.dart' as xelis_logging;
import 'package:xelis_flutter/src/api/network.dart' as x_network;
import 'package:xelis_flutter/src/api/seed_search_engine.dart' as x_seed;
import 'package:xelis_flutter/src/api/utils.dart' as x_utils;
import 'package:xelis_flutter/src/api/wallet.dart' as x_wallet;
import 'package:xelis_flutter/src/frb_generated.dart' as xelis_rust;

import '../../providers/progress_report/xelis_table_progress_provider.dart';
import '../../utilities/logger.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
//END_ON
import '../interfaces/lib_xelis_interface.dart';

LibXelisInterface get libXelis => _getInterface();

//OFF
LibXelisInterface _getInterface() => throw Exception("XEL not enabled!");

//END_OFF
//ON
LibXelisInterface _getInterface() => const _LibXelisInterfaceImpl();

extension _OpaqueXelisWalletExt on OpaqueXelisWallet {
  x_wallet.XelisWallet get actual => get();
}

final class _LibXelisInterfaceImpl extends LibXelisInterface {
  const _LibXelisInterfaceImpl();

  @override
  String get xelisAsset => xelis_sdk.xelisAsset;

  @override
  Future<void> initRustLib() => xelis_rust.RustLib.init();

  @override
  Future<void> setupRustLogger() => xelis_api.setUpRustLogger();

  @override
  void startListeningToRustLogs() => xelis_api.createLogStream().listen(
    (logEntry) {
      final Level level;
      switch (logEntry.level) {
        case xelis_logging.Level.error:
          level = Level.error;
        case xelis_logging.Level.warn:
          level = Level.warning;
        case xelis_logging.Level.info:
          level = Level.info;
        case xelis_logging.Level.debug:
          level = Level.debug;
        case xelis_logging.Level.trace:
          level = Level.trace;
      }

      Logging.instance.log(
        level,
        "[Xelis Rust Log] ${logEntry.tag}: ${logEntry.msg}",
      );
    },
    onError: (dynamic e) {
      Logging.instance.e("Error receiving Xelis Rust logs: $e");
    },
  );

  @override
  Stream<XelisTableProgressState> createProgressReportStream() {
    double lastPrintedProgress = 0.0;
    return xelis_api.createProgressReportStream().map((report) {
      return report.when(
        tableGeneration: (progress, step, _) {
          final currentStep = XelisTableGenerationStep.fromString(step);
          if ((progress - lastPrintedProgress).abs() >= 0.05 ||
              currentStep != XelisTableGenerationStep.fromString(step) ||
              progress >= 0.99) {
            Logging.instance.d(
              "Xelis Table Generation: $step - ${progress * 100.0}%",
            );
            lastPrintedProgress = progress;
          }

          return XelisTableProgressState(
            tableProgress: progress,
            currentStep: currentStep,
          );
        },
        misc: (_) => const XelisTableProgressState(),
      );
    });
  }

  @override
  bool isAddressValid({required String address}) =>
      x_utils.isAddressValid(strAddress: address);

  @override
  bool validateSeedWord(String word) {
    return x_seed.SearchEngine.init(
      languageIndex: BigInt.from(0),
    ).search(query: word).isNotEmpty;
  }

  @override
  Stream<Event> eventsStream(OpaqueXelisWallet wallet) async* {
    final rawEventStream = wallet.actual.eventsStream();

    await for (final rawData in rawEventStream) {
      final json = jsonDecode(rawData);
      try {
        final eventType = xelis_sdk.WalletEvent.fromStr(
          json['event'] as String,
        );
        switch (eventType) {
          case xelis_sdk.WalletEvent.newTopoHeight:
            yield NewTopoheight(json['data']['topoheight'] as int);
          case xelis_sdk.WalletEvent.newAsset:
            final data = xelis_sdk.AssetData.fromJson(
              json['data'] as Map<String, dynamic>,
            );

            yield NewAsset(data.name, data.decimals, data.maxSupply);
          case xelis_sdk.WalletEvent.newTransaction:
            final tx = xelis_sdk.TransactionEntry.fromJson(
              json['data'] as Map<String, dynamic>,
            );
            yield NewTransaction(
              TransactionEntryWrapper(
                tx,
                entryType: _entryTypeConversion(tx.txEntryType),
                hash: tx.hash,
                timestamp: tx.timestamp,
                topoheight: tx.topoheight,
              ),
            );
          case xelis_sdk.WalletEvent.balanceChanged:
            final data = xelis_sdk.BalanceChangedEvent.fromJson(
              json['data'] as Map<String, dynamic>,
            );
            yield BalanceChanged(data.assetHash, data.balance);
          case xelis_sdk.WalletEvent.rescan:
            yield Rescan(json['data']['start_topoheight'] as int);
          case xelis_sdk.WalletEvent.online:
            yield const Online();
          case xelis_sdk.WalletEvent.offline:
            yield const Offline();
          case xelis_sdk.WalletEvent.historySynced:
            yield HistorySynced(json['data']['topoheight'] as int);
        }
      } catch (e, s) {
        Logging.instance.e(
          "Error processing xelis wallet event: $rawData",
          error: e,
          stackTrace: s,
        );
        continue;
      }
    }
  }

  @override
  Future<void> onlineMode(
    OpaqueXelisWallet wallet, {
    required String daemonAddress,
  }) => wallet.actual.onlineMode(daemonAddress: daemonAddress);

  @override
  Future<void> offlineMode(OpaqueXelisWallet wallet) =>
      wallet.actual.offlineMode();

  @override
  Future<void> updateTables({
    required String precomputedTablesPath,
    required bool l1Low,
  }) => x_wallet.updateTables(
    precomputedTablesPath: precomputedTablesPath,
    l1Low: l1Low,
  );

  @override
  Future<String> getSeed(OpaqueXelisWallet wallet) => wallet.actual.getSeed();

  @override
  Future<OpaqueXelisWallet> createXelisWallet(
    String walletId, {
    required String name,
    required String directory,
    required String password,
    required CryptoCurrencyNetwork network,
    String? seed,
    String? privateKey,
    String? precomputedTablesPath,
    bool? l1Low,
  }) async {
    final wallet = await x_wallet.createXelisWallet(
      name: name,
      directory: directory,
      password: password,
      privateKey: privateKey,
      seed: seed,
      network: network.xelisNetwork,
      precomputedTablesPath: precomputedTablesPath,
      l1Low: l1Low,
    );

    return OpaqueXelisWallet(wallet);
  }

  @override
  Future<OpaqueXelisWallet> openXelisWallet(
    String walletId, {
    required String name,
    required String directory,
    required String password,
    required CryptoCurrencyNetwork network,
    String? precomputedTablesPath,
    bool? l1Low,
  }) async {
    final wallet = await x_wallet.openXelisWallet(
      name: name,
      directory: directory,
      password: password,
      network: network.xelisNetwork,
      precomputedTablesPath: precomputedTablesPath,
      l1Low: l1Low,
    );

    return OpaqueXelisWallet(wallet);
  }

  @override
  String getAddress(OpaqueXelisWallet wallet) => wallet.actual.getAddressStr();

  @override
  Future<String> getDaemonInfo(OpaqueXelisWallet wallet) =>
      wallet.actual.getDaemonInfo();

  @override
  Future<bool> isOnline(OpaqueXelisWallet wallet) => wallet.actual.isOnline();

  @override
  Future<void> rescan(OpaqueXelisWallet wallet, {required BigInt topoheight}) =>
      wallet.actual.rescan(topoheight: topoheight);

  @override
  Future<List<TransactionEntryWrapper>> allHistory(
    OpaqueXelisWallet wallet,
  ) async => (await wallet.actual.allHistory()).map((e) {
    final tx = _checkDecodeJsonStringTxEntry(e);
    return TransactionEntryWrapper(
      tx,
      entryType: _entryTypeConversion(tx.txEntryType),
      hash: tx.hash,
      timestamp: tx.timestamp,
      topoheight: tx.topoheight,
    );
  }).toList();

  @override
  Future<void> broadcastTransaction(
    OpaqueXelisWallet wallet, {
    required String txHash,
  }) => wallet.actual.broadcastTransaction(txHash: txHash);

  @override
  Future<String> createTransfersTransaction(
    OpaqueXelisWallet wallet, {
    required List<WrappedTransfer> transfers,
  }) => wallet.actual.createTransfersTransaction(
    transfers: transfers
        .map(
          (e) => x_wallet.Transfer(
            floatAmount: e.floatAmount,
            strAddress: e.strAddress,
            assetHash: e.assetHash,
            extraData: e.extraData,
          ),
        )
        .toList(),
  );

  @override
  Future<String> estimateFees(
    OpaqueXelisWallet wallet, {
    required List<WrappedTransfer> transfers,
  }) => wallet.actual.estimateFees(
    transfers: transfers
        .map(
          (e) => x_wallet.Transfer(
            floatAmount: e.floatAmount,
            strAddress: e.strAddress,
            assetHash: e.assetHash,
            extraData: e.extraData,
          ),
        )
        .toList(),
  );

  @override
  Future<String> formatCoin(
    OpaqueXelisWallet wallet, {
    required BigInt atomicAmount,
    String? assetHash,
  }) => wallet.actual.formatCoin(
    atomicAmount: atomicAmount,
    assetHash: assetHash,
  );

  @override
  Future<int> getAssetDecimals(
    OpaqueXelisWallet wallet, {
    required String asset,
  }) => wallet.actual.getAssetDecimals(asset: asset);

  @override
  Future<BigInt> getXelisBalanceRaw(OpaqueXelisWallet wallet) =>
      wallet.actual.getXelisBalanceRaw();

  @override
  Future<bool> hasXelisBalance(OpaqueXelisWallet wallet) =>
      wallet.actual.hasXelisBalance();

  @override
  Future<bool> testDaemonConnection(String endPoint, bool useSSL) async {
    try {
      final daemon = xelis_sdk.DaemonClient(
        endPoint: endPoint,
        secureWebSocket: useSSL,
        timeout: 5000,
      );
      daemon.connect();
      final xelis_sdk.GetInfoResult networkInfo = await daemon.getInfo();
      daemon.disconnect();

      Logging.instance.i(
        "Xelis testNodeConnection result: \"${networkInfo.toString()}\"",
      );
      return true;
    } catch (e, s) {
      Logging.instance.w(
        "xelis daemon connection test failed, returning false.",
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }
}

extension _XelisNetworkConversion on CryptoCurrencyNetwork {
  x_network.Network get xelisNetwork {
    switch (this) {
      case CryptoCurrencyNetwork.main:
        return x_network.Network.mainnet;
      case CryptoCurrencyNetwork.test:
        return x_network.Network.testnet;
      default:
        throw ArgumentError('Unsupported network type for Xelis: $this');
    }
  }
}

extension _CryptoCurrencyNetworkConversion on x_network.Network {
  CryptoCurrencyNetwork get cryptoCurrencyNetwork {
    switch (this) {
      case x_network.Network.mainnet:
        return CryptoCurrencyNetwork.main;
      case x_network.Network.testnet:
        return CryptoCurrencyNetwork.test;
      default:
        throw ArgumentError('Unsupported Xelis network type: $this');
    }
  }
}

EntryWrapper _entryTypeConversion(xelis_sdk.TransactionEntryType entryType) {
  if (entryType is xelis_sdk.CoinbaseEntry) {
    return CoinbaseEntryWrapper(reward: entryType.reward);
  } else if (entryType is xelis_sdk.BurnEntry) {
    return BurnEntryWrapper(
      amount: entryType.amount,
      fee: entryType.fee,
      asset: entryType.asset,
    );
  } else if (entryType is xelis_sdk.IncomingEntry) {
    return IncomingEntryWrapper(
      from: entryType.from,
      transfers: entryType.transfers
          .map(
            (e) => (
              amount: e.amount,
              asset: e.asset,
              extraData: e.extraData?.toJson(),
            ),
          )
          .toList(),
    );
  } else if (entryType is xelis_sdk.OutgoingEntry) {
    return OutgoingEntryWrapper(
      nonce: entryType.nonce,
      fee: entryType.fee,
      transfers: entryType.transfers
          .map(
            (e) => (
              destination: e.destination,
              amount: e.amount,
              asset: e.asset,
              extraData: e.extraData?.toJson(),
            ),
          )
          .toList(),
    );
  } else {
    return UnknownEntryWrapper();
  }
}

xelis_sdk.TransactionEntry _checkDecodeJsonStringTxEntry(String jsonString) {
  final json = jsonDecode(jsonString);
  if (json is Map) {
    return xelis_sdk.TransactionEntry.fromJson(json.cast());
  }

  throw Exception("Not a Map on jsonDecode($jsonString)");
}

//END_ON
