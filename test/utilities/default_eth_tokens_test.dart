import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/default_eth_tokens.dart';

void main() {
  test('Campfire Ethereum defaults are allowlisted', () {
    expect(
      DefaultTokens.forApp('Campfire').map((e) => (e.symbol, e.address)),
      unorderedEquals([
        ('USDC', '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'),
        ('USDT', '0xdac17f958d2ee523a2206206994597c13d831ec7'),
        ('rsFIRO', '0x2744ea5ac9b11cb5e3cd63d3a88e858336aeddc2'),
      ]),
    );
  });
}
