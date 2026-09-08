/// How an Epic Cash or MWC transaction is exchanged with the other party.
enum MimblewimbleTransactionMethod {
  /// Manual slate exchange (copy/paste, QR codes, files).
  slatepack,

  /// Automatic exchange through the coin's relay server (epicbox, mwcmqs).
  relay,
}
