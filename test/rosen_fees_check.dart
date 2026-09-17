// Run: dart --enable-asserts test/rosen_fees_check.dart
import '../lib/services/exchange/rosen/rosen_fees.dart';

void main() {
  // Actual FIRO fee box 346493beb1be3f439c64f71f98c07f7c6707c1f02e8f9505c2366e1f57c67655.
  final registers = <String, dynamic>{
    'R4': {
      'serializedValue': '1a060762696e616e63650d626974636f696e2d72756e65730763617264616e6f046572676f08657468657265756d046669726f',
    },
    'R5': {
      'serializedValue': '1c02069eee8d70c4d175ce869a0db2d8e201f8abcf1894bfa60106d6f2fd72baf575fc9aa20dd687e401a08ddd18d4cfa701',
    },
    'R6': {
      'serializedValue': '1d0206cedfebcf0acedfebcf0acedfebcf0acedfebcf0acedfebcf0acedfebcf0a06a28398b508a28398b508a28398b508a28398b508a28398b508a28398b508',
    },
    'R7': {
      'serializedValue': '1d0206b4faee01a4f1dc4ae8e2f976dc9db807ac80bb07c88b3d06d2e9cb01dae9e35fe8f6945fe0e1ce05e2a5b101c88b3d',
    },
    'R8': {
      'serializedValue': '0c1d020602fc826280a8d6b90702fc826280a8d6b90702fc826280a8d6b90702fc826280a8d6b90702fc826280a8d6b90702fc826280a8d6b9070602a2f80c8084af5f02a2f80c8084af5f02a2f80c8084af5f02a2f80c8084af5f02a2f80c8084af5f02a2f80c8084af5f',
    },
    'R9': {'serializedValue': '1d020664646464646406646464646464'},
  };
  final amount = BigInt.from(10000000000);
  RosenQuote quote({bool fromFiro = true, int height = 1378335}) =>
      RosenQuote.fromRegisters(
        registers,
        fromFiro: fromFiro,
        height: height,
        amount: amount,
      );
  final forward = quote();
  assert(forward.hasFees(forward.bridgeFee, forward.networkFee));
  for (final fees in [
    (forward.bridgeFee + BigInt.one, forward.networkFee),
    (forward.bridgeFee - BigInt.one, forward.networkFee),
    (forward.bridgeFee, forward.networkFee + BigInt.one),
    (forward.bridgeFee, forward.networkFee - BigInt.one),
    (forward.bridgeFee + BigInt.one, forward.networkFee - BigInt.one),
  ]) {
    assert(!forward.hasFees(fees.$1, fees.$2));
    assert(
      RosenQuote(
            bridgeFee: fees.$1,
            networkFee: fees.$2,
            minimum: forward.minimum,
            receiveAmount: amount - fees.$1 - fees.$2,
          ).fingerprint !=
          forward.fingerprint,
    );
  }
  assert(
    RosenQuote(
          bridgeFee: forward.bridgeFee,
          networkFee: forward.networkFee,
          minimum: forward.minimum,
          receiveAmount: forward.receiveAmount + BigInt.one,
        ).fingerprint !=
        forward.fingerprint,
  );
  assert(forward.bridgeFee == BigInt.from(1129513169));
  assert(forward.networkFee == BigInt.from(1452401));
  assert(forward.minimum == BigInt.from(1130965571));
  assert(forward.receiveAmount == BigInt.from(8869034430));
  assert(
    quote(fromFiro: false, height: 25992101).networkFee == BigInt.from(500452),
  );
  assert(quote(height: 1373162).bridgeFee == BigInt.from(1425897447));
  assert(quote(height: 1373163).bridgeFee == BigInt.from(1129513169));
  mustReject(() => quote(height: 1363914));
  final large = RosenQuote.fromRegisters(
    registers,
    fromFiro: true,
    height: 1378335,
    amount: BigInt.from(1000000000000),
  );
  assert(large.bridgeFee == BigInt.from(5000000000));
  registers['R9'] = {'serializedValue': '1d02066464646464640664646464646400'};
  mustReject(quote);

  final highRatio = <String, dynamic>{
    'R4': {'serializedValue': '1a02046669726f08657468657265756d'},
    'R5': {'serializedValue': '1c01020000'},
    'R6': {'serializedValue': '1d01020000'},
    'R7': {'serializedValue': '1d0102c801c801'},
    'R8': {'serializedValue': '0c1d0102020202020202'},
    'R9': {'serializedValue': '1d01029e9c019e9c01'},
  };
  RosenQuote edge(BigInt value) => RosenQuote.fromRegisters(
    highRatio,
    fromFiro: true,
    height: 1,
    amount: value,
  );
  final minimum = edge(BigInt.zero).minimum;
  assert(minimum == BigInt.from(1000001));
  assert(edge(minimum).receiveAmount == BigInt.one);
  assert(edge(minimum - BigInt.one).receiveAmount == BigInt.zero);
  highRatio['R6'] = {
    'serializedValue': '1d0102feffffffffffffffff01feffffffffffffffff01',
  };
  assert(edge(BigInt.zero).bridgeFee == BigInt.parse('9223372036854775807'));
  highRatio['R6'] = {
    'serializedValue': '1d0102ffffffffffffffffff02ffffffffffffffffff02',
  };
  mustReject(() => edge(BigInt.zero));
  print('Rosen fee checks passed');
}

void mustReject(Object? Function() run) {
  try {
    run();
  } on FormatException {
    return;
  }
  throw StateError('Invalid fee configuration was accepted');
}
