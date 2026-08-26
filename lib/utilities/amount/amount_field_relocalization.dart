import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/global/locale_provider.dart';
import 'amount.dart';

typedef ProviderListen<T> =
    void Function(
      ProviderListenable<T> provider,
      void Function(T? previous, T next) listener,
    );

/// Rewrites a controller's decimal separator while preserving its selection.
void relocalizeAmountController(
  TextEditingController controller, {
  required String sourceLocale,
  required String targetLocale,
}) {
  final value = controller.value;
  final text = Amount.relocalizeEditableDecimal(
    value.text,
    sourceLocale: sourceLocale,
    targetLocale: targetLocale,
  );
  if (text == value.text) return;

  int mapOffset(int offset) {
    int safeOffset = offset;
    if (safeOffset < 0) {
      safeOffset = 0;
    } else if (safeOffset > value.text.length) {
      safeOffset = value.text.length;
    }
    return Amount.relocalizeEditableDecimal(
      value.text.substring(0, safeOffset),
      sourceLocale: sourceLocale,
      targetLocale: targetLocale,
    ).length;
  }

  final selection = value.selection.isValid
      ? TextSelection(
          baseOffset: mapOffset(value.selection.baseOffset),
          extentOffset: mapOffset(value.selection.extentOffset),
          affinity: value.selection.affinity,
          isDirectional: value.selection.isDirectional,
        )
      : value.selection;
  controller.value = value.copyWith(
    text: text,
    selection: selection,
    composing: TextRange.empty,
  );
}

/// Rewrites the decimal separator in [controllers] when the app locale
/// changes so their text stays parseable by the locale-strict amount
/// parsers, then invokes [onRelocalized] so the caller can re-run any
/// parsing/validation that cached state from the old text.
///
/// Must be called from a widget's build method with `ref.listen`.
void listenForAmountRelocalization(
  ProviderListen<String> listen, {
  required List<TextEditingController> controllers,
  VoidCallback? onRelocalized,
}) {
  listen(localeServiceChangeNotifierProvider.select((value) => value.locale), (
    previous,
    next,
  ) {
    if (previous == null || previous == next) return;
    for (final controller in controllers) {
      relocalizeAmountController(
        controller,
        sourceLocale: previous,
        targetLocale: next,
      );
    }
    onRelocalized?.call();
  });
}
