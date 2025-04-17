import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

class Utf8ByteLengthLimitingTextInputFormatter extends TextInputFormatter {
  Utf8ByteLengthLimitingTextInputFormatter(
    this.maxBytes, {
    this.tryMinifyJson = false,
  }) : assert(maxBytes == -1 || maxBytes > 0);

  final int maxBytes;
  final bool tryMinifyJson;

  static String _maybeTryMinify(String text, bool tryMinifyJson) {
    if (tryMinifyJson) {
      try {
        final json = jsonDecode(text);
        final minified = jsonEncode(json);
        return minified;
      } catch (_) {}
    }

    return text;
  }

  static TextEditingValue truncate(
    TextEditingValue value,
    int maxBytes,
    bool tryMinifyJson,
  ) {
    final String text = _maybeTryMinify(value.text, tryMinifyJson);
    final encoded = utf8.encode(text);

    if (encoded.length <= maxBytes) {
      return value;
    }

    int validLength = maxBytes;
    while (validLength > 0 && (encoded[validLength] & 0xC0) == 0x80) {
      validLength--;
    }

    final truncated = utf8.decode(encoded.sublist(0, validLength));

    return TextEditingValue(
      text: truncated,
      selection: value.selection.copyWith(
        baseOffset: math.min(value.selection.start, truncated.length),
        extentOffset: math.min(value.selection.end, truncated.length),
      ),
      composing: !value.composing.isCollapsed &&
              truncated.length > value.composing.start
          ? TextRange(
              start: value.composing.start,
              end: math.min(value.composing.end, truncated.length),
            )
          : TextRange.empty,
    );
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (maxBytes == -1 ||
        utf8
                .encode(_maybeTryMinify(newValue.text, tryMinifyJson))
                .lengthInBytes <=
            maxBytes) {
      return newValue;
    }

    assert(maxBytes > 0);

    if (utf8
                .encode(_maybeTryMinify(oldValue.text, tryMinifyJson))
                .lengthInBytes ==
            maxBytes &&
        oldValue.selection.isCollapsed) {
      return oldValue;
    }

    return truncate(newValue, maxBytes, tryMinifyJson);
  }
}
