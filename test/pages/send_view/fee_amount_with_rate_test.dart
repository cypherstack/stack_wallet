import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/fee_amount_with_rate.dart';

void main() {
  test('formats positive fee rates to one decimal place', () {
    expect(formatFeeRate(feeRaw: BigInt.from(126), vSize: 100), '~1.3');
    expect(formatFeeRate(feeRaw: BigInt.from(1000), vSize: 3), '~333.3');
  });

  test('preserves precision for values beyond double range', () {
    final fee = BigInt.parse('900719925474099312345678901234567890');
    expect(formatFeeRate(feeRaw: fee, vSize: 3), '~300239975158033104115226300411522630.0');
  });

  test('omits fee rates without a positive virtual size', () {
    expect(formatFeeRate(feeRaw: BigInt.from(126), vSize: null), isNull);
    expect(formatFeeRate(feeRaw: BigInt.from(126), vSize: 0), isNull);
    expect(formatFeeRate(feeRaw: BigInt.from(126), vSize: -1), isNull);
    expect(formatFeeRate(feeRaw: BigInt.from(-126), vSize: 100), isNull);
  });

  test('uses the locale decimal separator', () {
    expect(formatFeeRate(feeRaw: BigInt.from(126), vSize: 100), '~1.3');
    expect(formatFeeRate(feeRaw: BigInt.from(126), vSize: 100, locale: 'en_US'), '~1.3');
    expect(formatFeeRate(feeRaw: BigInt.from(126), vSize: 100, locale: 'de_DE'), '~1,3');
    expect(formatFeeRate(feeRaw: BigInt.from(126), vSize: 100, locale: 'fr'), '~1,3');
  });

  testWidgets('renders the rate in the same locale as the amount', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FeeAmountWithRate(
            formattedAmount: '0,00000126 BTC',
            feeRaw: BigInt.from(126),
            vSize: 100,
            locale: 'de_DE',
            amountStyle: TextStyle(fontSize: 12),
            rateStyle: TextStyle(fontSize: 12),
          ),
        ),
      ),
    );

    expect(find.text(' (~1,3 sat/vB)'), findsOneWidget);
  });

  testWidgets('wraps a long amount and rate at large text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(240, 600),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SizedBox(
              width: 240,
              child: Row(
                children: [
                  Expanded(child: Text('Transaction fee')),
                  SizedBox(width: 12),
                  Expanded(
                    child: FeeAmountWithRate(
                      formattedAmount: '1234567890.12345678 BTC',
                      feeRaw: BigInt.from(999999999),
                      vSize: 1,
                      amountStyle: TextStyle(fontSize: 12),
                      rateStyle: TextStyle(fontSize: 12),
                      alignment: WrapAlignment.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(' (~999999999.0 sat/vB)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
