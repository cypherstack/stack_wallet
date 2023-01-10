import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/services/buys_service.dart';

final buysServiceProvider =
    ChangeNotifierProvider<BuysService>((ref) => BuysService());
