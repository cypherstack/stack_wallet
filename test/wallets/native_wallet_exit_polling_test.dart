import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/cryptonote_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/monero_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/wownero_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/salvium_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

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
  }
}
