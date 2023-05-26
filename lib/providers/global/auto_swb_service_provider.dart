import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/services/auto_swb_service.dart';

final autoSWBServiceProvider = ChangeNotifierProvider<AutoSWBService>(
  (ref) => AutoSWBService(
    secureStorageInterface: ref.read(secureStoreProvider),
  ),
);
