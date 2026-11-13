import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../../utilities/flutter_secure_storage_interface.dart';
import 'zcash_wallet_state.dart';

abstract interface class ZcashPendingSendStore {
  Future<zcash.IronwoodPendingSendState> load();

  Future<void> save(zcash.IronwoodPendingSendState state);
}

/// An account-bound store kept separate from the sync checkpoint.
///
/// Sync checkpoints and send reservations have different commit points. A
/// separate authenticated file prevents a later sync save from erasing a
/// reservation that was durably recorded immediately before broadcast.
final class ZcashEncryptedPendingSendStore implements ZcashPendingSendStore {
  ZcashEncryptedPendingSendStore({
    required this.path,
    required this.walletId,
    required this.network,
    required this.accountFingerprint,
    required this.secureStorage,
  });

  static const _envelopeVersion = 1;
  static const _payloadVersion = 1;
  static final _cipher = AesGcm.with256bits();

  final String path;
  final String walletId;
  final String network;
  final String accountFingerprint;
  final SecureStorageInterface secureStorage;

  String get _keyName => 'zcash_pending_send_key_v1_$walletId';

  List<int> get _aad => utf8.encode(
    'stack-wallet-zcash-pending|$_envelopeVersion|$walletId|$network|'
    '$accountFingerprint',
  );

  @override
  Future<zcash.IronwoodPendingSendState> load() async {
    await _refuseSymlink(path);
    await _removeInterruptedWrite();
    final file = File(path);
    if (!await file.exists()) return zcash.IronwoodPendingSendState();
    final encodedKey = await secureStorage.read(key: _keyName);
    if (encodedKey == null) {
      throw const ZcashStatePersistenceException(
        'encrypted pending-send state exists but its key is missing',
      );
    }
    try {
      final envelope = (jsonDecode(await file.readAsString()) as Map)
          .cast<String, Object?>();
      if (envelope['version'] != _envelopeVersion) {
        throw const ZcashStatePersistenceException(
          'unsupported encrypted pending-send envelope version',
        );
      }
      final clear = await _cipher.decrypt(
        SecretBox(
          base64Decode(envelope['ciphertext'] as String),
          nonce: base64Decode(envelope['nonce'] as String),
          mac: Mac(base64Decode(envelope['mac'] as String)),
        ),
        secretKey: SecretKey(base64Decode(encodedKey)),
        aad: _aad,
      );
      final payload = (jsonDecode(utf8.decode(clear)) as Map)
          .cast<String, Object?>();
      if (payload['version'] != _payloadVersion ||
          payload['network'] != network ||
          payload['account_fingerprint'] != accountFingerprint ||
          payload['pending'] is! Map) {
        throw const ZcashStatePersistenceException(
          'pending-send payload belongs to another wallet or is malformed',
        );
      }
      return zcash.IronwoodPendingSendState.fromJson(
        (payload['pending'] as Map).cast<String, Object?>(),
      );
    } on ZcashStatePersistenceException {
      rethrow;
    } on Object catch (error) {
      throw ZcashStatePersistenceException(
        'pending-send state failed authentication or is corrupt: $error',
      );
    }
  }

  @override
  Future<void> save(zcash.IronwoodPendingSendState state) async {
    await _refuseSymlink(path);
    await _refuseSymlink('$path.tmp');
    var encodedKey = await secureStorage.read(key: _keyName);
    if (encodedKey == null) {
      encodedKey = base64Encode(
        await (await _cipher.newSecretKey()).extractBytes(),
      );
      await secureStorage.write(key: _keyName, value: encodedKey);
    }
    final clear = utf8.encode(
      jsonEncode({
        'version': _payloadVersion,
        'network': network,
        'account_fingerprint': accountFingerprint,
        'pending': state.toJson(),
      }),
    );
    final box = await _cipher.encrypt(
      clear,
      secretKey: SecretKey(base64Decode(encodedKey)),
      nonce: _cipher.newNonce(),
      aad: _aad,
    );
    final envelope = jsonEncode({
      'version': _envelopeVersion,
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
    final temporary = File('$path.tmp');
    await temporary.parent.create(recursive: true);
    try {
      await temporary.writeAsString(envelope, flush: true);
      await temporary.rename(path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<void> _removeInterruptedWrite() async {
    await _refuseSymlink('$path.tmp');
    final temporary = File('$path.tmp');
    if (await temporary.exists()) await temporary.delete();
  }

  Future<void> _refuseSymlink(String candidate) async {
    if (await FileSystemEntity.type(candidate, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const ZcashStatePersistenceException(
        'refusing to access pending-send state through a symbolic link',
      );
    }
  }
}
