import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/format.dart';

void main() {
  group("extractDateFrom", () {
    test("1614578400", () {
      expect(Format.extractDateFrom(1614578400, localized: false),
          "1 Mar 2021, 6:00");
    });

    test("1641589563", () {
      expect(Format.extractDateFrom(1641589563, localized: false),
          "7 Jan 2022, 21:06");
    });
  });

  group("formatDate", () {
    test("formatDate", () {
      final date = DateTime(2020);
      expect(Format.formatDate(date), "01/01/20");
    });
    test("formatDate", () {
      final date = DateTime(2021, 2, 6, 23, 58);
      expect(Format.formatDate(date), "02/06/21");
    });
    test("formatDate", () {
      final date = DateTime(2021, 13);
      expect(Format.formatDate(date), "01/01/22");
    });
    test("formatDate", () {
      final date = DateTime(2021, 2, 35);
      expect(Format.formatDate(date), "03/07/21");
    });
  });
}
