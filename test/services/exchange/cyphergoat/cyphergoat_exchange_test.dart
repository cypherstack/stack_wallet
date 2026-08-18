import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/services/exchange/cyphergoat/cyphergoat_exchange.dart';

void main() {
  test("does not advertise extra ID support", () {
    expect(CypherGoatExchange.instance.supportsExtraId, isFalse);
  });

  for (final values in [
    (destination: "12345", refund: ""),
    (destination: null, refund: "refund memo"),
  ]) {
    test("rejects an unsupported "
        "${values.destination == null ? "refund" : "destination"} memo "
        "before a network call", () async {
      final response = await CypherGoatExchange.instance.createTrade(
        from: "btc",
        to: "xrp",
        fromNetwork: "btc",
        toNetwork: "xrp",
        fixedRate: false,
        amount: Decimal.one,
        addressTo: "destination",
        extraId: values.destination,
        addressRefund: "",
        refundExtraId: values.refund,
        estimate: Estimate(
          estimatedAmount: Decimal.one,
          fixedRate: false,
          reversed: false,
          exchangeProvider: "provider",
        ),
        reversed: false,
      );

      expect(response.value, isNull);
      expect(response.exception.toString(), contains("does not support"));
    });
  }
}
