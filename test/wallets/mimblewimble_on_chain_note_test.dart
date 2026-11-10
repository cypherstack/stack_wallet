import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wl_gen/interfaces/mimblewimble_transaction.dart';

enum _Type { sent }

MimblewimbleTransaction _tx(List<String?>? messages) => MimblewimbleTransaction(
  parentKeyId: '0200000000000000000000000000000000',
  id: 1,
  txType: _Type.sent,
  creationTs: '2026-11-10T00:00:00Z',
  confirmationTs: '',
  confirmed: false,
  numInputs: 1,
  numOutputs: 1,
  amountCredited: '0',
  amountDebited: '1',
  messages: messages
      ?.map((m) => MimblewimbleMessage(id: '0', publicKey: 'pk', message: m))
      .toList(),
);

void main() {
  test('skips the other party\'s empty entry on a send', () {
    // The plugins turn a missing message into the string "null".
    expect(_tx(['null', 'thanks for lunch']).onChainNote, 'thanks for lunch');
    expect(_tx([null, 'thanks for lunch']).onChainNote, 'thanks for lunch');
  });

  test('is null when no participant left a message', () {
    expect(_tx(['null', 'null']).onChainNote, isNull);
    expect(_tx(['', null]).onChainNote, isNull);
    expect(_tx([]).onChainNote, isNull);
    expect(_tx(null).onChainNote, isNull);
  });

  test('keeps a real first message', () {
    expect(_tx(['first', 'second']).onChainNote, 'first');
  });
}
