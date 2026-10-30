import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/replacement_fee.dart';

void main() {
  BigInt required(int vSize, int oldFee, int newRate) => requiredReplacementFee(
    vSize: vSize,
    oldFee: BigInt.from(oldFee),
    newRate: newRate,
  );

  test("a replacement pays the new rate, or the old fee plus the relay "
      "increment, whichever is more", () {
    // Old fee 10 sat/vB: a bump to 10 sat/vB must still add 1 sat/vB.
    expect(required(200, 2000, 10), BigInt.from(2200));
    expect(required(200, 2000, 15), BigInt.from(3000));
    expect(required(200, 1800, 10), BigInt.from(2000));
  });

  test("a fee short of the requirement is refused", () {
    void require(int fee) => requireReplacementFee(
      BigInt.from(fee),
      vSize: 200,
      oldFee: BigInt.from(2000),
      newRate: 10,
    );
    expect(() => require(2199), throwsException);
    expect(() => require(2200), returnsNormally);
  });

  // Builds pay the fee asked, less [shortBy], at the next size in [vSizes]
  // (the last size repeats). Returns the accepted build and the fees asked.
  Future<({String built, List<BigInt> fees})> settle({
    required int oldVSize,
    required int oldFee,
    required int newRate,
    required List<int> vSizes,
    int shortBy = 0,
  }) async {
    final fees = <BigInt>[];
    final built = await settleReplacementFee(
      oldVSize: oldVSize,
      oldFee: BigInt.from(oldFee),
      newRate: newRate,
      build: (newFee) async {
        fees.add(newFee);
        final i = fees.length - 1;
        return (
          fee: newFee - BigInt.from(shortBy),
          vSize: vSizes[i < vSizes.length ? i : vSizes.length - 1],
          built: "build ${fees.length}",
        );
      },
    );
    return (built: built, fees: fees);
  }

  test("settles on the first build when it already pays enough", () async {
    final r = await settle(
      oldVSize: 200,
      oldFee: 1000,
      newRate: 10,
      vSizes: [200],
    );
    expect(r.fees, [BigInt.from(2000)]);
    expect(r.built, "build 1");
  });

  test(
    "raises to the relay floor when the new rate alone falls short",
    () async {
      // Old rate 10 sat/vB bumped to 10: the first build pays the old fee, so
      // the second adds the relay increment.
      final r = await settle(
        oldVSize: 200,
        oldFee: 2000,
        newRate: 10,
        vSizes: [200],
      );
      expect(r.fees, [BigInt.from(2000), BigInt.from(2200)]);
      expect(r.built, "build 2");
    },
  );

  test("rebuilds at the new size when the replacement grows", () async {
    // An added input makes the replacement 300 vB; it must pay the rate on
    // that size.
    final r = await settle(
      oldVSize: 200,
      oldFee: 1000,
      newRate: 10,
      vSizes: [300],
    );
    expect(r.fees, [BigInt.from(2000), BigInt.from(3000)]);
    expect(r.built, "build 2");
  });

  test("gives up after three builds that keep falling short", () async {
    final fees = <BigInt>[];
    await expectLater(
      settleReplacementFee(
        oldVSize: 200,
        oldFee: BigInt.from(1000),
        newRate: 10,
        build: (newFee) async {
          fees.add(newFee);
          return (fee: newFee - BigInt.one, vSize: 200, built: fees.length);
        },
      ),
      throwsException,
    );
    expect(fees.length, 3);
  });
}
