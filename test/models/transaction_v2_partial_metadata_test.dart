import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';

void main() {
  test('partial metadata exposes only known wallet facts', () {
    final transaction = _transaction({
      TxV2OdKeys.metadataStatus: TxV2OdKeys.metadataStatusPartial,
      TxV2OdKeys.missingMetadata: ['timestamp', 'fee', 'memo'],
      TxV2OdKeys.walletNetAmountRaw: '-123',
    });

    expect(transaction.hasPartialMetadata, isTrue);
    expect(transaction.isMetadataMissing('fee'), isTrue);
    expect(transaction.isMetadataMissing('blockHash'), isFalse);
    expect(transaction.walletNetAmountRaw, BigInt.from(-123));
  });

  test('invalid or absent wallet net amounts remain unknown', () {
    expect(
      _transaction({TxV2OdKeys.walletNetAmountRaw: 'not-an-integer'})
          .walletNetAmountRaw,
      isNull,
    );
    expect(_transaction(null).walletNetAmountRaw, isNull);
  });

  test('metadata collections are immutable', () {
    final transaction = _transaction({
      TxV2OdKeys.missingMetadata: ['fee', 42],
      TxV2OdKeys.assetPools: ['sapling', 'ironwood', 42],
    });

    expect(transaction.missingMetadata, ['fee']);
    expect(transaction.assetPools, ['sapling', 'ironwood']);
    expect(
      () => transaction.missingMetadata.add('memo'),
      throwsUnsupportedError,
    );
    expect(() => transaction.assetPools.add('orchard'), throwsUnsupportedError);
  });
}

TransactionV2 _transaction(Map<String, Object?>? metadata) => TransactionV2(
  walletId: 'wallet',
  blockHash: null,
  hash: 'hash',
  txid: 'txid',
  timestamp: 0,
  height: 10,
  inputs: const [],
  outputs: const [],
  version: -1,
  type: TransactionType.outgoing,
  subType: TransactionSubType.none,
  otherData: metadata == null ? null : jsonEncode(metadata),
);
