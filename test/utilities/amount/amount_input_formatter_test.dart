import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/amount/amount_input_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';

void main() {
  group('AmountInputFormatter bulk input', () {
    const cases = <({String locale, String input, String expected})>[
      (locale: 'en_US', input: '1,234', expected: '1,234'),
      (locale: 'de_DE', input: '1.234', expected: '1.234'),
      (locale: 'en_US', input: '1,23', expected: '1.23'),
      (locale: 'de_DE', input: '1.23', expected: '1,23'),
      (locale: 'en_US', input: '1.234,56', expected: '1,234.56'),
      (locale: 'de_DE', input: '1,234.56', expected: '1.234,56'),
      (locale: 'fr_FR', input: '1\u202f234,56', expected: '1\u202f234,56'),
      (locale: 'fr_FR', input: '1\u00a0234,56', expected: '1\u202f234,56'),
      (locale: 'fr_FR', input: '1 234,56', expected: '1\u202f234,56'),
      (locale: 'hi_IN', input: '12,34,567.89', expected: '12,34,567.89'),
      (locale: 'hi_IN', input: '1,234,567.89', expected: '12,34,567.89'),
      (locale: 'en_US', input: '0,00', expected: '0.00'),
    ];

    for (final testCase in cases) {
      test('${testCase.locale}: ${testCase.input}', () {
        final result = _format(
          locale: testCase.locale,
          newValue: _value(testCase.input),
        );

        expect(result.text, testCase.expected);
        expect(
          result.selection,
          TextSelection.collapsed(offset: result.text.length),
        );
      });
    }

    test('detects a same-length selected-text replacement', () {
      final result = _format(
        locale: 'en_US',
        oldValue: const TextEditingValue(
          text: '12.34',
          selection: TextSelection(baseOffset: 0, extentOffset: 5),
        ),
        newValue: _value('1,23'),
      );

      expect(result.text, '1.23');
    });

    test('applies the configured fractional precision', () {
      expect(
        _format(locale: 'de_DE', decimals: 2, newValue: _value('1,2345')).text,
        '1,23',
      );
    });

    test('applies crypto unit and token precision', () {
      expect(
        _format(
          locale: 'de_DE',
          decimals: 8,
          unit: AmountUnit.milli,
          newValue: _value('10,123456'),
        ).text,
        '10,12345',
      );
      expect(
        _format(
          locale: 'en_US',
          decimals: 6,
          newValue: _value('0.12345678'),
        ).text,
        '0.123456',
      );
    });

    test('rejects signed amounts', () {
      expect(_format(locale: 'en_US', newValue: _value('-1,23')).text, isEmpty);
      expect(_format(locale: 'en_US', newValue: _value('+1.23')).text, isEmpty);
    });

    test('rejects non-numeric paste and typing', () {
      for (final input in ['1e3', r'$1.23', 'abc']) {
        expect(_format(locale: 'en_US', newValue: _value(input)).text, isEmpty);
      }
      expect(_format(locale: 'en_US', newValue: _value('a')).text, isEmpty);
    });

    test('keeps a grouped integer when no fractions are allowed', () {
      expect(
        _format(locale: 'en_US', decimals: 0, newValue: _value('21,000')).text,
        '21,000',
      );
      expect(
        _format(locale: 'de_DE', decimals: 0, newValue: _value('21.000')).text,
        '21.000',
      );
    });
  });

  test('preserves the cursor during a single-character insertion', () {
    final result = _format(
      locale: 'en_US',
      oldValue: const TextEditingValue(
        text: '12.34',
        selection: TextSelection.collapsed(offset: 2),
      ),
      newValue: const TextEditingValue(
        text: '120.34',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );

    expect(result.text, '120.34');
    expect(result.selection, const TextSelection.collapsed(offset: 3));
  });
}

TextEditingValue _format({
  required String locale,
  required TextEditingValue newValue,
  TextEditingValue oldValue = TextEditingValue.empty,
  int decimals = 8,
  AmountUnit? unit,
}) => AmountInputFormatter(
  decimals: decimals,
  locale: locale,
  unit: unit,
).formatEditUpdate(oldValue, newValue);

TextEditingValue _value(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);
