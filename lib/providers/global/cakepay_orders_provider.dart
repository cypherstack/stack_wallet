import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/cakepay/cakepay_orders_service.dart';

final pCakePayOrdersService = ChangeNotifierProvider<CakePayOrdersService>(
  (ref) => CakePayOrdersService(),
);
