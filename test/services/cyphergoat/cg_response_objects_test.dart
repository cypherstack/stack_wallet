import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/exchange/cyphergoat/response_objects/cg_estimate.dart';
import 'package:stackwallet/services/exchange/cyphergoat/response_objects/cg_parse_utils.dart';
import 'package:stackwallet/services/exchange/cyphergoat/response_objects/cg_transaction.dart';

Map<String, dynamic> minimalTxMap() => <String, dynamic>{
  "Coin1": "btc",
  "Coin2": "xmr",
  "Network1": "btc",
  "Network2": "xmr",
  "Address": "bc1qdeposit",
  "DestinationAddress": "44destination",
  "SendAmount": "0.01",
  "EstimateAmount": 1.234,
  "Id": "partner-order-id",
  "CreatedAt": "2026-07-30T12:00:00Z",
};

Map<String, dynamic> minimalEstimatesMap() => <String, dynamic>{
  "Results": [
    {"Exchange": "majesticbank", "Amount": "1.5", "KYCScore": 1},
  ],
  "Min": "0.001",
};

void main() {
  test("CgTransaction parses with only the consumed fields", () {
    final tx = CgTransaction.fromMap(minimalTxMap());

    expect(tx.address, "bc1qdeposit");
    expect(tx.sendAmount, Decimal.parse("0.01"));
    expect(tx.estimateAmount, Decimal.parse("1.234"));
    expect(tx.status, "waiting");
  });

  test("CgTransaction throws a format exception on empty amounts", () {
    for (final key in ["SendAmount", "EstimateAmount"]) {
      expect(
        () => CgTransaction.fromMap(minimalTxMap()..[key] = ""),
        throwsA(isA<CgResponseFormatException>()),
      );
    }
  });

  test("CgEstimatesResponse parses without TradeValue_* or EstimateId", () {
    final response = CgEstimatesResponse.fromMap(minimalEstimatesMap());

    expect(response.results.single.amount, Decimal.parse("1.5"));
    expect(response.estimateId, null);
    expect(
      CgEstimatesResponse.fromMap(minimalEstimatesMap()..["EstimateId"] = 42)
          .estimateId,
      42,
    );
  });

  test("extractErrorMessage", () {
    expect(extractErrorMessage(<String, dynamic>{"error": "foo"}), "foo");
    expect(extractErrorMessage(<String, dynamic>{"message": "foo"}), null);
    expect(extractErrorMessage(<String, dynamic>{"error": ""}), null);
    expect(extractErrorMessage("<html>502 Bad Gateway</html>"), null);
  });
}
