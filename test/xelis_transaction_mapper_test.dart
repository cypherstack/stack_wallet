import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/wallets/wallet/impl/xelis_transaction_mapper.dart';
import 'package:stackwallet/wl_gen/interfaces/lib_xelis_interface.dart';

void main() {
  const walletAddress = 'xel:wallet';

  TransactionEntryWrapper transaction(EntryWrapper entry) =>
      TransactionEntryWrapper(
        entry,
        entryType: entry,
        hash: 'hash-${entry.runtimeType}',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1234000),
        topoheight: 42,
      );

  test('maps coinbase rewards', () {
    final result = mapXelisTransactionEntry(
      transactionEntry: transaction(const CoinbaseEntryWrapper(reward: 50)),
      walletId: 'wallet-id',
      walletAddress: walletAddress,
      fractionDigits: 8,
    );

    expect(result.type, TransactionType.incoming);
    expect(result.outputs.single.valueStringSats, '50');
    expect(result.outputs.single.walletOwns, isTrue);
    expect(result.getFee(fractionDigits: 8).raw, BigInt.zero);
  });

  test('maps incoming transfers and sent-to-self history', () {
    final result = mapXelisTransactionEntry(
      transactionEntry: transaction(
        const IncomingEntryWrapper(
          from: walletAddress,
          transfers: [
            (
              amount: 15,
              asset: 'asset-a',
              extraData: {'flag': 'public', 'data': 'memo'},
            ),
          ],
        ),
      ),
      walletId: 'wallet-id',
      walletAddress: walletAddress,
      fractionDigits: 8,
    );

    final otherData = jsonDecode(result.otherData!) as Map<String, dynamic>;
    expect(result.type, TransactionType.sentToSelf);
    expect(result.outputs.single.valueStringSats, '15');
    expect(otherData['asset_asset-a'], '15');
    expect(otherData['extraData_asset-a']['data'], 'memo');
  });

  test('maps outgoing transfers, fee, and nonce', () {
    final result = mapXelisTransactionEntry(
      transactionEntry: transaction(
        const OutgoingEntryWrapper(
          nonce: 3,
          fee: 2,
          transfers: [
            (
              destination: 'xel:recipient',
              amount: 40,
              asset: 'asset-a',
              extraData: null,
            ),
          ],
        ),
      ),
      walletId: 'wallet-id',
      walletAddress: walletAddress,
      fractionDigits: 8,
    );

    expect(result.type, TransactionType.outgoing);
    expect(result.getFee(fractionDigits: 8).raw, BigInt.from(2));
    expect(result.nonce, 3);
    expect(
      result
          .getAmountSentFromThisWallet(fractionDigits: 8, subtractFee: true)
          .raw,
      BigInt.from(40),
    );
  });

  test('maps incoming contract transfers into wallet-owned outputs', () {
    final result = mapXelisTransactionEntry(
      transactionEntry: transaction(
        const IncomingContractEntryWrapper(
          transfers: {
            'contract-a': {'asset-a': 12, 'asset-b': 34},
            'contract-b': {'asset-a': 56},
          },
        ),
      ),
      walletId: 'wallet-id',
      walletAddress: walletAddress,
      fractionDigits: 8,
    );

    expect(result.type, TransactionType.incoming);
    expect(result.outputs.map((e) => e.valueStringSats), ['12', '34', '56']);
    expect(result.outputs.every((e) => e.walletOwns), isTrue);
    expect(jsonDecode(result.otherData!)['xelisEntryType'], 'incomingContract');
  });

  test('maps outgoing blob fee and participants without dropping history', () {
    final result = mapXelisTransactionEntry(
      transactionEntry: transaction(
        const OutgoingBlobEntryWrapper(
          destinations: ['xel:one', 'xel:two'],
          fee: 17,
          nonce: 9,
          data: {'flag': 'public', 'data': 'hello'},
        ),
      ),
      walletId: 'wallet-id',
      walletAddress: walletAddress,
      fractionDigits: 8,
    );

    expect(result.type, TransactionType.outgoing);
    expect(result.getFee(fractionDigits: 8).raw, BigInt.from(17));
    expect(result.outputs.expand((e) => e.addresses), ['xel:one', 'xel:two']);
    expect(result.nonce, 9);
  });

  test('maps incoming blob as a zero-value incoming transaction', () {
    final result = mapXelisTransactionEntry(
      transactionEntry: transaction(
        const IncomingBlobEntryWrapper(
          from: 'xel:sender',
          destinations: [walletAddress],
          data: {'flag': 'private', 'data': 'payload'},
        ),
      ),
      walletId: 'wallet-id',
      walletAddress: walletAddress,
      fractionDigits: 8,
    );

    expect(result.type, TransactionType.incoming);
    expect(result.outputs.single.valueStringSats, '0');
    expect(result.outputs.single.walletOwns, isTrue);
  });

  test('maps multisig metadata and fee', () {
    final result = mapXelisTransactionEntry(
      transactionEntry: transaction(
        const MultisigEntryWrapper(
          participants: ['xel:one', 'xel:two'],
          threshold: 2,
          fee: 5,
          nonce: 6,
        ),
      ),
      walletId: 'wallet-id',
      walletAddress: walletAddress,
      fractionDigits: 8,
    );

    final otherData = jsonDecode(result.otherData!) as Map<String, dynamic>;
    expect(result.type, TransactionType.outgoing);
    expect(result.getFee(fractionDigits: 8).raw, BigInt.from(5));
    expect(result.nonce, 6);
    expect(otherData['threshold'], 2);
    expect(result.outputs, hasLength(2));
  });

  test('maps contract deposits and received transfers', () {
    final result = mapXelisTransactionEntry(
      transactionEntry: transaction(
        const InvokeContractEntryWrapper(
          contract: 'contract-a',
          deposits: {'asset-a': 20},
          received: {
            'contract-a': {'asset-b': 30},
          },
          chunkId: 7,
          fee: 3,
          maxGas: 50,
          nonce: 8,
        ),
      ),
      walletId: 'wallet-id',
      walletAddress: walletAddress,
      fractionDigits: 8,
    );

    final otherData = jsonDecode(result.otherData!) as Map<String, dynamic>;
    expect(result.type, TransactionType.outgoing);
    expect(result.getFee(fractionDigits: 8).raw, BigInt.from(3));
    expect(result.inputs.map((e) => e.valueStringSats), ['3', '20']);
    expect(result.outputs.map((e) => e.valueStringSats), ['20', '30']);
    expect(result.outputs.map((e) => e.walletOwns), [false, true]);
    expect(otherData['chunkId'], 7);
    expect(otherData['maxGas'], 50);
  });

  test('maps deploy invocation deposits', () {
    final result = mapXelisTransactionEntry(
      transactionEntry: transaction(
        const DeployContractEntryWrapper(
          fee: 4,
          nonce: 10,
          invoke: DeployInvokeWrapper(maxGas: 100, deposits: {'asset-a': 25}),
        ),
      ),
      walletId: 'wallet-id',
      walletAddress: walletAddress,
      fractionDigits: 8,
    );

    expect(result.type, TransactionType.outgoing);
    expect(result.getFee(fractionDigits: 8).raw, BigInt.from(4));
    expect(result.inputs.map((e) => e.valueStringSats), ['4', '25']);
    expect(result.outputs.single.addresses, ['contract-deployment']);
    expect(result.nonce, 10);
  });

  test('maps deploys without an invocation', () {
    final result = mapXelisTransactionEntry(
      transactionEntry: transaction(
        const DeployContractEntryWrapper(fee: 4, nonce: 10, invoke: null),
      ),
      walletId: 'wallet-id',
      walletAddress: walletAddress,
      fractionDigits: 8,
    );

    expect(result.type, TransactionType.outgoing);
    expect(result.inputs.single.valueStringSats, '4');
    expect(result.outputs, isEmpty);
    expect(result.nonce, 10);
  });

  test('preserves future unknown entries instead of dropping them', () {
    final result = mapXelisTransactionEntry(
      transactionEntry: transaction(
        const UnknownEntryWrapper(
          entryType: 'futureEntry',
          data: {'value': 123},
        ),
      ),
      walletId: 'wallet-id',
      walletAddress: walletAddress,
      fractionDigits: 8,
    );

    expect(result.type, TransactionType.unknown);
    final otherData = jsonDecode(result.otherData!) as Map<String, dynamic>;
    expect(otherData['xelisEntryType'], 'futureEntry');
    expect(otherData['data'], {'value': 123});
    expect(otherData['overrideFee'], isA<String>());
  });

  test('accounts for both burn amount and fee', () {
    final result = mapXelisTransactionEntry(
      transactionEntry: transaction(
        const BurnEntryWrapper(
          amount: 100,
          fee: 7,
          asset: 'asset-a',
          nonce: 11,
        ),
      ),
      walletId: 'wallet-id',
      walletAddress: walletAddress,
      fractionDigits: 8,
    );

    expect(result.getFee(fractionDigits: 8).raw, BigInt.from(7));
    expect(result.nonce, 11);
    expect(
      result
          .getAmountSentFromThisWallet(fractionDigits: 8, subtractFee: true)
          .raw,
      BigInt.from(100),
    );
  });
}
