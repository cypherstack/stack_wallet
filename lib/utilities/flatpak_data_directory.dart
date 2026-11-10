import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

typedef DirectoryCopy = Future<void> Function(
  Directory source,
  Directory destination,
);
typedef DirectoryRename = Future<void> Function(
  Directory source,
  String destination,
);

abstract class FlatpakDataDirectory {
  static const migrationMarker = ".flatpak_data_migration_v1";

  /// Written to the legacy root before its contents are removed, so a later
  /// launch can finish an interrupted removal.
  static const legacyRemovalMarker = ".flatpak_data_migrated";

  /// Moves legacy data before selecting Flatpak's app-private XDG root.
  static Future<Directory?> resolve({
    required Map<String, String> environment,
    required String appDirectoryName,
    DirectoryRename renameDirectory = _renameDirectory,
    DirectoryCopy copyDirectory = _copyDirectory,
    void Function(Object error)? onError,
  }) async {
    if ((environment["FLATPAK_ID"] ?? "").isEmpty) {
      return null;
    }

    final xdgDataHome = environment["XDG_DATA_HOME"];
    if (xdgDataHome == null || xdgDataHome.isEmpty) {
      return null;
    }

    final destination = Directory(path.join(xdgDataHome, appDirectoryName));
    final home = environment["HOME"];
    if (home == null || home.isEmpty) {
      await _initialize(destination);
      return destination;
    }

    final legacy = Directory(path.join(home, ".$appDirectoryName"));
    final legacyType = await FileSystemEntity.type(
      legacy.path,
      followLinks: false,
    );
    if (legacyType == FileSystemEntityType.notFound) {
      await _initialize(destination);
      return destination;
    }
    if (legacyType != FileSystemEntityType.directory) {
      onError?.call(
        FileSystemException(
          "Legacy Flatpak data is not a directory",
          legacy.path,
        ),
      );
      return legacy;
    }

    final marker = File(path.join(destination.path, migrationMarker));
    RandomAccessFile? migrationLock;
    try {
      // Serialize before touching legacy data. A separate lock in the XDG
      // parent also covers first launch when Hive has not created dbinfo.lock.
      await Directory(path.dirname(destination.path)).create(recursive: true);
      migrationLock = await File("${destination.path}.migration.lock")
          .open(mode: FileMode.append);
      await migrationLock.lock(FileLock.exclusive);
    } catch (error) {
      await _releaseLock(migrationLock, onError);
      onError?.call(error);
      // If XDG is not writable, keep using the legacy data without mutation.
      return legacy;
    }

    if (await marker.exists()) {
      if (await File(path.join(legacy.path, legacyRemovalMarker)).exists()) {
        await _removeLegacy(legacy, onError);
      }
      await _releaseLock(migrationLock, onError);
      return destination;
    }

    if (await destination.exists()) {
      onError?.call(
        StateError(
          "Flatpak data migration found both legacy and unverified data",
        ),
      );
      await _releaseLock(migrationLock, onError);
      return legacy;
    }

    final temporary = Directory("${destination.path}.migrating");
    RandomAccessFile? migrationLock;
    RandomAccessFile? legacyLock;
    try {
      legacyLock = await _lockLegacyDatabase(legacy);
      // Another instance may have completed a verified migration between the
      // marker check above and taking the lock.
      if (await marker.exists()) {
        return destination;
      }
      final temporaryType = await FileSystemEntity.type(
        temporary.path,
        followLinks: false,
      );
      if (temporaryType == FileSystemEntityType.directory) {
        await temporary.delete(recursive: true);
      } else if (temporaryType != FileSystemEntityType.notFound) {
        throw FileSystemException(
          "Flatpak migration path is not a directory",
          temporary.path,
        );
      }

      await Directory(path.dirname(destination.path)).create(recursive: true);
      var renamed = true;
      try {
        await renameDirectory(legacy, destination.path);
      } on FileSystemException {
        // Always the case inside Flatpak, where the legacy root is a bind
        // mount. Fall back to copying.
        renamed = false;
      }
      if (renamed) {
        try {
          await _initialize(destination);
        } catch (error) {
          // The data is already in place; the next launch writes the marker.
          onError?.call(error);
        }
        return destination;
      }

      await copyDirectory(legacy, temporary);
      await _verifyDirectoryCopy(legacy, temporary);
      await File(path.join(temporary.path, migrationMarker))
          .writeAsString("complete", flush: true);
      final removalMarker = File(path.join(legacy.path, legacyRemovalMarker));
      await removalMarker.writeAsString("removing", flush: true);
      final copiedRemovalMarker = File(
        path.join(temporary.path, legacyRemovalMarker),
      );
      if (await copiedRemovalMarker.exists())
        await copiedRemovalMarker.delete();
      await renameDirectory(temporary, destination.path);
      // Leave no second copy of the wallet data behind, e.g. one that a
      // desktop reset of the new root would not remove.
      await _removeLegacy(legacy, onError);
      return destination;
    } catch (error) {
      try {
        if (await FileSystemEntity.type(temporary.path, followLinks: false) ==
            FileSystemEntityType.directory) {
          await temporary.delete(recursive: true);
        }
      } catch (cleanupError) {
        onError?.call(cleanupError);
      }
      // The rename loses to another instance that finished a verified
      // migration first; use that data rather than diverging onto legacy.
      if (await marker.exists()) {
        return destination;
      }
      onError?.call(error);
      return legacy;
    } finally {
      await _releaseLock(legacyLock, onError);
      await _releaseLock(migrationLock, onError);
    }
  }

  static Future<void> _releaseLock(
    RandomAccessFile? lock,
    void Function(Object error)? onError,
  ) async {
    if (lock == null) return;
    try {
      await lock.unlock();
    } catch (error) {
      onError?.call(error);
    }
    try {
      await lock.close();
    } catch (error) {
      onError?.call(error);
    }
  }

  static Future<RandomAccessFile?> _lockLegacyDatabase(Directory legacy) async {
    final lockFile = File(path.join(legacy.path, "hive", "dbinfo.lock"));
    if (!await lockFile.exists()) {
      return null;
    }

    final handle = await lockFile.open(mode: FileMode.append);
    try {
      await handle.lock(FileLock.exclusive);
      return handle;
    } catch (_) {
      await handle.close();
      rethrow;
    }
  }

  static Future<void> _removeLegacy(
    Directory legacy,
    void Function(Object error)? onError,
  ) async {
    try {
      final removalMarker = File(path.join(legacy.path, legacyRemovalMarker));
      await removalMarker.writeAsString("removing", flush: true);
      final entities = await legacy.list(followLinks: false).toList();
      for (final entity in entities) {
        if (entity.path != removalMarker.path) {
          await entity.delete(recursive: true);
        }
      }
      await removalMarker.delete();
    } catch (error) {
      onError?.call(error);
      return;
    }
    try {
      await legacy.delete();
    } on FileSystemException {
      // Expected inside Flatpak, where the legacy root is a mount point.
    }
  }

  static Future<void> _renameDirectory(Directory source, String destination) =>
      source.rename(destination);

  static Future<void> _initialize(Directory destination) async {
    await destination.create(recursive: true);
    final marker = File(path.join(destination.path, migrationMarker));
    if (!await marker.exists()) {
      await marker.writeAsString("complete", flush: true);
    }
  }

  static Future<void> _copyDirectory(
    Directory source,
    Directory destination,
  ) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      final targetPath = path.join(
        destination.path,
        path.basename(entity.path),
      );
      final type = await FileSystemEntity.type(entity.path, followLinks: false);
      switch (type) {
        case FileSystemEntityType.directory:
          await _copyDirectory(entity as Directory, Directory(targetPath));
        case FileSystemEntityType.file:
          await (entity as File).copy(targetPath);
          final copied = await File(targetPath).open(mode: FileMode.append);
          await copied.flush();
          await copied.close();
        default:
          throw FileSystemException(
            "Unsupported entry in Flatpak data directory",
            entity.path,
          );
      }
    }
  }

  static Future<void> _verifyDirectoryCopy(
    Directory source,
    Directory destination,
  ) async {
    final sourceEntries = await _fileDigests(source);
    final destinationEntries = await _fileDigests(destination);
    if (sourceEntries.length != destinationEntries.length) {
      throw const FileSystemException("Flatpak data copy is incomplete");
    }

    for (final entry in sourceEntries.entries) {
      if (destinationEntries[entry.key] != entry.value) {
        throw FileSystemException(
          "Flatpak data copy verification failed",
          entry.key,
        );
      }
    }
  }

  static Future<Map<String, String>> _fileDigests(Directory root) async {
    final entries = <String, String>{};
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      final relativePath = path.relative(entity.path, from: root.path);
      final type = await FileSystemEntity.type(entity.path, followLinks: false);
      if (type == FileSystemEntityType.directory) {
        entries[relativePath] = "directory";
      } else if (type == FileSystemEntityType.file) {
        entries[relativePath] =
            (await sha256.bind((entity as File).openRead()).first).toString();
      } else {
        throw FileSystemException(
          "Unsupported entry in Flatpak data directory",
          entity.path,
        );
      }
    }
    return entries;
  }
}
