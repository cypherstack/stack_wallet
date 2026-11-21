import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grin_native/grin_native.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/wallets/wallet/supporting/grin/grin_tx_mapping.dart';

import '../support/grin_fakes.dart';

const own = 'grin1own';

List<TransactionV2> map(
  List<GrinTxLogEntry> entries, {
  Map<String, int?> stored = const {},
  int chainHeight = 1000,
}) => mapGrinTransactions(
  entries: entries,
  walletId: 'w',
  ownAddress: own,
  storedHeights: stored,
  chainHeight: chainHeight,
  fractionDigits: 9,
);

Map<String, dynamic> od(TransactionV2 tx) =>
    jsonDecode(tx.otherData!) as Map<String, dynamic>;

String label(TransactionV2 tx, {int height = 1000}) => tx.statusLabel(
  currentChainHeight: height,
  minConfirms: 10,
  minCoinbaseConfirms: 1440,
);

void main() {
  test('a self-send becomes one sentToSelf row', () {
    final txs = map([
      entryOf(id: 1, debited: 1000, credited: 400, fee: 10, counterparty: own),
      entryOf(
        id: 2,
        type: GrinTxType.txReceived,
        state: GrinSlateState.s2,
        credited: 590,
        fee: null,
        counterparty: own,
      ),
    ]);
    expect(txs, hasLength(1));
    final tx = txs.single;
    expect(tx.txid, 'slate-1');
    expect(tx.type, TransactionType.sentToSelf);
    expect(od(tx)[TxV2OdKeys.grinLogIds], [1, 2]);
    expect(tx.getFee(fractionDigits: 9).raw, BigInt.from(10));
    expect(
      tx.outputs.where((o) => !o.walletOwns),
      isEmpty,
      reason: 'nothing leaves the wallet but the fee',
    );
  });

  test('an outgoing send has a counterparty output and its fee', () {
    final tx = map([
      entryOf(id: 3, debited: 1000, credited: 300, fee: 50, counterparty: 'b'),
    ]).single;
    expect(tx.type, TransactionType.outgoing);
    final paid = tx.outputs.singleWhere((o) => !o.walletOwns);
    expect(paid.value, BigInt.from(650));
    expect(paid.addresses, ['b']);
    expect(
      tx.getAmountSentFromThisWallet(fractionDigits: 9, subtractFee: true).raw,
      BigInt.from(650),
    );
  });

  test('overrideFee is always set, so getFee never reduces an empty list', () {
    final txs = map([
      entryOf(
        id: 4,
        slateId: null,
        type: GrinTxType.txReceived,
        state: null,
        credited: 0,
        fee: null,
      ),
      entryOf(id: 5, slateId: 's5', debited: 0, credited: 0, fee: null),
    ]);
    for (final tx in txs) {
      expect(od(tx)[TxV2OdKeys.overrideFee], isNotNull);
      expect(tx.getFee(fractionDigits: 9).raw, BigInt.zero);
    }
  });

  test('a coinbase uses the coinbase maturity', () {
    final tx = map([
      entryOf(
        id: 6,
        slateId: null,
        type: GrinTxType.confirmedCoinbase,
        state: null,
        confirmed: true,
        confirmedHeight: 500,
        credited: 60,
        fee: null,
      ),
    ]).single;
    expect(tx.txid, 'grin_cb_6');
    expect(tx.isCoinbase(), isTrue);
    expect(tx.isConfirmed(600, 10, 1440), isFalse);
    expect(tx.isConfirmed(1940, 10, 1440), isTrue);
    expect(label(tx, height: 600), startsWith('Receiving'));
  });

  test('heights: null until confirmed, then sticky, never the lookup hint', () {
    final unconfirmed = map([entryOf(id: 7, debited: 10)]).single;
    expect(unconfirmed.height, isNull);

    final reported = map([
      entryOf(id: 7, debited: 10, confirmed: true, confirmedHeight: 900),
    ]).single;
    expect(reported.height, 900);

    // The library stops reporting a height once the outputs are spent.
    final kept = map(
      [entryOf(id: 7, debited: 10, confirmed: true)],
      stored: {'slate-1': 900},
    ).single;
    expect(kept.height, 900);

    final firstSeen = map([
      entryOf(id: 7, debited: 10, confirmed: true),
    ], chainHeight: 1234).single;
    expect(firstSeen.height, 1234, reason: 'kernelLookupMinHeight is 1');

    final cancelled = map([
      entryOf(
        id: 7,
        type: GrinTxType.txSentCancelled,
        confirmed: true,
        confirmedHeight: 900,
      ),
    ]).single;
    expect(cancelled.height, isNull);
  });

  group('status labels', () {
    test('restored funds', () {
      final tx = map([
        entryOf(
          id: 1,
          slateId: null,
          type: GrinTxType.txReceived,
          state: null,
          credited: 5,
          confirmed: true,
          confirmedHeight: 10,
        ),
      ]).single;
      expect(tx.txid, 'grin_log_1');
      expect(label(tx), 'Restored funds');
    });

    test('cancelled and reverted', () {
      expect(
        label(map([entryOf(id: 1, type: GrinTxType.txSentCancelled)]).single),
        'Cancelled',
      );
      expect(
        label(
          map([
            entryOf(id: 1, type: GrinTxType.txReceivedCancelled, credited: 5),
          ]).single,
        ),
        'Cancelled',
      );
      expect(
        label(
          map([entryOf(id: 1, type: GrinTxType.txReverted, credited: 5)])
              .single,
        ),
        'Reverted',
      );
    });

    test('a self-send with one half cancelled is not cancelled yet', () {
      GrinTxLogEntry received(GrinTxType type) => entryOf(
        id: 2,
        type: type,
        state: GrinSlateState.s2,
        credited: 590,
        fee: null,
        counterparty: own,
      );
      final sent = entryOf(
        id: 1,
        type: GrinTxType.txSentCancelled,
        debited: 1000,
        credited: 400,
        counterparty: own,
      );
      final half = map([sent, received(GrinTxType.txReceived)]).single;
      expect(od(half)[TxV2OdKeys.isCancelled], isFalse);
      expect(label(half), isNot('Cancelled'));
      final both = map([sent, received(GrinTxType.txReceivedCancelled)]).single;
      expect(od(both)[TxV2OdKeys.isCancelled], isTrue);
      expect(label(both), 'Cancelled');
    });

    test('confirmed', () {
      expect(
        label(
          map([
            entryOf(id: 1, debited: 9, confirmed: true, confirmedHeight: 900),
          ]).single,
        ),
        'Sent',
      );
      expect(
        label(
          map([
            entryOf(
              id: 1,
              type: GrinTxType.txReceived,
              state: GrinSlateState.s2,
              credited: 9,
              confirmed: true,
              confirmedHeight: 900,
            ),
          ]).single,
        ),
        'Received',
      );
    });

    test('waiting for the other party', () {
      expect(
        label(map([entryOf(id: 1, debited: 9)]).single),
        'Sending (waiting for response)',
      );
      expect(
        label(
          map([
            entryOf(
              id: 1,
              type: GrinTxType.txReceived,
              state: GrinSlateState.s2,
              credited: 9,
            ),
          ]).single,
        ),
        'Receiving (waiting for sender to finalize)',
      );
      expect(
        label(
          map([
            entryOf(
              id: 1,
              type: GrinTxType.txReceived,
              state: GrinSlateState.i1,
              credited: 9,
            ),
          ]).single,
        ),
        'Invoice issued (waiting for payer)',
      );
      expect(
        label(
          map([entryOf(id: 1, state: GrinSlateState.i2, debited: 9)]).single,
        ),
        'Paying invoice (waiting for invoicer)',
      );
    });

    test('otherwise the confirmation count', () {
      expect(
        label(
          map([
            entryOf(
              id: 1,
              state: GrinSlateState.s3,
              debited: 9,
              confirmed: true,
              confirmedHeight: 995,
            ),
          ]).single,
        ),
        'Sending (6/10)',
      );
      expect(
        label(
          map([
            entryOf(
              id: 1,
              type: GrinTxType.txReceived,
              state: GrinSlateState.s2,
              credited: 9,
              confirmed: true,
              confirmedHeight: 995,
            ),
          ]).single,
        ),
        'Receiving (6/10)',
      );
    });
  });
}
