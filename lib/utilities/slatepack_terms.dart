/// Wording the slatepack screens use for the payload being exchanged. Epic
/// Cash passes raw slate JSON around while MWC uses armored slatepacks. A
/// wallet picks its terms through SlatepackInterface.slatepackTerms.
enum SlatepackTerms {
  slate("slate", "Slate JSON"),
  slatepack("slatepack", "Slatepack Message");

  const SlatepackTerms(this.noun, this.payload);

  /// "slate" or "slatepack".
  final String noun;

  /// What the user is asked to paste, e.g. "Slatepack Message".
  final String payload;

  /// [noun] with a capital, for titles.
  String get title => "${noun[0].toUpperCase()}${noun.substring(1)}";
}
