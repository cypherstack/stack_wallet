import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  test('a currency can require an explicitly configured node', () {
    final currency = _ExplicitNodeCurrency();

    expect(currency.defaultNodeOrNull(isPrimary: true), isNull);
    expect(
      () => currency.defaultNode(isPrimary: true),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          contains('explicitly configured node'),
        ),
      ),
    );
  });
}

class _ExplicitNodeCurrency extends Bitcoin {
  _ExplicitNodeCurrency() : super(CryptoCurrencyNetwork.main);

  @override
  NodeModel? defaultNodeOrNull({required bool isPrimary}) => null;

  @override
  NodeModel defaultNode({required bool isPrimary}) => throw UnsupportedError(
    'This currency requires an explicitly configured node',
  );
}
