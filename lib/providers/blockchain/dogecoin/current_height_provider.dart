import 'package:dart_numerics/dart_numerics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

final currentHeightProvider =
    StateProvider.family<int, Coin>((ref, coin) => int64MaxValue);
