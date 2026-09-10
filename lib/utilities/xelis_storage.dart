import 'dart:io';

import 'package:path/path.dart' as path;

/// Resolve one native wallet, rejecting aliases to other wallets or tables.
/// A missing directory is safe on a restored Stack backup with no native data.
Future<Directory?> xelisWalletDirectory(Directory root, String walletId) async {
  if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(walletId) ||
      walletId.toLowerCase() == 'table') {
    throw StateError('Invalid Xelis wallet directory');
  }
  final directory = Directory(path.join(root.path, walletId));
  final type = await FileSystemEntity.type(directory.path, followLinks: false);
  if (type == FileSystemEntityType.notFound) return null;
  if (type != FileSystemEntityType.directory) {
    throw StateError('Xelis wallet storage is not a regular directory');
  }
  final expected = path.join(await root.resolveSymbolicLinks(), walletId);
  final actual = await directory.resolveSymbolicLinks();
  if (!path.equals(expected, actual)) {
    throw StateError('Xelis wallet storage resolves to a different directory');
  }
  return directory;
}
