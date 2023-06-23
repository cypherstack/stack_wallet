import 'dart:math';

import 'package:flutter/services.dart';
import 'package:intl/number_symbols.dart';
import 'package:intl/number_symbols_data.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';

class AmountInputFormatter extends TextInputFormatter {
  final int decimals;
  final String locale;
  final AmountUnit? unit;

  AmountInputFormatter({
    required this.decimals,
    required this.locale,
    this.unit,
  });

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // get number symbols for decimal place and group separator
    final numberSymbols = numberFormatSymbols[locale] as NumberSymbols? ??
        numberFormatSymbols[locale.substring(0, 2)] as NumberSymbols?;

    final decimalSeparator = numberSymbols?.DECIMAL_SEP ?? ".";
    final groupSeparator = numberSymbols?.GROUP_SEP ?? ",";

    String newText = newValue.text.replaceAll(groupSeparator, "");

    final selectionIndexFromTheRight =
        newValue.text.length - newValue.selection.end;

    String? fraction;
    if (newText.contains(decimalSeparator)) {
      final parts = newText.split(decimalSeparator);

      if (parts.length > 2) {
        return oldValue;
      }

      final fractionDigits =
          unit == null ? decimals : max(decimals - unit!.shift, 0);

      if (newText.startsWith(decimalSeparator)) {
        if (newText.length - 1 > fractionDigits) {
          newText = newText.substring(0, fractionDigits + 1);
        }

        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: newText.length - selectionIndexFromTheRight,
          ),
        );
      }

      newText = parts.first;
      if (parts.length == 2) {
        fraction = parts.last;
      } else {
        fraction = "";
      }

      if (fraction.length > fractionDigits) {
        fraction = fraction.substring(0, fractionDigits);
      }
    }

    String newString;
    final val = BigInt.tryParse(newText);
    if (val == null || val < BigInt.one) {
      newString = newText;
    } else {
      // insert group separator
      final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
      newString = newText.replaceAllMapped(
        regex,
        (m) => "${m.group(0)}${numberSymbols?.GROUP_SEP ?? ","}",
      );
    }

    if (fraction != null) {
      newString += decimalSeparator;
      if (fraction.isNotEmpty) {
        newString += fraction;
      }
    }

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(
        offset: newString.length - selectionIndexFromTheRight,
      ),
    );
  }
}
