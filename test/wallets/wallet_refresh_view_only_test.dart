import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/view_only_option_interface.dart';

class _UnavailableWallet extends Wallet<Bitcoin>
    with ViewOnlyOptionInterface<Bitcoin> {
  _UnavailableWallet() : super(Bitcoin(CryptoCurrencyNetwork.main)) {
    doNotFireRefreshEvents = true;
  }

  @override
  String get walletId => 'unavailable-view-only-test';

  @override
  bool get isViewOnly => throw StateError('Wallet row is no longer available');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'failure reading view-only state completes and releases refresh',
    () async {
      final wallet = _UnavailableWallet();
      await wallet.refresh().timeout(const Duration(seconds: 1));
      expect(wallet.refreshMutex.isLocked, isFalse);
      // A failed attempt must not leave a permanently pending shared future.
      await wallet.refresh().timeout(const Duration(seconds: 1));
      expect(wallet.refreshMutex.isLocked, isFalse);
    },
  );
}
