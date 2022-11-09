import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stackwallet/providers/desktop/storage_crypto_handler_provider.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/util.dart';

final secureStoreProvider = Provider<FlutterSecureStorageInterface>((ref) {
  if (Util.isDesktop) {
    final handler = ref.read(storageCryptoHandlerProvider).handler;
    return SecureStorageWrapper(
        store: DesktopPWStore(handler), isDesktop: true);
  } else {
    return const SecureStorageWrapper(
      store: FlutterSecureStorage(),
      isDesktop: false,
    );
  }
});
