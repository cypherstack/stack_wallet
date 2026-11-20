import 'dart:io';

import 'package:path/path.dart' as path;

import '../../../utilities/flutter_secure_storage_interface.dart';

const zcashWalletPersistenceSuffixes = <String>[
  'state',
  'pending',
  'shielding',
  'zip318',
];

String zcashWalletStateKey(String walletId) =>
    'zcash_wallet_state_key_v1_$walletId';

String zcashPendingSendKey(String walletId) =>
    'zcash_pending_send_key_v1_$walletId';

String zcashTransparentShieldingKey(String walletId) =>
    'zcash_transparent_shielding_key_v1_$walletId';

String zcashZip318Key(String walletId) => 'zcash_zip318_key_v1_$walletId';

List<String> zcashWalletPersistenceKeys(String walletId) => [
  zcashWalletStateKey(walletId),
  zcashPendingSendKey(walletId),
  zcashTransparentShieldingKey(walletId),
  zcashZip318Key(walletId),
];

/// Removes exactly one wallet's Zcash checkpoints and their encryption keys.
/// Shared proving parameters and other wallets' files are never traversed.
Future<void> deleteZcashWalletPersistence({
  required Directory applicationRoot,
  required String walletId,
  required SecureStorageInterface secureStorage,
}) async {
  if (walletId.isEmpty ||
      walletId == '.' ||
      walletId == '..' ||
      walletId.contains('/') ||
      walletId.contains(r'\')) {
    throw ArgumentError.value(
      walletId,
      'walletId',
      'must be one path-safe segment',
    );
  }
  Object? firstError;
  StackTrace? firstStackTrace;

  Future<void> attempt(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }
  }

  final zcashRoot = path.join(applicationRoot.path, 'zcash');
  for (final suffix in zcashWalletPersistenceSuffixes) {
    final persistedPath = path.join(zcashRoot, '$walletId.$suffix');
    await attempt(() => _deleteExactFile(persistedPath));
    await attempt(() => _deleteExactFile('$persistedPath.tmp'));
  }
  if (firstError != null) {
    Error.throwWithStackTrace(firstError!, firstStackTrace!);
  }
  for (final key in zcashWalletPersistenceKeys(walletId)) {
    await attempt(() => secureStorage.delete(key: key));
  }

  if (firstError != null) {
    Error.throwWithStackTrace(firstError!, firstStackTrace!);
  }
}

Future<void> _deleteExactFile(String candidate) async {
  switch (await FileSystemEntity.type(candidate, followLinks: false)) {
    case FileSystemEntityType.notFound:
      return;
    case FileSystemEntityType.file:
      await File(candidate).delete();
    case FileSystemEntityType.link:
      await Link(candidate).delete();
    default:
      throw FileSystemException(
        'refusing to delete a non-file Zcash persistence path',
        candidate,
      );
  }
}
