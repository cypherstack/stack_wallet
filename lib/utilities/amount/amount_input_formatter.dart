import 'dart:math';

import 'package:flutter/services.dart';

import '../util.dart';
import 'amount_unit.dart';

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
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // get number symbols for decimal place and group separator
    final numberSymbols = Util.getSymbolsFor(locale: locale);

    final decimalSeparator = numberSymbols?.DECIMAL_SEP ?? ".";
    final groupSeparator = numberSymbols?.GROUP_SEP ?? ",";
    final oldSelection = oldValue.selection.isValid
        ? oldValue.selection
        : TextSelection.collapsed(offset: oldValue.text.length);

    String text = newValue.text;
    if (groupSeparator == "." && decimalSeparator != ".") {
      final insertedLength =
          newValue.text.length -
          oldValue.text.length +
          oldSelection.end -
          oldSelection.start;
      final insertedStart = oldSelection.start;
      final insertedEnd = insertedStart + insertedLength;
      if (insertedLength > 0 &&
          insertedStart >= 0 &&
          insertedEnd <= text.length) {
        final inserted = text.substring(insertedStart, insertedEnd);
        final isGrouped = RegExp(
          r'^[1-9]\d{0,2}(\.\d{3})+$',
        ).hasMatch(inserted);
        text =
            text.substring(0, insertedStart) +
            (inserted.contains(decimalSeparator) || isGrouped
                ? inserted
                : inserted.replaceAll(groupSeparator, decimalSeparator)) +
            text.substring(insertedEnd);
      }
    }
    final selectionEnd = min(newValue.selection.end, text.length);
    final textBeforeSelection = text
        .substring(0, selectionEnd)
        .replaceAll(groupSeparator, "");
    String newText = text.replaceAll(groupSeparator, "");
    final selectionOffset = textBeforeSelection.length;

    String? fraction;
    if (newText.contains(decimalSeparator)) {
      final parts = newText.split(decimalSeparator);

      if (parts.length > 2) {
        return oldValue;
      }

      final fractionDigits = unit == null
          ? decimals
          : max(decimals - unit!.shift, 0);

      if (newText.startsWith(decimalSeparator)) {
        if (newText.length - 1 > fractionDigits) {
          newText = newText.substring(0, fractionDigits + 1);
        }

        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: min(selectionOffset, newText.length),
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

    int formattedSelectionOffset = 0;
    int normalizedOffset = 0;
    while (formattedSelectionOffset < newString.length &&
        normalizedOffset < selectionOffset) {
      if (newString[formattedSelectionOffset] != groupSeparator) {
        normalizedOffset++;
      }
      formattedSelectionOffset++;
    }

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: formattedSelectionOffset),
    );
  }
}
