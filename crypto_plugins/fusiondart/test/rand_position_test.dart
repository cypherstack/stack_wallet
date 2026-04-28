import 'package:fusiondart/fusiondart.dart';
import 'package:fusiondart/src/extensions/on_string.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test("rand position", () {
    final seed =
        "9b9c247f72b7a3fd05f1bb17af9a4661835ed1604bdd6ca395495590d0077659"
            .toUint8ListFromHex;

    final N = 10;

    final List<int> results = [];

    for (int i = 0; i < 6; i++) {
      results.add(Utilities.randPosition(seed, N, i));
    }

    // TODO: unsure about duplicates?
    expect(results.toString(), "[9, 0, 7, 7, 6, 8]");
  });
}
