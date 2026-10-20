import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';

void main() {
  group("Trade terminal status", () {
    test("recognizes provider terminal statuses without case sensitivity", () {
      for (final status in [
        "Finished",
        "completed",
        "SUCCESS",
        "Failed",
        "error",
        "Refunded",
        "overdue",
        "Expired",
        "Closed",
        "cancelled",
        "CANCELED",
        "Not found",
        " finished ",
      ]) {
        expect(Trade.isTerminalStatusValue(status), isTrue, reason: status);
      }
    });

    test("keeps active and refund-in-progress statuses non-terminal", () {
      for (final status in [
        "new",
        "waiting",
        "confirming",
        "exchanging",
        "sending",
        "refund",
        "unknown",
      ]) {
        expect(Trade.isTerminalStatusValue(status), isFalse, reason: status);
      }
    });

    test("exposes terminal status on a trade", () {
      expect(_tradeWithStatus(" Finished ").isTerminalStatus, isTrue);
      expect(_tradeWithStatus("refund").isTerminalStatus, isFalse);
    });
  });
}

Trade _tradeWithStatus(String status) => Trade(
  uuid: "uuid",
  tradeId: "tradeId",
  rateType: "fixed",
  direction: "direct",
  timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  payInCurrency: "btc",
  payInAmount: "1",
  payInAddress: "payInAddress",
  payInNetwork: "btc",
  payInExtraId: "",
  payInTxid: "",
  payOutCurrency: "xmr",
  payOutAmount: "1",
  payOutAddress: "payOutAddress",
  payOutNetwork: "xmr",
  payOutExtraId: "",
  payOutTxid: "",
  refundAddress: "refundAddress",
  refundExtraId: "",
  status: status,
  exchangeName: "exchange",
);
