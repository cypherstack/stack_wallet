import 'dart:io';

abstract class Util {
  static bool get isDesktop {
    return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
  }
}
