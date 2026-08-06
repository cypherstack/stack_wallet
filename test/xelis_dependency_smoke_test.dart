import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wl_gen/interfaces/lib_xelis_interface.dart';
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

  test('all Xelis SDK transaction variants have Stack Wallet wrappers', () {
    const extraData = xelis_sdk.ExtraData(
      data: 'payload',
      flag: xelis_sdk.Flag.public,
    );
    final entries = <xelis_sdk.TransactionEntryType>[
      const xelis_sdk.TransactionEntryType.coinbase(reward: 1),
      const xelis_sdk.TransactionEntryType.burn(
        asset: 'asset',
        amount: 2,
        fee: 3,
        nonce: 4,
      ),
      const xelis_sdk.TransactionEntryType.incoming(
        from: 'from',
        transfers: [],
      ),
      const xelis_sdk.TransactionEntryType.outgoing(
        fee: 1,
        nonce: 2,
        transfers: [],
      ),
      const xelis_sdk.TransactionEntryType.multisig(
        participants: ['participant'],
        threshold: 1,
        fee: 2,
        nonce: 3,
      ),
      const xelis_sdk.TransactionEntryType.invokeContract(
        contract: 'contract',
        deposits: {'asset': 1},
        received: {},
        chunkId: 2,
        fee: 3,
        maxGas: 4,
        nonce: 5,
      ),
      const xelis_sdk.TransactionEntryType.deployContract(fee: 1, nonce: 2),
      const xelis_sdk.TransactionEntryType.incomingContract(
        transfers: {
          'contract': {'asset': 1},
        },
      ),
      const xelis_sdk.TransactionEntryType.outgoingBlob(
        destinations: ['destination'],
        fee: 1,
        nonce: 2,
        data: extraData,
      ),
      const xelis_sdk.TransactionEntryType.incomingBlob(
        from: 'from',
        destinations: ['destination'],
        data: extraData,
      ),
    ];

    final wrappers = entries.map(xelisEntryTypeToWrapper).toList();

    expect(wrappers, hasLength(entries.length));
    expect(wrappers.whereType<UnknownEntryWrapper>(), isEmpty);
    expect(wrappers[7], isA<IncomingContractEntryWrapper>());
    expect(wrappers[8], isA<OutgoingBlobEntryWrapper>());
    expect(wrappers[9], isA<IncomingBlobEntryWrapper>());
  });
}
