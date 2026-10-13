import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/pages/coin_control/coin_control_rules.dart';

void main() {
  test("uses one filter contract for flat and grouped output lists", () {
    expect(
      coinControlFilter(isSearching: true, showBlocked: false),
      CCFilter.all,
    );
    expect(
      coinControlFilter(isSearching: false, showBlocked: false),
      CCFilter.available,
    );
    expect(
      coinControlFilter(isSearching: false, showBlocked: true),
      CCFilter.frozen,
    );
  });

  test("use mode excludes blocked and unconfirmed outputs", () {
    expect(
      canSelectCoinControlOutput(
        isManageMode: false,
        isBlocked: false,
        isConfirmed: true,
      ),
      isTrue,
    );
    expect(
      canSelectCoinControlOutput(
        isManageMode: false,
        isBlocked: true,
        isConfirmed: true,
      ),
      isFalse,
    );
    expect(
      canSelectCoinControlOutput(
        isManageMode: false,
        isBlocked: false,
        isConfirmed: false,
      ),
      isFalse,
    );
    expect(
      canSelectCoinControlOutput(
        isManageMode: true,
        isBlocked: true,
        isConfirmed: false,
      ),
      isTrue,
    );
  });
}
