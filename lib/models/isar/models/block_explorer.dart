import 'package:isar/isar.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

part 'block_explorer.g.dart';

@collection
class TransactionBlockExplorer {
  TransactionBlockExplorer({
    required this.ticker,
    required this.url,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late final String ticker;

  late final String url;

  @ignore
  Coin? get coin {
    try {
      return coinFromTickerCaseInsensitive(ticker);
    } catch (_) {
      return null;
    }
  }

  Uri? getUrlFor({required String txid}) => Uri.tryParse(
        url.replaceFirst(
          "%5BTXID%5D",
          txid,
        ),
      );
}
