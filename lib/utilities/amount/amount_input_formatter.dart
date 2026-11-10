import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../util.dart';
import 'amount_unit.dart';

class AmountInputFormatter extends TextInputFormatter {
  final TextEditingController controller;
  final int decimals;
  final String locale;
  final AmountUnit? unit;

  AmountInputFormatter({
    required this.controller,
    required this.decimals,
    required this.locale,
    this.unit,
  }) : assert(decimals >= 0);

  late final String _decimalSeparator =
      Util.getSymbolsFor(locale: locale)?.DECIMAL_SEP ?? ".";

  late final int _maximumFractionDigits = unit == null
      ? max(decimals, 0)
      : max(decimals - unit!.shift, 0);

  // Formatters are frequently constructed inline in build methods that
  // rebuild per keystroke, so the compiled patterns are cached globally
  // instead of per instance.
  static final Map<(String, int), RegExp> _patternCache = {};

  late final RegExp _validPattern = _patternCache.putIfAbsent(
    (_decimalSeparator, _maximumFractionDigits),
    () => _maximumFractionDigits == 0
        ? RegExp(r'^\d*$')
        : RegExp(
            '^\\d*(?:${RegExp.escape(_decimalSeparator)}\\d{0,$_maximumFractionDigits})?\$',
          ),
  );

  static final Expando<_AmountInputRecovery> _recoveryCache = Expando();

  (String, int, int?) get _configuration => (locale, decimals, unit?.shift);

  _AmountInputRecovery? get _activeRecovery {
    final recovery = _recoveryCache[controller];
    return recovery?.configuration == _configuration ? recovery : null;
  }

  bool _continuesActiveComposition(
    _AmountInputRecovery recovery,
    TextEditingValue oldValue,
  ) =>
      !oldValue.composing.isCollapsed &&
      recovery.composingText == oldValue.text;

  void _clearRecovery() => _recoveryCache[controller] = null;

  void _rememberComposition(TextEditingValue value, String composingText) {
    if (value.text.isEmpty) {
      _clearRecovery();
      return;
    }

    final selection = value.selection.isValid
        ? TextSelection(
            baseOffset: min(
              max(value.selection.baseOffset, 0),
              value.text.length,
            ),
            extentOffset: min(
              max(value.selection.extentOffset, 0),
              value.text.length,
            ),
            affinity: value.selection.affinity,
            isDirectional: value.selection.isDirectional,
          )
        : TextSelection.collapsed(offset: value.text.length);
    _recoveryCache[controller] = _AmountInputRecovery(
      configuration: _configuration,
      value: value.copyWith(selection: selection, composing: TextRange.empty),
      composingText: composingText,
    );
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) {
      if (_validPattern.hasMatch(oldValue.text)) {
        _rememberComposition(oldValue, newValue.text);
      } else {
        final recovery = _activeRecovery;
        if (recovery != null &&
            _continuesActiveComposition(recovery, oldValue)) {
          _recoveryCache[controller] = _AmountInputRecovery(
            configuration: _configuration,
            value: recovery.value,
            composingText: newValue.text,
          );
        } else {
          _clearRecovery();
        }
      }
      return newValue;
    }

    if (_validPattern.hasMatch(newValue.text)) {
      _clearRecovery();
      return newValue;
    }

    final recovery = _activeRecovery;
    if (recovery != null && _continuesActiveComposition(recovery, oldValue)) {
      _clearRecovery();
      return recovery.value;
    }

    final oldTextIsValid = _validPattern.hasMatch(oldValue.text);
    final isDeletingFromInvalidText =
        !oldTextIsValid &&
        newValue.text.length < oldValue.text.length &&
        _canResultFromDeletion(oldValue.text, newValue.text);
    if (isDeletingFromInvalidText) {
      _clearRecovery();
      return newValue;
    }

    if (oldTextIsValid) {
      _clearRecovery();
      return oldValue;
    }

    // Both texts are invalid, but are not the commit of the active composing
    // value. A remembered value from an unrelated edit (or an earlier
    // formatter configuration) must not replace the current input.
    _clearRecovery();
    // Never strip characters from the middle — joining the surrounding digits
    // would silently change the value ("1.5" must not become "15").
    return _validPrefix(newValue);
  }

  TextEditingValue _validPrefix(TextEditingValue value) {
    const asciiZeroCodeUnit = 0x30;
    const asciiNineCodeUnit = 0x39;
    bool separatorSeen = false;
    int fractionDigits = 0;
    int end = 0;
    for (; end < value.text.length; end++) {
      final char = value.text[end];
      final codeUnit = char.codeUnitAt(0);
      if (codeUnit >= asciiZeroCodeUnit && codeUnit <= asciiNineCodeUnit) {
        if (separatorSeen) {
          if (fractionDigits >= _maximumFractionDigits) break;
          fractionDigits++;
        }
      } else if (!separatorSeen &&
          _maximumFractionDigits > 0 &&
          char == _decimalSeparator) {
        separatorSeen = true;
      } else {
        break;
      }
    }
    final text = value.text.substring(0, end);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: min(
          value.selection.isValid ? value.selection.end : text.length,
          text.length,
        ),
      ),
    );
  }

  bool _canResultFromDeletion(String oldText, String newText) {
    int newIndex = 0;
    for (
      int oldIndex = 0;
      oldIndex < oldText.length && newIndex < newText.length;
      oldIndex++
    ) {
      if (oldText.codeUnitAt(oldIndex) == newText.codeUnitAt(newIndex)) {
        newIndex++;
      }
    }
    return newIndex == newText.length;
  }
}

class _AmountInputRecovery {
  final (String, int, int?) configuration;
  final TextEditingValue value;
  final String composingText;

  const _AmountInputRecovery({
    required this.configuration,
    required this.value,
    required this.composingText,
  });
}
