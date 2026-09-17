import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/amount/amount_field_relocalization.dart';

void main() {
  test('relocalizing an amount preserves its selection', () {
    const selection = TextSelection(
      baseOffset: 4,
      extentOffset: 1,
      affinity: TextAffinity.upstream,
      isDirectional: true,
    );
    final controller = TextEditingController.fromValue(
      const TextEditingValue(
        text: '12.34',
        selection: selection,
        composing: TextRange(start: 2, end: 4),
      ),
    );
    addTearDown(controller.dispose);

    relocalizeAmountController(
      controller,
      sourceLocale: 'en_US',
      targetLocale: 'de_DE',
    );

    expect(controller.text, '12,34');
    expect(controller.selection, selection);
    expect(controller.value.composing, TextRange.empty);
  });
}
