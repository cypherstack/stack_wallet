import 'package:decimal/decimal.dart';

class TrocadorCoin {
  final String name;
  final String ticker;
  final String network;
  final bool memo;
  final String image;
  final Decimal minimum;
  final Decimal maximum;

  TrocadorCoin({
    required this.name,
    required this.ticker,
    required this.network,
    required this.memo,
    required this.image,
    required this.minimum,
    required this.maximum,
  });

  factory TrocadorCoin.fromMap(Map<String, dynamic> json) => TrocadorCoin(
        name: json['name'] as String,
        ticker: json['ticker'] as String,
        network: json['network'] as String,
        memo: json['memo'] as bool,
        image: json['image'] as String,
        minimum: Decimal.parse(json['minimum'].toString()),
        maximum: Decimal.parse(json['maximum'].toString()),
      );

  @override
  String toString() {
    return 'TrocadorCoin( '
        'name: $name, '
        'ticker: $ticker, '
        'network: $network, '
        'memo: $memo, '
        'image: $image, '
        'minimum: $minimum, '
        'maximum: $maximum '
        ')';
  }
}
