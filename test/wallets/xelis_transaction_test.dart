import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/wallets/models/xelis_transaction.dart';
import 'package:stackwallet/wl_gen/interfaces/lib_xelis_interface.dart';

void main() {
  const own = 'own-address';
  const xel = 'native-asset';
  project(EntryWrapper entry, {BigInt? height}) => projectXelisTransaction(
    tx: TransactionEntryWrapper(
      Object(),
      entryType: entry,
      hash: 'hash',
      timestamp: DateTime.fromMillisecondsSinceEpoch(123000),
      topoheight: height,
    ),
    ownAddress: own,
    walletId: 'wallet',
    xelisAsset: xel,
    fractionDigits: 8,
  )!;

  test('burn keeps the XEL amount and its separate fee', () {
    final tx = project(
      BurnEntryWrapper(
        amount: BigInt.from(400),
        fee: BigInt.from(7),
        asset: xel,
      ),
      height: BigInt.from(9),
    );
    expect(tx.height, 9);
    expect(tx.getFee(fractionDigits: 8).raw, BigInt.from(7));
    expect(
      tx.getAmountSentFromThisWallet(fractionDigits: 8, subtractFee: true).raw,
      BigInt.from(400),
    );
  });

  test(
    'non-XEL transfers record only their XEL fee without empty-list errors',
    () {
      final tx = project(
        OutgoingEntryWrapper(
          nonce: BigInt.one,
          fee: BigInt.from(7),
          transfers: [
            (
              destination: 'other',
              amount: BigInt.from(999),
              asset: 'token',
              extraData: null,
            ),
          ],
        ),
      );
      expect(tx.height, isNull);
      expect(
        tx.nonce,
        isNull,
      ); // Xelis preserves its u64 separately as a string.
      expect(tx.outputs, isEmpty);
      expect(tx.getFee(fractionDigits: 8).raw, BigInt.from(7));
      expect(
        tx
            .getAmountSentFromThisWallet(fractionDigits: 8, subtractFee: true)
            .raw,
        BigInt.zero,
      );
    },
  );

  test('self transfer displays only the net fee as the wallet debit', () {
    final tx = project(
      OutgoingEntryWrapper(
        nonce: BigInt.one,
        fee: BigInt.from(7),
        transfers: [
          (
            destination: own,
            amount: BigInt.from(400),
            asset: xel,
            extraData: null,
          ),
        ],
      ),
    );
    expect(tx.type, TransactionType.sentToSelf);
    expect(
      tx.getAmountSentFromThisWallet(fractionDigits: 8, subtractFee: false).raw,
      BigInt.from(7),
    );
    expect(
      tx.getAmountReceivedInThisWallet(fractionDigits: 8).raw,
      BigInt.from(400),
    );
  });

  test('contract receipt offsets the outgoing XEL debit', () {
    final tx = project(
      XelisActionEntryWrapper(
        kind: 'invoke_contract',
        spent: BigInt.from(500),
        received: BigInt.from(150),
        fee: BigInt.from(7),
      ),
    );
    expect(
      tx.getAmountSentFromThisWallet(fractionDigits: 8, subtractFee: true).raw,
      BigInt.from(350),
    );
  });

  test('incoming native atomic amounts never pass through a double', () {
    final exact = BigInt.parse('9007199254740993');
    final tx = project(
      IncomingEntryWrapper(
        from: 'other',
        transfers: [(amount: exact, asset: xel, extraData: null)],
      ),
    );
    expect(tx.getAmountReceivedInThisWallet(fractionDigits: 8).raw, exact);
    expect(tx.timestamp, 123);
  });
}
