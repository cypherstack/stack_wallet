import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/utilities/enums/sync_type_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/xelis_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/wl_gen/interfaces/lib_xelis_interface.dart';

class FakeNative extends Fake implements LibXelisInterface {
  @override
  String get xelisAsset => 'xel';
  @override
  bool isAddressValid({
    required String address,
    required CryptoCurrencyNetwork network,
  }) => true;
  final discarded = <XelisPreparedTransaction>[];
  final broadcast = <XelisPreparedTransaction>[];
  XelisBroadcastOutcome outcome = const XelisBroadcastOutcome(
    XelisBroadcastDisposition.submitted,
  );
  Completer<XelisPreparedTransaction>? pendingPreparation;
  Completer<XelisBroadcastOutcome>? pendingBroadcast;
  int preparedCount = 0;
  bool usedMax = false;

  XelisPreparedTransaction makePrepared(BigInt amount) =>
      XelisPreparedTransaction(
        handle: Object(),
        hash: 'hash-${++preparedCount}',
        feeAtomic: BigInt.from(7),
        transfers: [
          XelisPreparedTransfer(
            destination: 'base-destination',
            amountAtomic: amount,
            asset: xelisAsset,
            hasExtraData: true,
          ),
        ],
      );
  @override
  Future<XelisPreparedTransaction> prepareTransfers(
    OpaqueXelisWallet wallet, {
    required List<XelisTransfer> transfers,
  }) async =>
      pendingPreparation?.future ??
      Future.value(makePrepared(transfers.single.amountAtomic));
  @override
  Future<XelisPreparedTransaction> prepareTransferAll(
    OpaqueXelisWallet wallet, {
    required String destination,
  }) async {
    usedMax = true;
    return makePrepared(BigInt.from(93));
  }

  @override
  Future<void> discardPreparedTransaction(
    OpaqueXelisWallet wallet, {
    required XelisPreparedTransaction transaction,
  }) async => discarded.add(transaction);
  @override
  Future<XelisBroadcastOutcome> broadcastTransaction(
    OpaqueXelisWallet wallet, {
    required XelisPreparedTransaction transaction,
  }) async {
    broadcast.add(transaction);
    return pendingBroadcast?.future ?? Future.value(outcome);
  }
}

class TestWallet extends XelisWallet {
  TestWallet(FakeNative native)
    : super(CryptoCurrencyNetwork.test, native: native) {
    wallet = const OpaqueXelisWallet(Object());
  }
  @override
  Future<void> refresh({int? topoheight}) async {}
}

class SessionPrefs extends Fake implements Prefs {
  @override
  SyncingType get syncType => SyncingType.allWalletsOnStartup;
}

class ConfirmationWallets extends Fake implements Wallets {
  ConfirmationWallets(this.wallet);
  final Wallet wallet;
  @override
  Wallet getWallet(String walletId) => wallet;
}

class ConfirmationPrefs extends ChangeNotifier implements Prefs {
  @override
  bool get externalCalls => false;
  @override
  String get currency => 'USD';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemorySecrets extends Fake implements SecureStorageInterface {
  final values = <String, String>{'xelis_wants_full_tables': 'false'};
  String? failingKey;
  String? failingDeleteKey;
  Future<void> Function(String)? beforeDelete;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final key = invocation.namedArguments[#key] as String;
    switch (invocation.memberName) {
      case #delete:
        return () async {
          await beforeDelete?.call(key);
          if (key == failingDeleteKey) {
            throw StateError('fixture delete failure');
          }
          values.remove(key);
        }();
      case #read:
        return Future<String?>.value(values[key]);
      case #write:
        if (key == failingKey) {
          return Future<void>.error(StateError('fixture write failure'));
        }
        values[key] = invocation.namedArguments[#value] as String;
        return Future<void>.value();
      default:
        return super.noSuchMethod(invocation);
    }
  }
}
