import 'crypto_currency.dart';

typedef OptInCoinFactory = CryptoCurrency Function();

/// Resolves feature-gated currencies without exposing them in ordinary builds.
///
/// [declaration] is a comma-separated list of names from the strict
/// [factories] registry supplied by the application configuration.
List<CryptoCurrency> resolveOptInCoins(
  String declaration, {
  required Map<String, OptInCoinFactory> factories,
}) {
  final names = declaration
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty);
  final seen = <String>{};
  final result = <CryptoCurrency>[];
  for (final name in names) {
    final factory = factories[name];
    if (factory == null) {
      throw ArgumentError.value(
        name,
        'STACK_EXTRA_COINS',
        'unknown opt-in coin; supported values are '
            '${factories.keys.join(', ')}',
      );
    }
    if (!seen.add(name)) {
      throw StateError('Opt-in coin "$name" was enabled more than once');
    }
    result.add(factory());
  }
  return List.unmodifiable(result);
}
