/// Parsing shared by Slatepack entry points and MWC format checks.
abstract final class SlatepackText {
  static final RegExp _armoredFrame = RegExp(
    r"BEGINSLATE(PACK|_BIN)\.[\s\S]*?ENDSLATE\1\.?",
  );

  /// Whether [text] consists of exactly one armored Slatepack frame.
  static bool isArmored(String text) {
    final trimmed = text.trim();
    return _armoredFrame.firstMatch(trimmed)?.group(0) == trimmed;
  }

  /// Removes surrounding prose from an armored Slatepack.
  ///
  /// Plain slate JSON and unrecognized text are only trimmed.
  static String normalize(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith("{")) return trimmed;
    return _armoredFrame.firstMatch(trimmed)?.group(0) ?? trimmed;
  }
}
