import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../../utilities/flutter_secure_storage_interface.dart';

class ZcashStatePersistenceException implements Exception {
  const ZcashStatePersistenceException(this.message);

  final String message;

  @override
  String toString() => 'ZcashStatePersistenceException: $message';
}

class ZcashPersistedWalletState {
  const ZcashPersistedWalletState({
    required this.syncState,
    required this.observedChainHeight,
  });

  static const version = 1;

  final zcash.ZcashWalletSyncState syncState;
  final int observedChainHeight;

  Map<String, Object?> toJson() => {
    'version': version,
    'observed_chain_height': observedChainHeight,
    'sync_state': syncState.toJson(),
  };

  factory ZcashPersistedWalletState.fromJson(Map<String, Object?> json) {
    if (json['version'] != version) {
      throw const ZcashStatePersistenceException(
        'unsupported wallet-state payload version',
      );
    }
    final height = json['observed_chain_height'];
    final state = json['sync_state'];
    if (height is! num || state is! Map) {
      throw const ZcashStatePersistenceException(
        'wallet-state payload is malformed',
      );
    }
    return ZcashPersistedWalletState(
      syncState: zcash.ZcashWalletSyncState.fromJson(
        state.cast<String, Object?>(),
      ),
      observedChainHeight: height.toInt(),
    );
  }
}

class ZcashEncryptedWalletStateStore {
  ZcashEncryptedWalletStateStore({
    required this.path,
    required this.walletId,
    required this.network,
    required this.accountFingerprint,
    required this.secureStorage,
  });

  static const envelopeVersion = 1;
  static final _cipher = AesGcm.with256bits();

  final String path;
  final String walletId;
  final String network;
  final String accountFingerprint;
  final SecureStorageInterface secureStorage;

  String get _keyName => 'zcash_wallet_state_key_v1_$walletId';

  List<int> get _aad => utf8.encode(
    'stack-wallet-zcash-state|$envelopeVersion|$walletId|$network|'
    '$accountFingerprint',
  );

  Future<ZcashPersistedWalletState?> load() async {
    await _refuseSymlink(path);
    await _removeInterruptedWrite();
    final file = File(path);
    if (!await file.exists()) return null;
    final encodedKey = await secureStorage.read(key: _keyName);
    if (encodedKey == null) {
      throw const ZcashStatePersistenceException(
        'encrypted wallet state exists but its key is missing',
      );
    }
    try {
      final envelope = (jsonDecode(await file.readAsString()) as Map)
          .cast<String, Object?>();
      if (envelope['version'] != envelopeVersion) {
        throw const ZcashStatePersistenceException(
          'unsupported encrypted wallet-state envelope version',
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
      final restored = ZcashPersistedWalletState.fromJson(payload);
      if (restored.syncState.accountFingerprint != accountFingerprint) {
        throw const ZcashStatePersistenceException(
          'wallet state belongs to a different account',
        );
      }
      _validateNetwork(restored.syncState);
      return restored;
    } on ZcashStatePersistenceException {
      rethrow;
    } on Object catch (error) {
      throw ZcashStatePersistenceException(
        'wallet state failed authentication or is corrupt: $error',
      );
    }
  }

  Future<void> save(ZcashPersistedWalletState state) async {
    await _refuseSymlink(path);
    await _refuseSymlink('$path.tmp');
    if (state.syncState.accountFingerprint != accountFingerprint) {
      throw const ZcashStatePersistenceException(
        'refusing to save state for a different account',
      );
    }
    _validateNetwork(state.syncState);
    var encodedKey = await secureStorage.read(key: _keyName);
    if (encodedKey == null) {
      encodedKey = base64Encode(
        await (await _cipher.newSecretKey()).extractBytes(),
      );
      await secureStorage.write(key: _keyName, value: encodedKey);
    }
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(state.toJson())),
      secretKey: SecretKey(base64Decode(encodedKey)),
      nonce: _cipher.newNonce(),
      aad: _aad,
    );
    final envelope = jsonEncode({
      'version': envelopeVersion,
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

  /// Removes the local chain checkpoint so the next open starts from the
  /// validated wallet birthday. The per-wallet encryption key is retained so
  /// a newly scanned checkpoint can be authenticated with the same wallet
  /// identity.
  Future<void> reset() async {
    final temporaryPath = '$path.tmp';
    await _refuseSymlink(path);
    await _refuseSymlink(temporaryPath);

    final file = File(path);
    final temporary = File(temporaryPath);
    if (await file.exists()) await file.delete();
    if (await temporary.exists()) await temporary.delete();
  }

  Future<void> _removeInterruptedWrite() async {
    final temporaryPath = '$path.tmp';
    await _refuseSymlink(temporaryPath);
    final temporary = File(temporaryPath);
    if (await temporary.exists()) await temporary.delete();
  }

  Future<void> _refuseSymlink(String candidate) async {
    if (await FileSystemEntity.type(candidate, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const ZcashStatePersistenceException(
        'refusing to access wallet state through a symbolic link',
      );
    }
  }

  void _validateNetwork(zcash.ZcashWalletSyncState state) {
    final expected = zcash.ZcashAddressNetwork.fromJson(network);
    if (state.network != expected) {
      throw const ZcashStatePersistenceException(
        'wallet state belongs to a different consensus network',
      );
    }
  }
}
