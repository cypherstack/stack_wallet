import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';

String _label({
  required String coinKey,
  required TransactionType type,
  required int? messages,
  String? note,
  int? height,
  bool cancelled = false,
}) {
  final tx = TransactionV2(
    walletId: 'wallet',
    blockHash: null,
    hash: 'hash',
    txid: 'txid',
    timestamp: 1,
    height: height,
    inputs: const [],
    outputs: const [],
    version: 1,
    type: type,
    subType: TransactionSubType.none,
    otherData: jsonEncode({
      coinKey: true,
      TxV2OdKeys.slateId: 'slate',
      TxV2OdKeys.numberOfMessages: messages,
      TxV2OdKeys.onChainNote: note,
      TxV2OdKeys.isCancelled: cancelled,
    }),
  );
  return tx.statusLabel(
    currentChainHeight: 100,
    minConfirms: 10,
    minCoinbaseConfirms: 10,
  );
}

void main() {
  for (final coinKey in [
    TxV2OdKeys.isEpiccashTransaction,
    TxV2OdKeys.isMimblewimblecoinTransaction,
  ]) {
    group(coinKey, () {
      // A note changes the text of a message entry and never the number of
      // entries, so every label has to be the same with and without one.
      for (final note in [null, 'thanks for lunch']) {
        final withNote = note == null ? 'without a note' : 'with a note';

        test('a send $withNote waits for the receiver until finalized', () {
          expect(
            _label(
              coinKey: coinKey,
              type: TransactionType.outgoing,
              messages: 1,
              note: note,
            ),
            'Sending (waiting for receiver)',
          );
        });

        test('a finalized send $withNote waits for confirmations', () {
          expect(
            _label(
              coinKey: coinKey,
              type: TransactionType.outgoing,
              messages: 2,
              note: note,
            ),
            'Sending (waiting for confirmations)',
          );
        });

        test('a signed receive $withNote waits for the sender', () {
          expect(
            _label(
              coinKey: coinKey,
              type: TransactionType.incoming,
              messages: 2,
              note: note,
            ),
            'Receiving (waiting for sender)',
          );
        });
      }

      test('confirmed transactions say so', () {
        expect(
          _label(
            coinKey: coinKey,
            type: TransactionType.outgoing,
            messages: 2,
            height: 50,
          ),
          'Sent (confirmed)',
        );
        expect(
          _label(
            coinKey: coinKey,
            type: TransactionType.incoming,
            messages: 2,
            height: 50,
          ),
          'Received',
        );
      });

      test('a cancelled send says so', () {
        expect(
          _label(
            coinKey: coinKey,
            type: TransactionType.outgoing,
            messages: 1,
            cancelled: true,
          ),
          'Cancelled',
        );
      });
    });
  }
}
