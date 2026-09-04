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
    final grouping = _Grouping.fromPattern(
      numberSymbols?.DECIMAL_PATTERN ?? "#,##0.###",
    );

    final canonicalText = _canonicalizeSpaceGrouping(
      newValue.text,
      groupSeparator,
    );
    if (!_hasOnlyAmountCharacters(
      canonicalText,
      decimalSeparator,
      groupSeparator,
    )) {
      return oldValue;
    }
    TextEditingValue valueToProcess = newValue.copyWith(text: canonicalText);
    if (_isBulkEdit(oldValue.text, newValue.text)) {
      final normalized = _normalizeBulkInput(
        canonicalText,
        decimalSeparator: decimalSeparator,
        groupSeparator: groupSeparator,
        grouping: grouping,
      );
      if (normalized == null) {
        return oldValue;
      }

      final selectionIndexFromTheRight =
          newValue.text.length - newValue.selection.end;
      valueToProcess = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(
          offset: max(normalized.length - selectionIndexFromTheRight, 0),
        ),
      );
    }

    String newText = valueToProcess.text.replaceAll(groupSeparator, "");

    final selectionIndexFromTheRight =
        valueToProcess.text.length - valueToProcess.selection.end;

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
      newString = _groupInteger(newText, groupSeparator, grouping);
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

bool _hasOnlyAmountCharacters(
  String value,
  String decimalSeparator,
  String groupSeparator,
) {
  final separators = {decimalSeparator, groupSeparator, '.', ','};
  return value
      .split('')
      .every(
        (character) =>
            int.tryParse(character) != null || separators.contains(character),
      );
}

bool _isBulkEdit(String oldText, String newText) {
  var prefix = 0;
  while (prefix < oldText.length &&
      prefix < newText.length &&
      oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
    prefix++;
  }

  var oldSuffix = oldText.length;
  var newSuffix = newText.length;
  while (oldSuffix > prefix &&
      newSuffix > prefix &&
      oldText.codeUnitAt(oldSuffix - 1) == newText.codeUnitAt(newSuffix - 1)) {
    oldSuffix--;
    newSuffix--;
  }

  return newSuffix - prefix > 1;
}

String _canonicalizeSpaceGrouping(String value, String groupSeparator) {
  if (!_spaceSeparators.contains(groupSeparator)) {
    return value;
  }

  return value.replaceAll(RegExp(r'[ \u00a0\u202f]'), groupSeparator);
}

String? _normalizeBulkInput(
  String value, {
  required String decimalSeparator,
  required String groupSeparator,
  required _Grouping grouping,
}) {
  final hasDot = value.contains('.');
  final hasComma = value.contains(',');

  if (hasDot && hasComma) {
    final actualDecimal = value.lastIndexOf('.') > value.lastIndexOf(',')
        ? '.'
        : ',';
    final group = actualDecimal == '.' ? ',' : '.';
    final decimalIndex = value.lastIndexOf(actualDecimal);
    final integer = value.substring(0, decimalIndex);
    final fraction = value.substring(decimalIndex + 1);

    if (fraction.contains(actualDecimal) ||
        fraction.contains(group) ||
        integer.contains(actualDecimal) ||
        (integer.contains(group) &&
            !_hasRecognizedGrouping(integer, group, grouping))) {
      return null;
    }

    return '${integer.replaceAll(group, '')}$decimalSeparator$fraction';
  }

  final decimalCount = decimalSeparator.allMatches(value).length;
  if (decimalCount > 1) {
    if (_hasRecognizedGrouping(value, decimalSeparator, grouping)) {
      return value.replaceAll(decimalSeparator, '');
    }
    return null;
  }

  if (decimalCount == 1) {
    final parts = value.split(decimalSeparator);
    if (parts.length != 2 ||
        (parts.first.contains(groupSeparator) &&
            !_hasRecognizedGrouping(parts.first, groupSeparator, grouping))) {
      return null;
    }
    return '${parts.first.replaceAll(groupSeparator, '')}'
        '$decimalSeparator${parts.last}';
  }

  final groupCount = groupSeparator.allMatches(value).length;
  if (groupCount > 0) {
    if (_hasRecognizedGrouping(value, groupSeparator, grouping)) {
      return value.replaceAll(groupSeparator, '');
    }
    if (groupCount == 1 && _dotOrComma.contains(groupSeparator)) {
      return value.replaceFirst(groupSeparator, decimalSeparator);
    }
    return null;
  }

  final foreignSeparator = decimalSeparator == '.' ? ',' : '.';
  final foreignCount = foreignSeparator.allMatches(value).length;
  if (foreignCount == 0) {
    return value;
  }
  if (foreignCount == 1) {
    return value.replaceFirst(foreignSeparator, decimalSeparator);
  }
  if (_hasRecognizedGrouping(value, foreignSeparator, grouping)) {
    return value.replaceAll(foreignSeparator, '');
  }
  return null;
}

bool _hasRecognizedGrouping(
  String value,
  String separator,
  _Grouping localeGrouping,
) =>
    _hasValidGrouping(value, separator, localeGrouping) ||
    _hasValidGrouping(value, separator, const _Grouping(3, 3)) ||
    _hasValidGrouping(value, separator, const _Grouping(3, 2));

bool _hasValidGrouping(String value, String separator, _Grouping grouping) {
  final unsigned = value.startsWith(RegExp(r'[+-]'))
      ? value.substring(1)
      : value;
  final groups = unsigned.split(separator);
  if (groups.length < 2 ||
      groups.any((part) => !RegExp(r'^\d+$').hasMatch(part))) {
    return false;
  }
  if (groups.last.length != grouping.primary) {
    return false;
  }
  for (var i = groups.length - 2; i > 0; i--) {
    if (groups[i].length != grouping.secondary) {
      return false;
    }
  }
  return groups.first.isNotEmpty && groups.first.length <= grouping.secondary;
}

String _groupInteger(String value, String separator, _Grouping grouping) {
  final sign = value.startsWith(RegExp(r'[+-]')) ? value[0] : '';
  var digits = sign.isEmpty ? value : value.substring(1);
  if (!RegExp(r'^\d+$').hasMatch(digits) || digits.length <= grouping.primary) {
    return value;
  }

  final groups = <String>[];
  var size = grouping.primary;
  while (digits.length > size) {
    groups.add(digits.substring(digits.length - size));
    digits = digits.substring(0, digits.length - size);
    size = grouping.secondary;
  }
  groups.add(digits);
  return '$sign${groups.reversed.join(separator)}';
}

class _Grouping {
  const _Grouping(this.primary, this.secondary);

  factory _Grouping.fromPattern(String pattern) {
    final integerPattern = pattern.split('.').first;
    final groups = integerPattern.split(',');
    final primary = groups.length > 1 ? groups.last.length : 3;
    final secondary = groups.length > 2
        ? groups[groups.length - 2].length
        : primary;
    return _Grouping(primary, secondary);
  }

  final int primary;
  final int secondary;
}

const _dotOrComma = {'.', ','};
const _spaceSeparators = {' ', '\u00a0', '\u202f'};
