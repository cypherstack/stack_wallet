import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/desktop_all_trades_view.dart';

void main() {
  test("one transaction load opens one trade-details dialog", () async {
    var loads = 0;
    var presentations = 0;
    String? presented;

    await loadAndPresentDesktopTradeDetails(
      load: () async {
        loads++;
        return "transaction";
      },
      present: (value) {
        presentations++;
        presented = value;
      },
    );

    expect(loads, 1);
    expect(presentations, 1);
    expect(presented, "transaction");
  });
}
