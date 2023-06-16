import 'package:flutter/services.dart';
import 'package:intl/number_symbols.dart';
import 'package:intl/number_symbols_data.dart';

class AmountInputFormatter extends TextInputFormatter {
  final int decimals;
  final String locale;

  AmountInputFormatter({required this.decimals, required this.locale});

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
      if (newText.startsWith(decimalSeparator)) {
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

      if (fraction.length > decimals) {
        return oldValue;
      }
    }

    if (newText.trim() == '' || newText.trim() == '0') {
      return newValue.copyWith(text: '');
    } else if (BigInt.parse(newText) < BigInt.one) {
      return newValue.copyWith(text: '');
    }

    // insert group separator
    final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');

    String newString = newText.replaceAllMapped(
      regex,
      (m) => "${m.group(0)}${numberSymbols?.GROUP_SEP ?? ","}",
    );

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
