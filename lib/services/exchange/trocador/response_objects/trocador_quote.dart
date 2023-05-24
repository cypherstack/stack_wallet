import 'package:decimal/decimal.dart';

class TrocadorQuote {
  final String provider;
  final String kycRating;
  final int insurance;
  final bool fixed;
  final Decimal? amountTo;
  final Decimal? amountFrom;
  final Decimal waste;

  TrocadorQuote({
    required this.provider,
    required this.kycRating,
    required this.insurance,
    required this.fixed,
    required this.amountTo,
    required this.amountFrom,
    required this.waste,
  });

  factory TrocadorQuote.fromMap(Map<String, dynamic> map) {
    return TrocadorQuote(
      provider: map['provider'] as String,
      kycRating: map['kycrating'] as String,
      insurance: map['insurance'] as int,
      // wtf trocador?
      fixed: map['fixed'] == "True",
      amountTo: Decimal.tryParse(map['amount_to'].toString()),
      amountFrom: Decimal.tryParse(map['amount_from'].toString()),
      waste: Decimal.parse(map['waste'].toString()),
    );
  }

  @override
  String toString() {
    return 'TrocadorQuote( '
        'provider: $provider, '
        'kycRating: $kycRating, '
        'insurance: $insurance, '
        'fixed: $fixed, '
        'amountTo: $amountTo, '
        'amountFrom: $amountFrom, '
        'waste: $waste '
        ')';
  }
}
