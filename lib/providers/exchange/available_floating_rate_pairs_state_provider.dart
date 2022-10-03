import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/response_objects/pair.dart';

final availableFloatingRatePairsStateProvider =
    StateProvider<List<Pair>>((ref) => <Pair>[]);
