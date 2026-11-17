import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _ChmodNative = Int32 Function(Pointer<Utf8>, Uint32);
typedef _ChmodDart = int Function(Pointer<Utf8>, int);

_ChmodDart? _chmod;

/// Sets [path] to mode 0700 on Linux and macOS. Does nothing elsewhere.
///
/// Throws [FileSystemException] if the mode cannot be set.
void restrictDirectoryToOwner(String path) {
  if (!(Platform.isLinux || Platform.isMacOS)) return;
  final chmod = _chmod ??= DynamicLibrary.process()
      .lookupFunction<_ChmodNative, _ChmodDart>("chmod");
  final nativePath = path.toNativeUtf8();
  try {
    if (chmod(nativePath, 448) != 0) {
      throw FileSystemException("Could not restrict directory", path);
    }
  } finally {
    malloc.free(nativePath);
  }
}

/// Creates [path] and its parents if needed, then restricts [path] to its
/// owner.
Future<Directory> createOwnerOnlyDirectory(String path) async {
  final dir = Directory(path);
  if (!await dir.exists()) await dir.create(recursive: true);
  restrictDirectoryToOwner(dir.path);
  return dir;
}
