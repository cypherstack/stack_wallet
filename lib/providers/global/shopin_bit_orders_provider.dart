import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/shopinbit/shopinbit_orders_service.dart';
import 'shopin_bit_service_provider.dart';

final pShopInBitOrdersService = ChangeNotifierProvider<ShopInBitOrdersService>(
  (ref) =>
      ShopInBitOrdersService(shopInBitService: ref.read(pShopinBitService)),
);
