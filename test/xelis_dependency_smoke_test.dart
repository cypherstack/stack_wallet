import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as xelis_sdk;
import 'package:xelis_flutter/src/api/network.dart' as xelis_ffi;
import 'package:xelis_flutter/src/api/precomputed_tables.dart' as xelis_ffi;

void main() {
  test('updated Xelis dependencies expose the APIs used by Stack Wallet', () {
    expect(
      xelis_sdk.WalletEvent.fromStr('new_transaction'),
      xelis_sdk.WalletEvent.newTransaction,
    );
    expect(
      xelis_sdk.WalletEvent.fromStr('new_pending_transaction'),
      xelis_sdk.WalletEvent.newPendingTransaction,
    );
    expect(xelis_ffi.Network.mainnet.name, 'mainnet');
    expect(
      const xelis_ffi.PrecomputedTableType.l1Low(),
      isA<xelis_ffi.PrecomputedTableType>(),
    );
  });
}
