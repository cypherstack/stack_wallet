import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';
import 'package:stackwallet/services/exchange/exchange.dart';

final changeNowProvider = Provider<Exchange>((ref) => ChangeNowExchange());
