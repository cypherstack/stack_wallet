import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/transaction_note.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/wallet/transaction_note_provider.dart';

import '../support/isar_test_utils.dart';

class _TestMainDB extends Mock implements MainDB {
  _TestMainDB(this.isar);

  @override
  final Isar isar;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('transaction note watcher updates and disposes exactly once', () async {
    await initializeTestIsar();
    final directory = await Directory.systemTemp.createTemp('note_provider_');
    final isar = await Isar.open(
      [TransactionNoteSchema],
      directory: directory.path,
      name: 'notes',
      inspector: false,
    );
    addTearDown(() async {
      await isar.close();
      await directory.delete(recursive: true);
    });
    final errors = <Object>[];
    final container = ProviderContainer(
      overrides: [mainDBProvider.overrideWithValue(_TestMainDB(isar))],
    );
    var disposed = false;
    addTearDown(() {
      if (!disposed) container.dispose();
    });
    const key = (walletId: 'wallet', txid: 'transaction');
    final noteObserved = Completer<void>();
    final subscription = container.listen(pTransactionNote(key), (_, next) {
      if (next?.value == 'note' && !noteObserved.isCompleted) {
        noteObserved.complete();
      }
    });
    expect(container.read(pTransactionNote(key)), isNull);
    await isar.writeTxn(() async {
      await isar.transactionNotes.put(
        TransactionNote(walletId: key.walletId, txid: key.txid, value: 'note'),
      );
    });
    await noteObserved.future.timeout(const Duration(seconds: 5));
    expect(container.read(pTransactionNote(key))?.value, 'note');

    subscription.close();
    runZonedGuarded<void>(container.dispose, (error, _) => errors.add(error));
    disposed = true;
    expect(errors, isEmpty);

    await isar.writeTxn(() => isar.transactionNotes.clear());
    await Future<void>.delayed(Duration.zero);
    expect(errors, isEmpty);
  });
}
