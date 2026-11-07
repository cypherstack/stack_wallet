/// How a Mimblewimble send reaches its recipient.
enum SlatepackMethod {
  /// Slatepacks are handed over by the user.
  slatepack,

  /// Through a relay such as epicbox or mwcmqs.
  relay,

  /// Directly to the recipient's wallet over HTTP or Tor.
  http,
}
