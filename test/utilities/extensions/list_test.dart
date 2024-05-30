import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';

void main() {
  test("Empty list", () {
    final List<int> list = [];
    expect(
      list.chunked(chunkSize: 3).isEmpty,
      true,
    );
  });

  test("No remainder", () {
    final List<int> list = [0, 1, 2, 3, 4, 5, 6, 7, 8];
    final chunked = list.chunked(chunkSize: 3);
    expect(chunked.length == 3, true);
    expect(
      chunked.map((e) => e.length == 3).reduce((v, e) => v && e),
      true,
    );
  });

  test("Some remainder", () {
    final List<int> list = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    final chunked = list.chunked(chunkSize: 3);
    expect(chunked.length == 4, true);
    expect(chunked.last.length == 1, true);
    expect(
      chunked.map((e) => e.length == 3).reduce((v, e) => v && e),
      false,
    );
  });
}
