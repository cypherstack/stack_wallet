import 'package:grin/grin.dart';

export '../generated/libgrin_interface_impl.dart';

/// The only native boundary for Grin. Everything else uses package:grin,
/// which every app config depends on.
abstract class LibGrinInterface {
  const LibGrinInterface();

  GrinWalletBackend get backend;
}
