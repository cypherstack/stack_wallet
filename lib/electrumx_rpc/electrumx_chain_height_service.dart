import 'dart:async';

import 'package:stackwallet/utilities/enums/coin_enum.dart';

/// Store chain height subscriptions for each coin.
abstract class ElectrumxChainHeightService {
  // Used to hold chain height subscriptions for each coin as in:
  // ElectrumxChainHeightService.subscriptions[cryptoCurrency.coin] = sub;
  static Map<Coin, StreamSubscription<dynamic>?> subscriptions = {};

  // Used to hold chain height completers for each coin as in:
  // ElectrumxChainHeightService.completers[cryptoCurrency.coin] = completer;
  static Map<Coin, Completer<int>?> completers = {};

  // Used to hold the time each coin started waiting for chain height as in:
  // ElectrumxChainHeightService.timeStarted[cryptoCurrency.coin] = time;
  static Map<Coin, DateTime?> timeStarted = {};
}
