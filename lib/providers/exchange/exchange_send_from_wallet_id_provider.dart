import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:tuple/tuple.dart';

final exchangeSendFromWalletIdStateProvider =
    StateProvider<Tuple2<String, Coin>?>((ref) => null);
