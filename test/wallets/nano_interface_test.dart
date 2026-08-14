import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/nano_interface.dart';

void main() {
  test('Nano send state uses the live account balance', () {
    final state = parseNanoSendState({
      'frontier': 'frontier',
      'representative': 'representative',
      'balance': '15',
    }, BigInt.from(3));

    expect(state.frontier, 'frontier');
    expect(state.representative, 'representative');
    expect(state.balanceAfterSend, BigInt.from(12));
    expect(
      () => parseNanoSendState({'balance': '2'}, BigInt.from(3)),
      throwsException,
    );
  });
}
