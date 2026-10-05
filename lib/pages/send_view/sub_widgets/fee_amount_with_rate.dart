import 'package:flutter/material.dart';

import '../../../utilities/util.dart';

/// Fee rate in sat/vB to one decimal, or null when [vSize] is unknown or non
/// positive (fixed fee coins, spark mints, account based coins).
///
/// [locale] picks the decimal separator so the rate matches the amount
/// formatted next to it.
String? formatFeeRate({
  required int feeSats,
  required int? vSize,
  String? locale,
}) {
  if (vSize == null || vSize <= 0) {
    return null;
  }

  final rate = (feeSats / vSize).toStringAsFixed(1);
  if (locale == null) {
    return rate;
  }

  final separator = Util.getSymbolsFor(locale: locale)?.DECIMAL_SEP ?? '.';
  return separator == '.' ? rate : rate.replaceFirst('.', separator);
}

class FeeAmountWithRate extends StatelessWidget {
  const FeeAmountWithRate({
    super.key,
    required this.formattedAmount,
    required this.feeSats,
    required this.vSize,
    required this.amountStyle,
    required this.rateStyle,
    this.alignment = WrapAlignment.start,
    this.locale,
  });

  final String formattedAmount;
  final int feeSats;
  final int? vSize;
  final TextStyle amountStyle;
  final TextStyle rateStyle;
  final WrapAlignment alignment;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final rate = formatFeeRate(feeSats: feeSats, vSize: vSize, locale: locale);

    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SelectableText(
          formattedAmount,
          style: amountStyle,
          textAlign: TextAlign.right,
        ),
        if (rate != null)
          Text(
            ' (~$rate sat/vB)',
            style: rateStyle,
            textAlign: TextAlign.right,
          ),
      ],
    );
  }
}
