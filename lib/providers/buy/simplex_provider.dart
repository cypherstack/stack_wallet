import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/buy/simplex/simplex.dart';

final simplexProvider = Provider<Simplex>(
  (ref) => Simplex(),
);
