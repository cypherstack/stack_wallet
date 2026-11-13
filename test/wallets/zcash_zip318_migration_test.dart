import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_send.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_zip318_migration.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_zip318_migration_store.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import 'support/xelis_test_fakes.dart';

void main() {
  test(
    'prepares a canonical Orchard to Ironwood migration from a due schedule',
    () async {
      final backend = _Backend();
      final service = ZcashProductionZip318MigrationService(
        backend: backend,
        random: Random(7),
      );
      final prepared = await service.prepare(_request());

      expect(prepared.sourcePool, ZcashSendSourcePool.orchard);
      expect(prepared.actualOutputPool, zcash.ProposalOutputPool.ironwood);
      expect(prepared.encodedRecipient, 'uregtest1requested');
      expect(prepared.selectedReceiver, zcash.ZcashAddressReceiverType.orchard);
      expect(prepared.amountZatoshis, 1000000);
      expect(prepared.feeZatoshis, 15000);
      expect(prepared.inputZatoshis, 2000000);
      expect(prepared.changeZatoshis, 985000);
      expect(prepared.selectedNotes, [_orchardNote]);
      expect(backend.plan?.funding.note, same(_orchardNote));
    },
  );

  test('refuses an incomplete privacy-consent contract', () async {
    final service = ZcashProductionZip318MigrationService(
      backend: _Backend(),
      random: Random(7),
    );

    await expectLater(
      service.prepare(_request(consent: const zcash.Zip318ConsentChecklist())),
      throwsA(isA<StateError>()),
    );
  });

  test('refuses a boundary whose Ironwood tree is unavailable', () async {
    final service = ZcashProductionZip318MigrationService(
      backend: _Backend(),
      random: Random(7),
    );

    await expectLater(
      service.prepare(
        _request(
          fetchTreeState: (height) async => zcash.TreeState(
            hash: '22' * 32,
            height: height,
            time: 1,
            orchard: const zcash.ShieldedTree(finalState: 'orchard-tree'),
          ),
        ),
      ),
      throwsA(
        isA<zcash.Zip318AnchorException>().having(
          (error) => error.anchorRefusal,
          'anchor refusal',
          zcash.Zip318AnchorRefusal.ironwoodTreeUnavailable,
        ),
      ),
    );
  });

  test('refuses preparation before its randomized broadcast height', () async {
    final service = ZcashProductionZip318MigrationService(
      backend: _Backend(),
      random: Random(7),
    );

    await expectLater(
      service.prepare(
        _request(
          observedTipHeight: 30,
          scheduledTransfer: const zcash.Zip318ScheduledTransfer(
            denominationZatoshis: 1000000,
            feeZatoshis: 15000,
            broadcastHeight: 31,
            expiryHeight: 100,
          ),
        ),
      ),
      throwsA(
        isA<zcash.Zip318PlanException>().having(
          (error) => error.refusal,
          'refusal',
          zcash.Zip318PlanRefusal.offSchedule,
        ),
      ),
    );
  });

  test('refuses preparation before Ironwood activation', () async {
    final service = ZcashProductionZip318MigrationService(
      backend: _Backend(),
      random: Random(7),
    );

    await expectLater(
      service.prepare(
        _request(
          observedTipHeight: 10,
          scheduledTransfer: const zcash.Zip318ScheduledTransfer(
            denominationZatoshis: 1000000,
            feeZatoshis: 15000,
            broadcastHeight: 9,
            expiryHeight: 100,
          ),
        ),
      ),
      throwsA(
        isA<zcash.Zip318PlanException>().having(
          (error) => error.refusal,
          'refusal',
          zcash.Zip318PlanRefusal.anchorBeforeActivation,
        ),
      ),
    );
  });

  test('one application-open session refuses a second migration', () async {
    final service = ZcashProductionZip318MigrationService(
      backend: _Backend(),
      random: Random(7),
    );
    final prepared = await service.prepare(_request());
    final session = zcash.Zip318BroadcastSession();
    final first = ZcashZip318PendingState()
      ..addPrepared(prepared, createdHeight: 30);
    await service.broadcast(
      prepared: prepared,
      pending: first,
      session: session,
      chainHeight: 30,
      persist: () async {},
      submit: (_) async => prepared.txid,
    );
    final second = ZcashZip318PendingState()
      ..addPrepared(prepared, createdHeight: 30);

    await expectLater(
      service.broadcast(
        prepared: prepared,
        pending: second,
        session: session,
        chainHeight: 30,
        persist: () async {},
        submit: (_) async => prepared.txid,
      ),
      throwsA(
        isA<zcash.Zip318PlanException>().having(
          (error) => error.refusal,
          'refusal',
          zcash.Zip318PlanRefusal.sessionAlreadyUsed,
        ),
      ),
    );
    expect(
      second.records.single.state,
      ZcashZip318PendingBroadcastState.prepared,
    );
  });

  test(
    'persists the reservation before one session-limited broadcast',
    () async {
      final service = ZcashProductionZip318MigrationService(
        backend: _Backend(),
        random: Random(7),
      );
      final prepared = await service.prepare(_request());
      final pending = ZcashZip318PendingState()
        ..addPrepared(prepared, createdHeight: 30);
      final session = zcash.Zip318BroadcastSession();
      final events = <String>[];

      final receipt = await service.broadcast(
        prepared: prepared,
        pending: pending,
        session: session,
        chainHeight: 30,
        persist: () async =>
            events.add('persist:${pending.records.single.state.name}'),
        submit: (transactionHex) async {
          events.add('submit:$transactionHex');
          return prepared.txid;
        },
      );

      expect(receipt.txid, prepared.txid);
      expect(receipt.sourceNullifier, _orchardNote.nullifier);
      expect(session.hasBroadcast, isTrue);
      expect(
        pending.records.single.state,
        ZcashZip318PendingBroadcastState.acknowledged,
      );
      expect(events, [
        'persist:submitting',
        'submit:${prepared.transactionHex}',
        'persist:acknowledged',
      ]);
    },
  );

  test(
    'encrypted migration state survives restart without leaking artifacts',
    () async {
      final directory = await Directory.systemTemp.createTemp('zip318_store_');
      addTearDown(() => directory.delete(recursive: true));
      final store = ZcashEncryptedZip318MigrationStore(
        path: '${directory.path}/wallet.zip318',
        walletId: 'wallet-a',
        network: 'regtest',
        accountFingerprint: 'account-a',
        secureStorage: MemorySecrets(),
      );
      final service = ZcashProductionZip318MigrationService(
        backend: _Backend(),
        random: Random(7),
      );
      final prepared = await service.prepare(_request());
      final pending = ZcashZip318PendingState()
        ..addPrepared(prepared, createdHeight: 30);

      await store.save(pending);
      final envelope = jsonDecode(await File(store.path).readAsString()) as Map;
      expect(envelope.toString(), isNot(contains(prepared.transactionHex)));
      final loaded = await store.load();
      expect(loaded.records.single.txid, prepared.txid);
      expect(
        loaded.records.single.sourceNullifier,
        prepared.plan.funding.note.nullifier,
      );
    },
  );
}

ZcashZip318PreparationRequest _request({
  int observedTipHeight = 30,
  zcash.Zip318ScheduledTransfer scheduledTransfer =
      const zcash.Zip318ScheduledTransfer(
        denominationZatoshis: 1000000,
        feeZatoshis: 15000,
        broadcastHeight: 29,
        expiryHeight: 100,
      ),
  Set<String> reservedNullifiers = const {},
  zcash.Zip318ConsentChecklist consent = const zcash.Zip318ConsentChecklist(
    disclosedPoolCrossingAmounts: true,
    displayedOrchardBalanceAtRisk: true,
    confirmedFullSchedule: true,
    presentedNetworkPrivacyOptions: true,
    separatesSyncFromBroadcast: true,
    limitsOverdueCatchUp: true,
  ),
  ZcashTreeStateFetcher? fetchTreeState,
}) => ZcashZip318PreparationRequest(
  network: CryptoCurrencyNetwork.regtest,
  sessionGeneration: 3,
  orchardNotes: [_orchardNote],
  orchardSpends: const [],
  reservedNullifiers: reservedNullifiers,
  observedTipHeight: observedTipHeight,
  scheduledTransfer: scheduledTransfer,
  recipientAddress: 'uregtest1requested',
  ufvk: 'regtest-ufvk',
  seedHex: '11' * 32,
  parameters: _parameters,
  consent: consent,
  fetchTreeState:
      fetchTreeState ??
      (height) async => zcash.TreeState(
        hash: '22' * 32,
        height: height,
        time: 1,
        orchard: const zcash.ShieldedTree(finalState: 'orchard-tree'),
        ironwood: const zcash.ShieldedTree(finalState: 'ironwood-tree'),
      ),
);

const _parameters = zcash.Zip318Parameters(
  nu63ActivationHeight: 10,
  meanDelayBlocks: 1,
  maxDelayBlocks: 2,
  anchorBoundaryModulus: 5,
  anchorAgeCapBoundaries: 4,
  expiryModulusBlocks: 100,
);

final _orchardNote = zcash.ZcashScannedNote(
  height: 11,
  tx: '33' * 32,
  output: 0,
  value: 2000000,
  pool: 'orchard',
  nullifier: '44' * 32,
  recipient: 'uregtest1source',
  rseed: '55',
  rho: '66',
  noteVersion: 'v2',
  witness: '77',
);

final class _Backend implements ZcashZip318Backend {
  zcash.Zip318TransferPlan? plan;

  @override
  zcash.IronwoodBuildResult build({
    required CryptoCurrencyNetwork network,
    required zcash.Zip318TransferPlan plan,
    required String seedHex,
    int account = 0,
  }) {
    this.plan = plan;
    return zcash.IronwoodBuildResult(
      network: zcash.ZcashAddressNetwork.regtest,
      transactionHex: '0123456789abcdef' * 8,
      txid: '88' * 32,
      version: 'v6',
      consensusBranchId: 'nu6.3',
      expiryHeight: plan.expiryHeight,
      feeZatoshis: plan.feeZatoshis,
      feeRule: 'zip317',
      proofValidity: 'real',
      ironwoodAnchor: plan.ironwoodAnchorHex,
      ironwoodAnchorSource: 'anchor',
      vin: 0,
      vout: 0,
      ironwoodActions: 1,
      orchardSpends: 1,
      orchardActions: plan.orchardChangeZatoshis == null ? 1 : 2,
      orchardChangeOutputs: plan.orchardChangeZatoshis == null ? 0 : 1,
      zip318Canonical: true,
      totalInputZatoshis: plan.funding.note.value,
      orchardInputZatoshis: plan.funding.note.value,
      orchardChangeZatoshis: plan.orchardChangeZatoshis ?? 0,
      nonIronwoodOutputZatoshis: 0,
      ironwoodOutputZatoshis: plan.ironwoodOutputZatoshis,
      rng: 'os',
    );
  }

  @override
  ZcashZip318ResolvedOutput resolveOutput({
    required CryptoCurrencyNetwork network,
    required String encodedRecipient,
    required int amountZatoshis,
    required int targetHeight,
    required int expiryHeight,
  }) => ZcashZip318ResolvedOutput(
    encodedAddress: encodedRecipient,
    receiverAddress: 'uregtest1selected-orchard',
    selectedReceiver: zcash.ZcashAddressReceiverType.orchard,
    actualOutputPool: zcash.ProposalOutputPool.ironwood,
  );

  @override
  zcash.Zip318TransferPlan planTransfer({
    required CryptoCurrencyNetwork network,
    required zcash.Zip318ScheduledTransfer transfer,
    required zcash.Zip318FundingSelection funding,
    required zcash.Zip318BoundaryAnchors anchors,
    required int observedTipHeight,
    required String recipientAddress,
    required String ufvk,
    required zcash.Zip318Parameters parameters,
  }) => zcash.Zip318TransferPlan.forTransfer(
    transfer: transfer,
    funding: funding,
    anchorHeight: anchors.boundaryHeight,
    orchardAnchorHex: 'aa' * 32,
    ironwoodAnchorHex: 'bb' * 32,
    observedTipHeight: observedTipHeight,
    recipientAddress: recipientAddress,
    parameters: parameters,
  );
}
