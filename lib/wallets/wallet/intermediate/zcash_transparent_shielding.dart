import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:mutex/mutex.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../../utilities/flutter_secure_storage_interface.dart';
import 'zcash_wallet_state.dart';

enum ZcashShieldingBroadcastState {
  prepared,
  submitting,
  acknowledged,
  indeterminate,
  confirmed,
}

final class ZcashTransparentShieldingRecord {
  ZcashTransparentShieldingRecord._({
    required this.transactionHex,
    required this.txid,
    required Set<String> selectedOutpoints,
    required this.destinationAddress,
    required this.shieldedZatoshis,
    required this.feeZatoshis,
    required this.createdHeight,
    required this.broadcastState,
    this.confirmedHeight,
    this.confirmedBlockHash,
  }) : selectedOutpoints = Set.unmodifiable(selectedOutpoints) {
    _validate();
  }

  static const version = 1;

  final String transactionHex;
  final String txid;
  final Set<String> selectedOutpoints;
  final String destinationAddress;
  final int shieldedZatoshis;
  final int feeZatoshis;
  final int createdHeight;
  final ZcashShieldingBroadcastState broadcastState;
  final int? confirmedHeight;
  final String? confirmedBlockHash;

  Map<String, Object?> toJson() => {
    'version': version,
    'transaction': transactionHex,
    'txid': txid,
    'selected_outpoints': selectedOutpoints.toList(growable: false)..sort(),
    'destination_address': destinationAddress,
    'shielded_zatoshis': shieldedZatoshis,
    'fee_zatoshis': feeZatoshis,
    'created_height': createdHeight,
    'broadcast_state': broadcastState.name,
    if (confirmedHeight != null) 'confirmed_height': confirmedHeight,
    if (confirmedBlockHash != null) 'confirmed_block_hash': confirmedBlockHash,
  };

  factory ZcashTransparentShieldingRecord.fromJson(Map<String, Object?> json) {
    if (json['version'] != version || json['selected_outpoints'] is! List) {
      throw const ZcashStatePersistenceException(
        'transparent shielding record is malformed',
      );
    }
    final stateName = json['broadcast_state'];
    final states = ZcashShieldingBroadcastState.values.where(
      (state) => state.name == stateName,
    );
    if (states.length != 1) {
      throw const ZcashStatePersistenceException(
        'transparent shielding broadcast state is unknown',
      );
    }
    return ZcashTransparentShieldingRecord._(
      transactionHex: json['transaction'] as String,
      txid: json['txid'] as String,
      selectedOutpoints: (json['selected_outpoints'] as List)
          .cast<String>()
          .toSet(),
      destinationAddress: json['destination_address'] as String,
      shieldedZatoshis: json['shielded_zatoshis'] as int,
      feeZatoshis: json['fee_zatoshis'] as int,
      createdHeight: json['created_height'] as int,
      broadcastState: states.single,
      confirmedHeight: json['confirmed_height'] as int?,
      confirmedBlockHash: json['confirmed_block_hash'] as String?,
    );
  }

  ZcashTransparentShieldingRecord copyWith({
    ZcashShieldingBroadcastState? broadcastState,
    int? confirmedHeight,
    String? confirmedBlockHash,
  }) => ZcashTransparentShieldingRecord._(
    transactionHex: transactionHex,
    txid: txid,
    selectedOutpoints: selectedOutpoints,
    destinationAddress: destinationAddress,
    shieldedZatoshis: shieldedZatoshis,
    feeZatoshis: feeZatoshis,
    createdHeight: createdHeight,
    broadcastState: broadcastState ?? this.broadcastState,
    confirmedHeight: confirmedHeight ?? this.confirmedHeight,
    confirmedBlockHash: confirmedBlockHash ?? this.confirmedBlockHash,
  );

  void _validate() {
    final paired = (confirmedHeight == null) == (confirmedBlockHash == null);
    if (!_isEvenHex(transactionHex) ||
        !_isHash(txid) ||
        selectedOutpoints.isEmpty ||
        selectedOutpoints.any((outpoint) => !_isOutpoint(outpoint)) ||
        destinationAddress.isEmpty ||
        shieldedZatoshis <= 0 ||
        feeZatoshis < 0 ||
        createdHeight < 0 ||
        !paired ||
        confirmedHeight != null && confirmedHeight! < createdHeight ||
        confirmedBlockHash != null && !_isHash(confirmedBlockHash!)) {
      throw const ZcashStatePersistenceException(
        'transparent shielding record is malformed',
      );
    }
  }
}

final class ZcashTransparentShieldingState {
  ZcashTransparentShieldingState();

  static const version = 1;
  final List<ZcashTransparentShieldingRecord> _records = [];

  List<ZcashTransparentShieldingRecord> get records =>
      List.unmodifiable(_records);

  Set<String> get reservedOutpoints => Set.unmodifiable({
    for (final record in _records)
      if (record.broadcastState != ZcashShieldingBroadcastState.confirmed)
        ...record.selectedOutpoints,
  });

  void addPrepared(
    zcash.ShieldingPreparedSend prepared, {
    required String destinationAddress,
    required int createdHeight,
  }) {
    final selection = prepared.selection;
    if (prepared.destination != zcash.ShieldingDestination.ironwood ||
        prepared.shieldedZatoshis != selection.amountZatoshis ||
        prepared.feeZatoshis != selection.feeZatoshis ||
        selection.changeZatoshis != 0 ||
        selection.inputZatoshis !=
            prepared.shieldedZatoshis +
                prepared.feeZatoshis +
                selection.changeZatoshis) {
      throw StateError(
        'transparent shielding build does not conserve its exact values',
      );
    }
    final outpoints = {for (final coin in selection.coins) coin.outpoint};
    if (_records.any(
          (record) => record.txid.toLowerCase() == prepared.txid.toLowerCase(),
        ) ||
        outpoints.any(reservedOutpoints.contains)) {
      throw StateError('transparent shielding inputs are already reserved');
    }
    _records.add(
      ZcashTransparentShieldingRecord._(
        transactionHex: prepared.transactionHex,
        txid: prepared.txid,
        selectedOutpoints: outpoints,
        destinationAddress: destinationAddress,
        shieldedZatoshis: prepared.shieldedZatoshis,
        feeZatoshis: prepared.feeZatoshis,
        createdHeight: createdHeight,
        broadcastState: ZcashShieldingBroadcastState.prepared,
      ),
    );
  }

  ZcashTransparentShieldingRecord requireBroadcastable(
    zcash.ShieldingPreparedSend prepared,
  ) {
    final record = _record(prepared.txid);
    final selected = {
      for (final coin in prepared.selection.coins) coin.outpoint,
    };
    if (record.transactionHex != prepared.transactionHex ||
        record.selectedOutpoints.length != selected.length ||
        !record.selectedOutpoints.containsAll(selected) ||
        record.shieldedZatoshis != prepared.shieldedZatoshis ||
        record.feeZatoshis != prepared.feeZatoshis) {
      throw StateError(
        'persisted shielding reservation does not match the build',
      );
    }
    if (record.broadcastState != ZcashShieldingBroadcastState.prepared &&
        record.broadcastState != ZcashShieldingBroadcastState.indeterminate) {
      throw StateError(
        'transparent shielding transaction is not broadcastable',
      );
    }
    return record;
  }

  void markSubmitting(String txid) =>
      _transition(txid, ZcashShieldingBroadcastState.submitting, const {
        ZcashShieldingBroadcastState.prepared,
        ZcashShieldingBroadcastState.indeterminate,
      });

  void markAcknowledged(String txid) => _transition(
    txid,
    ZcashShieldingBroadcastState.acknowledged,
    const {ZcashShieldingBroadcastState.submitting},
  );

  void markIndeterminate(String txid) => _transition(
    txid,
    ZcashShieldingBroadcastState.indeterminate,
    const {ZcashShieldingBroadcastState.submitting},
  );

  /// A persisted `submitting` state has no trustworthy outcome after process
  /// restart. Keep its inputs reserved and make only the exact transaction
  /// retryable; a definitive node rejection is the only event that releases it.
  void recoverInterruptedSubmissions() {
    for (var index = 0; index < _records.length; index++) {
      final record = _records[index];
      if (record.broadcastState == ZcashShieldingBroadcastState.submitting) {
        _records[index] = record.copyWith(
          broadcastState: ZcashShieldingBroadcastState.indeterminate,
        );
      }
    }
  }

  void releaseRejected(String txid) => _records.remove(_record(txid));

  void reconcile(zcash.ZcashTransparentState transparent) {
    final byOutpoint = {
      for (final output in transparent.outputs)
        '${output.utxo.txid}:${output.outputIndex}': output,
    };
    for (var index = 0; index < _records.length; index++) {
      final record = _records[index];
      if (record.broadcastState == ZcashShieldingBroadcastState.confirmed) {
        continue;
      }
      final outputs = record.selectedOutpoints
          .map((outpoint) => byOutpoint[outpoint])
          .toList();
      if (outputs.any((output) => output == null) ||
          outputs.any(
            (output) =>
                output!.spendState != zcash.ZcashTransparentSpendState.spent,
          )) {
        continue;
      }
      final spent = outputs.cast<zcash.ZcashTransparentOutput>();
      final protocolTxid = zcash
          .reverseTxidByteOrder(record.txid)
          .toLowerCase();
      if (spent.any(
        (output) => output.spendingProtocolTxid?.toLowerCase() != protocolTxid,
      )) {
        continue;
      }
      final heights = spent.map((output) => output.spentHeight).toSet();
      final hashes = spent.map((output) => output.spentBlockHash).toSet();
      if (heights.length != 1 ||
          heights.single == null ||
          hashes.length != 1 ||
          hashes.single == null) {
        continue;
      }
      _records[index] = record.copyWith(
        broadcastState: ZcashShieldingBroadcastState.confirmed,
        confirmedHeight: heights.single,
        confirmedBlockHash: hashes.single,
      );
    }
  }

  Map<String, Object?> toJson() => {
    'version': version,
    'records': [for (final record in _records) record.toJson()],
  };

  factory ZcashTransparentShieldingState.fromJson(Map<String, Object?> json) {
    if (json['version'] != version || json['records'] is! List) {
      throw const ZcashStatePersistenceException(
        'transparent shielding state is malformed',
      );
    }
    final state = ZcashTransparentShieldingState();
    for (final entry in json['records'] as List) {
      if (entry is! Map) {
        throw const ZcashStatePersistenceException(
          'transparent shielding state record is malformed',
        );
      }
      final record = ZcashTransparentShieldingRecord.fromJson(
        entry.cast<String, Object?>(),
      );
      if (state._records.any((existing) => existing.txid == record.txid) ||
          record.selectedOutpoints.any(state.reservedOutpoints.contains)) {
        throw const ZcashStatePersistenceException(
          'transparent shielding state contains overlapping reservations',
        );
      }
      state._records.add(record);
    }
    return state;
  }

  ZcashTransparentShieldingRecord _record(String txid) => _records.singleWhere(
    (record) => record.txid.toLowerCase() == txid.toLowerCase(),
    orElse: () => throw StateError('unknown transparent shielding transaction'),
  );

  void _transition(
    String txid,
    ZcashShieldingBroadcastState next,
    Set<ZcashShieldingBroadcastState> allowed,
  ) {
    final index = _records.indexOf(_record(txid));
    if (!allowed.contains(_records[index].broadcastState)) {
      throw StateError('invalid transparent shielding broadcast transition');
    }
    _records[index] = _records[index].copyWith(broadcastState: next);
  }
}

abstract interface class ZcashTransparentShieldingStore {
  Future<ZcashTransparentShieldingState> load();
  Future<void> save(ZcashTransparentShieldingState state);
  Future<T> update<T>(T Function(ZcashTransparentShieldingState state) mutate);
}

final class ZcashEncryptedTransparentShieldingStore
    implements ZcashTransparentShieldingStore {
  ZcashEncryptedTransparentShieldingStore({
    required this.path,
    required this.walletId,
    required this.network,
    required this.accountFingerprint,
    required this.secureStorage,
  });

  static const _envelopeVersion = 1;
  static final _cipher = AesGcm.with256bits();
  final Mutex _mutex = Mutex();
  final String path;
  final String walletId;
  final String network;
  final String accountFingerprint;
  final SecureStorageInterface secureStorage;

  String get _keyName => 'zcash_transparent_shielding_key_v1_$walletId';
  List<int> get _aad => utf8.encode(
    'stack-wallet-zcash-transparent-shielding|$_envelopeVersion|$walletId|'
    '$network|$accountFingerprint',
  );

  @override
  Future<ZcashTransparentShieldingState> load() => _mutex.protect(_load);

  Future<ZcashTransparentShieldingState> _load() async {
    await _refuseSymlink(path);
    await _refuseSymlink('$path.tmp');
    final temporary = File('$path.tmp');
    if (await temporary.exists()) await temporary.delete();
    final file = File(path);
    if (!await file.exists()) return ZcashTransparentShieldingState();
    final encodedKey = await secureStorage.read(key: _keyName);
    if (encodedKey == null) {
      throw const ZcashStatePersistenceException(
        'encrypted transparent shielding state exists but its key is missing',
      );
    }
    try {
      final envelope = (jsonDecode(await file.readAsString()) as Map)
          .cast<String, Object?>();
      if (envelope['version'] != _envelopeVersion) {
        throw const ZcashStatePersistenceException(
          'unsupported transparent shielding envelope version',
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
      if (payload['network'] != network ||
          payload['account_fingerprint'] != accountFingerprint ||
          payload['state'] is! Map) {
        throw const ZcashStatePersistenceException(
          'transparent shielding state belongs to another wallet',
        );
      }
      return ZcashTransparentShieldingState.fromJson(
        (payload['state'] as Map).cast<String, Object?>(),
      );
    } on ZcashStatePersistenceException {
      rethrow;
    } on Object catch (error) {
      throw ZcashStatePersistenceException(
        'transparent shielding state failed authentication or is corrupt: '
        '$error',
      );
    }
  }

  @override
  Future<void> save(ZcashTransparentShieldingState state) =>
      _mutex.protect(() => _save(state));

  @override
  Future<T> update<T>(
    T Function(ZcashTransparentShieldingState state) mutate,
  ) => _mutex.protect(() async {
    final state = await _load();
    final result = mutate(state);
    await _save(state);
    return result;
  });

  Future<void> _save(ZcashTransparentShieldingState state) async {
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
        'network': network,
        'account_fingerprint': accountFingerprint,
        'state': state.toJson(),
      }),
    );
    final box = await _cipher.encrypt(
      clear,
      secretKey: SecretKey(base64Decode(encodedKey)),
      nonce: _cipher.newNonce(),
      aad: _aad,
    );
    final temporary = File('$path.tmp');
    await temporary.parent.create(recursive: true);
    try {
      await temporary.writeAsString(
        jsonEncode({
          'version': _envelopeVersion,
          'nonce': base64Encode(box.nonce),
          'ciphertext': base64Encode(box.cipherText),
          'mac': base64Encode(box.mac.bytes),
        }),
        flush: true,
      );
      await temporary.rename(path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<void> _refuseSymlink(String candidate) async {
    if (await FileSystemEntity.type(candidate, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const ZcashStatePersistenceException(
        'refusing transparent shielding state through a symbolic link',
      );
    }
  }
}

bool _isHash(String value) =>
    value.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(value);

bool _isEvenHex(String value) =>
    value.isNotEmpty &&
    value.length.isEven &&
    RegExp(r'^[0-9a-fA-F]+$').hasMatch(value);

bool _isOutpoint(String value) {
  final separator = value.lastIndexOf(':');
  return separator == 64 &&
      _isHash(value.substring(0, separator)) &&
      int.tryParse(value.substring(separator + 1)) != null;
}
