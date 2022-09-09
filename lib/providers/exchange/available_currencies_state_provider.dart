import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/change_now/currency.dart';

final availableChangeNowCurrenciesStateProvider =
    StateProvider<List<Currency>>((ref) => <Currency>[]);
