import '../wallets/crypto_currency/crypto_currency.dart';

/// Wording the slatepack screens use for the payload being exchanged. Epic
/// Cash passes raw slate JSON around while MWC uses armored slatepacks.
enum SlatepackTerms {
  slate("slate", "Slate JSON", "Enter Response Slate JSON"),
  slatepack("slatepack", "Slatepack Message", "Enter Final Slatepack Message");

  const SlatepackTerms(this.noun, this.payload, this.finalizeHint);

  /// "slate" or "slatepack".
  final String noun;

  /// What the user is asked to paste, e.g. "Slatepack Message".
  final String payload;

  /// Hint for the response field on the finalize screen.
  final String finalizeHint;

  /// [noun] with a capital, for titles.
  String get title => "${noun[0].toUpperCase()}${noun.substring(1)}";

  static SlatepackTerms forCoin(CryptoCurrency coin) =>
      coin is Epiccash ? slate : slatepack;
}
