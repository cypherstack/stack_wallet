import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/services/trade_sent_from_stack_service.dart';

final tradeSentFromStackLookupProvider =
    ChangeNotifierProvider<TradeSentFromStackService>(
        (ref) => TradeSentFromStackService());
