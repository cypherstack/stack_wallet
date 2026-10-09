import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/providers/ui/preview_tx_button_state_provider.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  test(
    'alias eligibility requires an amount and respects unsupported data',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final coin = Monero(CryptoCurrencyNetwork.main);
      final enabled = pPreviewTxButtonEnabledForDestination((
        coin: coin,
        isAlias: true,
      ));
      final subscription = container.listen(enabled, (_, _) {});
      addTearDown(subscription.close);
      expect(container.read(enabled), isFalse);
      container.read(pSendAmount.notifier).state = Amount(
        rawValue: BigInt.one,
        fractionDigits: 12,
      );
      expect(container.read(enabled), isTrue);
      expect(container.read(pValidSendToAddress), isFalse);
      container.read(pOpReturnData.notifier).state = '00';
      expect(container.read(enabled), isFalse);
      container.read(pOpReturnData.notifier).state = null;
      container.read(pSendAmount.notifier).state = Amount.zero;
      expect(container.read(enabled), isFalse);
    },
  );

  test('alias state is local and never enables another wallet or coin', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final monero = Monero(CryptoCurrencyNetwork.main);
    final bitcoin = Bitcoin(CryptoCurrencyNetwork.main);
    final alias = pPreviewTxButtonEnabledForDestination((
      coin: monero,
      isAlias: true,
    ));
    final literal = pPreviewTxButtonEnabledForDestination((
      coin: monero,
      isAlias: false,
    ));
    final other = pPreviewTxButtonEnabledForDestination((
      coin: bitcoin,
      isAlias: true,
    ));
    final subscriptions = [
      alias,
      literal,
      other,
    ].map((p) => container.listen(p, (_, _) {})).toList();
    addTearDown(() {
      for (final s in subscriptions) {
        s.close();
      }
    });
    container.read(pSendAmount.notifier).state = Amount(
      rawValue: BigInt.one,
      fractionDigits: 12,
    );
    expect(container.read(alias), isTrue);
    expect(container.read(literal), isFalse);
    expect(container.read(other), isFalse);
    container.read(pValidSendToAddress.notifier).state = true;
    expect(container.read(literal), isTrue);
    expect(container.read(other), isTrue);
  });
}
