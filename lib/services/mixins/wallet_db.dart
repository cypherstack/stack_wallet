import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';

mixin WalletDB {
  Isar? _isar;

  Isar get isar => _isar!;

  /// open the db if it was not already open
  /// returns true if the db was not yet open
  /// returns false if the db was already open
  Future<bool> isarInit(String walletId) async {
    if (_isar != null && isar.isOpen) return false;
    _isar = await Isar.open(
      [
        TransactionSchema,
        TransactionNoteSchema,
        InputSchema,
        OutputSchema,
        UTXOSchema,
        AddressSchema,
      ],
      directory: (await StackFileSystem.applicationIsarDirectory()).path,
      inspector: false,
      name: walletId,
    );
    return true;
  }

  Future<bool> isarClose() async => await _isar?.close() ?? false;
}
