import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/enums/sync_type_enum.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/cryptonote_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/monero_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/wownero_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/salvium_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

import '../support/isar_test_utils.dart';

class _Prefs extends Fake implements Prefs {
  _Prefs(this.syncType);

  @override
  final SyncingType syncType;

  @override
  List<String> get walletIdsSyncOnStartup => ['deleted-wallet', 'live-wallet'];
}

mixin _PollingProbe on Wallet<CryptonoteCurrency> {
  int pings = 0;
  @override
  String get walletId => 'native-exit-fixture';
  @override
  Future<bool> pingCheck() async {
    pings++;
    return false;
  }

  @override
  Future<void> refresh() async {}
}

class _Monero extends MoneroWallet with _PollingProbe {
  _Monero() : super(CryptoCurrencyNetwork.main);
}

class _Wownero extends WowneroWallet with _PollingProbe {
  _Wownero() : super(CryptoCurrencyNetwork.main);
}

class _Salvium extends SalviumWallet with _PollingProbe {
  _Salvium() : super(CryptoCurrencyNetwork.main);
}

class _OwnedTimer implements Timer {
  bool _active = true;
  @override
  bool get isActive => _active;
  @override
  int get tick => 0;
  @override
  void cancel() => _active = false;
}

void main() {
  late Directory directory;
  late Isar isar;
  setUpAll(() async {
    await initializeTestIsar();
    directory = await Directory.systemTemp.createTemp('native-exit-');
    isar = await Isar.open(
      [WalletInfoSchema],
      directory: directory.path,
      name: 'native-exit',
      inspector: false,
    );
    await MainDB.instance.initMainDB(mock: isar);
    await isar.writeTxn(
      () => isar.walletInfo.put(
        WalletInfo(
          walletId: 'live-wallet',
          name: 'Live selected wallet',
          mainAddressType: AddressType.p2wpkh,
          coinName: 'bitcoin',
        ),
      ),
    );
  });
  tearDownAll(() async {
    await isar.close();
    await directory.delete(recursive: true);
  });

  for (final entry in <String, _PollingProbe Function()>{
    "Monero": _Monero.new,
    "Wownero": _Wownero.new,
    "Salvium": _Salvium.new,
  }.entries) {
    test("native exit stops base polling ${entry.key}", () async {
      final periodic = <_OwnedTimer>[];
      await runZoned(
        () async {
          final wallet = entry.value()
            ..doNotFireRefreshEvents = true
            ..prefs = Prefs.instance;
          try {
            wallet.shouldAutoSync = true;
            expect(periodic.where((timer) => timer.isActive), isNotEmpty);
            await wallet.exit();
            expect(wallet.shouldAutoSync, isFalse);
            expect(periodic.where((timer) => timer.isActive), isEmpty);
          } finally {
            wallet.shouldAutoSync = false;
          }
        },
        zoneSpecification: ZoneSpecification(
          // Native constructors defer a DB watcher by two seconds. Keep that
          // unrelated initialization out of this polling-ownership test.
          createTimer: (self, parent, zone, duration, callback) =>
              _OwnedTimer(),
          createPeriodicTimer: (self, parent, zone, duration, callback) {
            final timer = _OwnedTimer();
            periodic.add(timer);
            return timer;
          },
        ),
      );
    });

    for (final syncType in [
      SyncingType.currentWalletOnly,
      SyncingType.selectedWalletsAtStartup,
    ]) {
      test(
        '${entry.key} exits with a deleted ${syncType.name} wallet',
        () async {
          await runZoned(
            () async {
              final wallet = entry.value()
                ..mainDB = MainDB.instance
                ..prefs = _Prefs(syncType);
              await wallet.exit();
              expect(wallet.shouldAutoSync, isFalse);
            },
            zoneSpecification: ZoneSpecification(
              // Prevent the unrelated deferred native DB watcher from starting.
              createTimer: (self, parent, zone, duration, callback) =>
                  _OwnedTimer(),
            ),
          );
        },
      );
    }
  }
}
