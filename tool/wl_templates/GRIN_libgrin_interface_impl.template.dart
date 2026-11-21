//ON
import 'package:grin_native/grin_native.dart';

//END_ON
//OFF
import 'package:grin_native/grin_native.dart';

//END_OFF
import '../interfaces/libgrin_interface.dart';

LibGrinInterface get libGrin => const _LibGrinInterfaceImpl();

final class _LibGrinInterfaceImpl extends LibGrinInterface {
  const _LibGrinInterfaceImpl();

  @override
  //OFF
  GrinWalletBackend get backend => throw StateError("GRIN not enabled");
  //END_OFF
  //ON
  GrinWalletBackend get backend => const GrinNativeBackend();
  //END_ON
}
