import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stackduo/providers/desktop/storage_crypto_handler_provider.dart';
import 'package:stackduo/utilities/flutter_secure_storage_interface.dart';
import 'package:stackduo/utilities/util.dart';

final secureStoreProvider = Provider<SecureStorageInterface>((ref) {
  if (Util.isDesktop) {
    final handler = ref.read(storageCryptoHandlerProvider).handler;
    return SecureStorageWrapper(
        store: DesktopSecureStore(handler), isDesktop: true);
  } else {
    return const SecureStorageWrapper(
      store: FlutterSecureStorage(),
      isDesktop: false,
    );
  }
});
