import 'package:stackwallet/services/exchange/rosen/rosen_fees.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rosen_test_utils.dart';

void main() {
  test('decodes fee schedules and rejects stale or malformed registers', () {
    final registers = {...rosenFeeRegisters};
    final amount = BigInt.from(10000000000);
    RosenQuote quote({bool fromFiro = true, int height = 1378335}) =>
        RosenQuote.fromRegisters(
          registers,
          fromFiro: fromFiro,
          height: height,
          amount: amount,
        );
    final forward = quote();
    expect(forward.hasFees(forward.bridgeFee, forward.networkFee), isTrue);
    for (final fees in [
      (forward.bridgeFee + BigInt.one, forward.networkFee),
      (forward.bridgeFee - BigInt.one, forward.networkFee),
      (forward.bridgeFee, forward.networkFee + BigInt.one),
      (forward.bridgeFee, forward.networkFee - BigInt.one),
      (forward.bridgeFee + BigInt.one, forward.networkFee - BigInt.one),
    ]) {
      expect(forward.hasFees(fees.$1, fees.$2), isFalse);
      expect(
        RosenQuote(
          bridgeFee: fees.$1,
          networkFee: fees.$2,
          minimum: forward.minimum,
          receiveAmount: amount - fees.$1 - fees.$2,
        ).fingerprint,
        isNot(forward.fingerprint),
      );
    }
    expect(
      RosenQuote(
        bridgeFee: forward.bridgeFee,
        networkFee: forward.networkFee,
        minimum: forward.minimum,
        receiveAmount: forward.receiveAmount + BigInt.one,
      ).fingerprint,
      isNot(forward.fingerprint),
    );
    expect(forward.bridgeFee, BigInt.from(1129513169));
    expect(forward.networkFee, BigInt.from(1452401));
    expect(forward.minimum, BigInt.from(1130965571));
    expect(forward.receiveAmount, BigInt.from(8869034430));
    expect(
      quote(fromFiro: false, height: 25992101).networkFee,
      BigInt.from(500452),
    );
    expect(quote(height: 1373162).bridgeFee, BigInt.from(1425897447));
    expect(quote(height: 1373163).bridgeFee, BigInt.from(1129513169));
    expect(() => quote(height: 1363914), throwsFormatException);
    final large = RosenQuote.fromRegisters(
      registers,
      fromFiro: true,
      height: 1378335,
      amount: BigInt.from(1000000000000),
    );
    expect(large.bridgeFee, BigInt.from(5000000000));
    registers['R9'] = {'serializedValue': '1d02066464646464640664646464646400'};
    expect(quote, throwsFormatException);
  });

  test('preserves integer fee boundaries and rejects uint64 overflow', () {
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
    expect(minimum, BigInt.from(1000001));
    expect(edge(minimum).receiveAmount, BigInt.one);
    expect(edge(minimum - BigInt.one).receiveAmount, BigInt.zero);
    highRatio['R6'] = {
      'serializedValue': '1d0102feffffffffffffffff01feffffffffffffffff01',
    };
    expect(edge(BigInt.zero).bridgeFee, BigInt.parse('9223372036854775807'));
    highRatio['R6'] = {
      'serializedValue': '1d0102ffffffffffffffffff02ffffffffffffffffff02',
    };
    expect(() => edge(BigInt.zero), throwsFormatException);
  });
}
