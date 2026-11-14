/// How a Mimblewimble transaction is exchanged with the other party.
enum SlatepackMethod {
  /// Manual slatepack exchange (copy/paste, QR codes, files).
  slatepack("Slatepack"),

  /// Automatic exchange through the coin's relay server (epicbox, mwcmqs).
  relay("Automatic"),

  /// Direct send to the recipient's listener (http(s), Tor).
  http("Address");

  const SlatepackMethod(this.label);

  /// Label on the method toggle.
  final String label;

  static SlatepackMethod? fromName(String? name) {
    for (final m in values) {
      if (m.name == name) return m;
    }
    return null;
  }
}
