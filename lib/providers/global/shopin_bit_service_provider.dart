import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/shopinbit/shopinbit_service.dart';
import 'secure_store_provider.dart';

final pShopinBitService = Provider(
  (ref) => ShopInBitService()..ensureInitialized(ref.read(secureStoreProvider)),
);
