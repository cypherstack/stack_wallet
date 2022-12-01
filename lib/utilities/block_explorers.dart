import 'package:epicmobile/utilities/enums/coin_enum.dart';

Uri getBlockExplorerTransactionUrlFor({
  required Coin coin,
  required String txid,
}) {
  switch (coin) {
    case Coin.epicCash:
      // TODO: Handle this case.
      throw UnimplementedError("missing block explorer for epic cash");
  }
}
