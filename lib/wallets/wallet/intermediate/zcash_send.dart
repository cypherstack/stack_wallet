import 'dart:convert';
import 'dart:typed_data';

import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../crypto_currency/crypto_currency.dart';
import 'zcash_account_session.dart';
import 'zcash_wallet_state_controller.dart';

enum ZcashSendSourcePool { transparent, orchard, ironwood, sapling }

typedef ZcashPreparedPaymentOutput = ({
  String encodedRecipient,
  int amountZatoshis,
  Uint8List? memo,
});

abstract class ZcashPreparedWalletSend {
  const ZcashPreparedWalletSend({
    required this.sessionGeneration,
    required this.encodedRecipient,
    required this.selectedReceiver,
    required this.selectedReceiverAddress,
    required this.actualOutputPool,
    required this.memo,
  });

  final int sessionGeneration;
  final String encodedRecipient;
  final zcash.ZcashAddressReceiverType selectedReceiver;
  final String selectedReceiverAddress;
  final zcash.ProposalOutputPool actualOutputPool;
  final Uint8List? memo;

  String get transactionHex;
  String get txid;
  int get amountZatoshis;
  int get feeZatoshis;
  int get inputZatoshis;
  int get changeZatoshis;
  int get expiryHeight;
  ZcashSendSourcePool get sourcePool;

  List<zcash.ZcashScannedNote> get selectedNotes;

  List<ZcashPreparedPaymentOutput> get paymentOutputs => [
    (
      encodedRecipient: encodedRecipient,
      amountZatoshis: amountZatoshis,
      memo: memo,
    ),
  ];

  void requireValueConservation() {
    if (inputZatoshis != amountZatoshis + feeZatoshis + changeZatoshis) {
      throw StateError(
        'Prepared Zcash transaction does not conserve value: '
        '$inputZatoshis != $amountZatoshis + $feeZatoshis + $changeZatoshis',
      );
    }
  }
}

final class ZcashPreparedIronwoodSend extends ZcashPreparedWalletSend {
  ZcashPreparedIronwoodSend({
    required this.prepared,
    required super.sessionGeneration,
    required super.encodedRecipient,
    required super.selectedReceiver,
    required super.selectedReceiverAddress,
    required super.actualOutputPool,
    required super.memo,
  }) {
    requireValueConservation();
  }

  final zcash.IronwoodPreparedPayment prepared;

  @override
  String get transactionHex => prepared.transactionHex;
  @override
  String get txid => prepared.txid;
  @override
  int get amountZatoshis => prepared.plan.amountZatoshis;
  @override
  int get feeZatoshis => prepared.plan.feeZatoshis;
  @override
  int get inputZatoshis => prepared.plan.inputZatoshis;
  @override
  int get changeZatoshis => prepared.plan.changeZatoshis;
  @override
  int get expiryHeight => prepared.expiryHeight;
  @override
  ZcashSendSourcePool get sourcePool => ZcashSendSourcePool.ironwood;
  @override
  List<zcash.ZcashScannedNote> get selectedNotes =>
      List.unmodifiable(prepared.plan.notes);
}

final class ZcashPreparedIronwoodBatch extends ZcashPreparedWalletSend {
  ZcashPreparedIronwoodBatch({
    required this.prepared,
    required super.sessionGeneration,
  }) : outputs = List.unmodifiable(prepared.plan.outputs),
       super(
         encodedRecipient: prepared.plan.outputs.first.encodedAddress,
         selectedReceiver: prepared.plan.outputs.first.selectedReceiver,
         selectedReceiverAddress: prepared.plan.outputs.first.receiverAddress,
         actualOutputPool: prepared.plan.outputs.first.actualOutputPool,
         memo: prepared.plan.outputs.first.memo,
       ) {
    requireValueConservation();
  }

  final zcash.IronwoodPreparedPayments prepared;
  final List<zcash.ProposalOutput> outputs;

  @override
  List<ZcashPreparedPaymentOutput> get paymentOutputs => [
    for (final output in outputs)
      (
        encodedRecipient: output.encodedAddress,
        amountZatoshis: output.amountZatoshis,
        memo: output.memo,
      ),
  ];

  @override
  String get transactionHex => prepared.transactionHex;
  @override
  String get txid => prepared.txid;
  @override
  int get amountZatoshis => prepared.plan.amountZatoshis;
  @override
  int get feeZatoshis => prepared.plan.feeZatoshis;
  @override
  int get inputZatoshis => prepared.plan.inputZatoshis;
  @override
  int get changeZatoshis => prepared.plan.changeZatoshis;
  @override
  int get expiryHeight => prepared.expiryHeight;
  @override
  ZcashSendSourcePool get sourcePool => ZcashSendSourcePool.ironwood;
  @override
  List<zcash.ZcashScannedNote> get selectedNotes =>
      List.unmodifiable(prepared.plan.notes);
}

final class ZcashPreparedSaplingPayment extends ZcashPreparedWalletSend {
  ZcashPreparedSaplingPayment({
    required this.prepared,
    required super.sessionGeneration,
    required super.encodedRecipient,
    required super.selectedReceiver,
    required super.selectedReceiverAddress,
    required super.actualOutputPool,
    required super.memo,
  }) {
    requireValueConservation();
  }

  final zcash.SaplingPreparedPayment prepared;

  @override
  String get transactionHex => prepared.transactionHex;
  @override
  String get txid => prepared.txid;
  @override
  int get amountZatoshis => prepared.plan.amountZatoshis;
  @override
  int get feeZatoshis => prepared.plan.feeZatoshis;
  @override
  int get inputZatoshis => prepared.plan.inputZatoshis;
  @override
  int get changeZatoshis => prepared.plan.changeZatoshis;
  @override
  int get expiryHeight => prepared.expiryHeight;
  @override
  ZcashSendSourcePool get sourcePool => ZcashSendSourcePool.sapling;
  @override
  List<zcash.ZcashScannedNote> get selectedNotes =>
      List.unmodifiable(prepared.plan.notes);
}

final class ZcashRecoveredPreparedSend extends ZcashPreparedWalletSend {
  ZcashRecoveredPreparedSend({
    required this.record,
    required List<zcash.ZcashScannedNote> notes,
    required super.sessionGeneration,
  }) : _notes = List.unmodifiable(notes),
       _outputs = List.unmodifiable([
         for (final output in record.paymentOutputs)
           (
             encodedRecipient: output.encodedRecipient,
             amountZatoshis: output.amountZatoshis,
             memo: output.memoHex == null
                 ? null
                 : Uint8List.fromList([
                     for (var i = 0; i < output.memoHex!.length; i += 2)
                       int.parse(
                         output.memoHex!.substring(i, i + 2),
                         radix: 16,
                       ),
                   ]),
           ),
       ]),
       super(
         encodedRecipient: record.paymentOutputs.first.encodedRecipient,
         selectedReceiver: _receiverType(
           record.paymentOutputs.first.actualDestinationPool,
         ),
         selectedReceiverAddress: record.paymentOutputs.first.receiverAddress,
         actualOutputPool: _proposalPool(
           record.paymentOutputs.first.actualDestinationPool,
         ),
         memo: record.paymentOutputs.first.memoHex == null
             ? null
             : Uint8List.fromList([
                 for (
                   var i = 0;
                   i < record.paymentOutputs.first.memoHex!.length;
                   i += 2
                 )
                   int.parse(
                     record.paymentOutputs.first.memoHex!.substring(i, i + 2),
                     radix: 16,
                   ),
               ]),
       ) {
    requireValueConservation();
  }

  final zcash.IronwoodPendingSendRecord record;
  final List<zcash.ZcashScannedNote> _notes;
  final List<ZcashPreparedPaymentOutput> _outputs;

  @override
  List<ZcashPreparedPaymentOutput> get paymentOutputs => _outputs;
  @override
  String get transactionHex => record.transactionHex;
  @override
  String get txid => record.txid;
  @override
  int get amountZatoshis => record.amountZatoshis;
  @override
  int get feeZatoshis => record.feeZatoshis;
  @override
  int get inputZatoshis => _notes.fold(0, (sum, note) => sum + note.value);
  @override
  int get changeZatoshis => inputZatoshis - amountZatoshis - feeZatoshis;
  @override
  int get expiryHeight => record.expiryHeight;
  @override
  ZcashSendSourcePool get sourcePool =>
      record.sourcePool == zcash.ShieldedPendingSourcePool.ironwood
      ? ZcashSendSourcePool.ironwood
      : ZcashSendSourcePool.sapling;
  @override
  List<zcash.ZcashScannedNote> get selectedNotes => _notes;
}

zcash.ZcashAddressReceiverType _receiverType(
  zcash.IronwoodDestinationPool pool,
) => switch (pool) {
  zcash.IronwoodDestinationPool.transparent =>
    zcash.ZcashAddressReceiverType.p2pkh,
  zcash.IronwoodDestinationPool.sapling =>
    zcash.ZcashAddressReceiverType.sapling,
  zcash.IronwoodDestinationPool.orchard =>
    zcash.ZcashAddressReceiverType.orchard,
  zcash.IronwoodDestinationPool.ironwood =>
    zcash.ZcashAddressReceiverType.unified,
};

zcash.ProposalOutputPool _proposalPool(zcash.IronwoodDestinationPool pool) =>
    switch (pool) {
      zcash.IronwoodDestinationPool.transparent =>
        zcash.ProposalOutputPool.transparent,
      zcash.IronwoodDestinationPool.sapling => zcash.ProposalOutputPool.sapling,
      zcash.IronwoodDestinationPool.orchard => zcash.ProposalOutputPool.orchard,
      zcash.IronwoodDestinationPool.ironwood =>
        zcash.ProposalOutputPool.ironwood,
    };

final class ZcashPreparedTransparentShielding extends ZcashPreparedWalletSend {
  ZcashPreparedTransparentShielding({
    required this.prepared,
    required this.targetHeight,
    required super.sessionGeneration,
    required super.encodedRecipient,
    required super.selectedReceiverAddress,
  }) : super(
         selectedReceiver: zcash.ZcashAddressReceiverType.unified,
         actualOutputPool: zcash.ProposalOutputPool.ironwood,
         memo: null,
       ) {
    requireValueConservation();
  }

  final zcash.ShieldingPreparedSend prepared;
  final int targetHeight;

  @override
  String get transactionHex => prepared.transactionHex;
  @override
  String get txid => prepared.txid;
  @override
  int get amountZatoshis => prepared.shieldedZatoshis;
  @override
  int get feeZatoshis => prepared.feeZatoshis;
  @override
  int get inputZatoshis => prepared.selection.inputZatoshis;
  @override
  int get changeZatoshis => prepared.selection.changeZatoshis;
  @override
  int get expiryHeight => targetHeight + 40;
  @override
  ZcashSendSourcePool get sourcePool => ZcashSendSourcePool.transparent;
  @override
  List<zcash.ZcashScannedNote> get selectedNotes => const [];
}

class ZcashSendPayment {
  const ZcashSendPayment({
    required this.recipient,
    required this.amountZatoshis,
    this.memo,
  });

  final String recipient;
  final int amountZatoshis;
  final Uint8List? memo;
}

class ZcashSendPreparationRequest {
  const ZcashSendPreparationRequest({
    required this.network,
    required this.sessionGeneration,
    required this.state,
    required this.pendingSends,
    required this.syncClient,
    required this.scanExecutor,
    required this.seedHex,
    required this.saplingChangeAddress,
    required this.ironwoodChangeAddress,
    required this.recipient,
    required this.amountZatoshis,
    required this.memo,
    this.payments = const [],
    required this.targetHeight,
    required this.expiryHeight,
    required this.resolveSaplingProvingParameters,
    this.regtestNu63ActivationHeight,
  });

  final CryptoCurrencyNetwork network;
  final int sessionGeneration;
  final zcash.ZcashWalletSyncState state;
  final zcash.IronwoodPendingSendState pendingSends;
  final ZcashLightwalletdSyncClient syncClient;
  final ZcashScanExecutor scanExecutor;
  final String seedHex;
  final String saplingChangeAddress;
  final String ironwoodChangeAddress;
  final String recipient;
  final int amountZatoshis;
  final Uint8List? memo;
  final List<ZcashSendPayment> payments;
  final int targetHeight;
  final int expiryHeight;
  final Future<zcash.SaplingProvingParameters> Function()
  resolveSaplingProvingParameters;
  final int? regtestNu63ActivationHeight;

  List<ZcashSendPayment> get effectivePayments => payments.isEmpty
      ? [
          ZcashSendPayment(
            recipient: recipient,
            amountZatoshis: amountZatoshis,
            memo: memo,
          ),
        ]
      : List.unmodifiable(payments);
}

abstract interface class ZcashIronwoodSpendMaterialProvider {
  Future<zcash.ZcashSpendMaterial> acquire({
    required ZcashSendPreparationRequest request,
    required List<zcash.ZcashScannedNote> candidates,
  });
}

final class ZcashNativeIronwoodSpendMaterialProvider
    implements ZcashIronwoodSpendMaterialProvider {
  const ZcashNativeIronwoodSpendMaterialProvider();

  @override
  Future<zcash.ZcashSpendMaterial> acquire({
    required ZcashSendPreparationRequest request,
    required List<zcash.ZcashScannedNote> candidates,
  }) => zcash.acquireNativeSpendMaterial(
    wallet: request.state,
    request: zcash.ZcashSpendMaterialRequest.ironwood(
      accountFingerprint: request.state.accountFingerprint,
      notes: candidates,
      anchorHeight: request.targetHeight - 1,
    ),
    source: _StackSpendMaterialSource(
      network: _nativeNetwork(request.network).ffiLabel,
      client: request.syncClient,
      scanExecutor: request.scanExecutor,
    ),
  );
}

abstract interface class ZcashWalletSendService {
  Future<ZcashPreparedWalletSend> prepare(ZcashSendPreparationRequest request);

  Future<void> broadcast({
    required ZcashPreparedWalletSend prepared,
    required zcash.IronwoodPendingSendState pendingSends,
    required int chainHeight,
    required Future<void> Function() persist,
    required Future<ZcashSubmissionAcknowledgement> Function(
      String transactionHex,
    )
    submit,
  });
}

final class ZcashProductionWalletSendService implements ZcashWalletSendService {
  const ZcashProductionWalletSendService({
    this.maxSpendNotes = 50,
    this.spendMaterialProvider =
        const ZcashNativeIronwoodSpendMaterialProvider(),
    this.ironwoodPaymentBackend,
  });

  final int maxSpendNotes;
  final ZcashIronwoodSpendMaterialProvider spendMaterialProvider;
  final zcash.IronwoodPaymentBackend? ironwoodPaymentBackend;

  @override
  Future<void> broadcast({
    required ZcashPreparedWalletSend prepared,
    required zcash.IronwoodPendingSendState pendingSends,
    required int chainHeight,
    required Future<void> Function() persist,
    required Future<ZcashSubmissionAcknowledgement> Function(
      String transactionHex,
    )
    submit,
  }) async {
    switch (prepared) {
      case ZcashPreparedIronwoodSend():
        await zcash.broadcastIronwoodPayment(
          payment: prepared.prepared,
          chainHeight: chainHeight,
          pendingSends: pendingSends,
          isRejection: (error) => error is ZcashBroadcastRejectedException,
          submit: (transactionHex) async {
            await persist();
            await submit(transactionHex);
            return '';
          },
        );
      case ZcashPreparedIronwoodBatch():
        pendingSends.requireBroadcastablePayments(
          prepared.prepared,
          chainHeight: chainHeight,
        );
        pendingSends.markSubmitting(prepared.txid);
        await persist();
        try {
          await submit(prepared.transactionHex);
          pendingSends.markAcknowledged(prepared.txid);
        } on ZcashBroadcastRejectedException {
          pendingSends.releaseRejected(prepared.txid);
          rethrow;
        } on Object {
          pendingSends.markIndeterminate(prepared.txid);
          rethrow;
        }
      case ZcashPreparedSaplingPayment():
        pendingSends.requireBroadcastableSaplingPayment(
          prepared.prepared,
          chainHeight: chainHeight,
        );
        pendingSends.markSubmitting(prepared.txid);
        await persist();
        try {
          await submit(prepared.transactionHex);
          pendingSends.markAcknowledged(prepared.txid);
        } on ZcashBroadcastRejectedException {
          pendingSends.releaseRejected(prepared.txid);
          rethrow;
        } on Object {
          pendingSends.markIndeterminate(prepared.txid);
          rethrow;
        }
      case ZcashRecoveredPreparedSend():
        final matches = pendingSends.records.where(
          (record) => record.txid.toLowerCase() == prepared.txid.toLowerCase(),
        );
        if (matches.length != 1 ||
            jsonEncode(matches.single.toJson()) !=
                jsonEncode(prepared.record.toJson())) {
          throw StateError(
            'recovered Zcash artifact no longer matches durable state',
          );
        }
        pendingSends.requireBroadcastableRecord(
          prepared.record,
          chainHeight: chainHeight,
        );
        pendingSends.markSubmitting(prepared.txid);
        await persist();
        try {
          await submit(prepared.transactionHex);
          pendingSends.markAcknowledged(prepared.txid);
        } on ZcashBroadcastRejectedException {
          pendingSends.releaseRejected(prepared.txid);
          rethrow;
        } on Object {
          pendingSends.markIndeterminate(prepared.txid);
          rethrow;
        }
      default:
        throw StateError('Unknown Zcash prepared-send artifact');
    }
  }

  @override
  Future<ZcashPreparedWalletSend> prepare(
    ZcashSendPreparationRequest request,
  ) async {
    final outputs = [
      for (final payment in request.effectivePayments)
        _resolveOutput(request, payment),
    ];
    final ironwood = await _tryPrepareIronwood(request, outputs);
    if (ironwood != null) return ironwood;
    if (outputs.length != 1) {
      throw zcash.IronwoodSelectionException(
        zcash.IronwoodSelectionRefusal.insufficientFunds,
        'multi-recipient sends require spendable Ironwood notes',
      );
    }
    final output = outputs.single;
    if (output.actualOutputPool != zcash.ProposalOutputPool.ironwood) {
      throw zcash.IronwoodSelectionException(
        zcash.IronwoodSelectionRefusal.insufficientFunds,
        'A ${output.actualOutputPool.name} output after NU6.3 must be funded '
        'from Ironwood, but this wallet has no spendable Ironwood notes for '
        'the payment and its ZIP 317 fee',
      );
    }
    return _prepareSaplingPathB(request, output);
  }

  zcash.ProposalOutput _resolveOutput(
    ZcashSendPreparationRequest request,
    ZcashSendPayment payment,
  ) {
    final nativeNetwork = _nativeNetwork(request.network);
    final metadata = zcash.decodeNativeAddress(
      address: payment.recipient,
      network: nativeNetwork,
    );
    final inventory =
        metadata.receiverType == zcash.ZcashAddressReceiverType.unified
        ? zcash.inventoryUnifiedAddressReceivers(
            address: payment.recipient,
            network: nativeNetwork,
          )
        : null;
    return zcash.resolveProposalOutput(
      recipient: zcash.ProposalRecipient(
        address: payment.recipient,
        amountZatoshis: payment.amountZatoshis,
        memo: payment.memo,
      ),
      address: metadata,
      unifiedReceivers: inventory,
      network: _addressNetwork(request.network),
      targetHeight: request.targetHeight,
      transactionExpiryHeight: request.expiryHeight,
      currentUnixTime: DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Future<ZcashPreparedWalletSend?> _tryPrepareIronwood(
    ZcashSendPreparationRequest request,
    List<zcash.ProposalOutput> outputs,
  ) async {
    final spent = {
      for (final spend in request.state.ironwood.spends) spend.nullifier,
    };
    final reserved = request.pendingSends.reservedNullifiersAt(
      request.targetHeight,
    );
    final candidates = <zcash.ZcashScannedNote>[
      for (final note in request.state.ironwood.notes)
        if (note.nullifier != null &&
            note.commitmentPosition != null &&
            !spent.contains(note.nullifier) &&
            !reserved.contains(note.nullifier))
          note,
    ]..sort((left, right) => right.value.compareTo(left.value));
    if (candidates.length > maxSpendNotes) {
      candidates.removeRange(maxSpendNotes, candidates.length);
    }
    if (candidates.isEmpty) return null;

    final material = await spendMaterialProvider.acquire(
      request: request,
      candidates: candidates,
    );
    try {
      final provingParameters =
          outputs.any(
            (output) =>
                output.actualOutputPool == zcash.ProposalOutputPool.sapling,
          )
          ? await request.resolveSaplingProvingParameters()
          : null;
      if (outputs.length > 1) {
        final prepared = zcash.prepareNativeIronwoodPayments(
          network: _nativeNetwork(request.network),
          scan: material.scan,
          outputs: outputs,
          ironwoodChangeAddress: request.ironwoodChangeAddress,
          targetHeight: request.targetHeight,
          expiryHeight: request.expiryHeight,
          seedHex: request.seedHex,
          reservations: request.pendingSends,
          maxNotes: maxSpendNotes,
          provingParameters: provingParameters,
          regtestNu63ActivationHeight: request.regtestNu63ActivationHeight,
          now: DateTime.now().toUtc(),
          allowExperimentalIronwoodBuild: true,
          backend: ironwoodPaymentBackend,
        );
        request.pendingSends.addPreparedPayments(
          prepared,
          createdHeight: request.targetHeight - 1,
        );
        return ZcashPreparedIronwoodBatch(
          prepared: prepared,
          sessionGeneration: request.sessionGeneration,
        );
      }
      final output = outputs.single;
      final prepared = zcash.prepareNativeIronwoodPayment(
        network: _nativeNetwork(request.network),
        scan: material.scan,
        output: output,
        ironwoodChangeAddress: request.ironwoodChangeAddress,
        targetHeight: request.targetHeight,
        expiryHeight: request.expiryHeight,
        seedHex: request.seedHex,
        reservations: request.pendingSends,
        maxNotes: maxSpendNotes,
        provingParameters: provingParameters,
        regtestNu63ActivationHeight: request.regtestNu63ActivationHeight,
        now: DateTime.now().toUtc(),
        allowExperimentalIronwoodBuild: true,
        backend: ironwoodPaymentBackend,
      );
      request.pendingSends.addPreparedPayment(
        prepared,
        createdHeight: request.targetHeight - 1,
      );
      return ZcashPreparedIronwoodSend(
        prepared: prepared,
        sessionGeneration: request.sessionGeneration,
        encodedRecipient: output.encodedAddress,
        selectedReceiver: output.selectedReceiver,
        selectedReceiverAddress: output.receiverAddress,
        actualOutputPool: output.actualOutputPool,
        memo: output.memo,
      );
    } on zcash.IronwoodSelectionException catch (error) {
      if (error.refusal != zcash.IronwoodSelectionRefusal.insufficientFunds &&
          error.refusal !=
              zcash.IronwoodSelectionRefusal.insufficientSpendableNotes) {
        rethrow;
      }
      return null;
    }
  }

  Future<ZcashPreparedSaplingPayment> _prepareSaplingPathB(
    ZcashSendPreparationRequest request,
    zcash.ProposalOutput output,
  ) async {
    // An empty compact-block scan does not promise to emit anchors. Acquire
    // the exact canonical tree state for the block the payment anchors to,
    // matching the live Path B contract and avoiding a synthesized tip root.
    final boundary = await request.syncClient.getTreeState(
      request.targetHeight - 1,
    );
    final saplingFrontier = boundary.sapling?.finalState;
    if (saplingFrontier == null || saplingFrontier.isEmpty) {
      throw StateError('Sapling Path B boundary has no Sapling frontier');
    }
    final ironwoodFrontier = boundary.ironwood?.finalState;
    final anchors = await request.scanExecutor.scan(
      zcash.ScanInputEnvelope(
        network: _nativeNetwork(request.network).ffiLabel,
        includeSaplingWitnesses: true,
        priorSaplingFrontier: saplingFrontier,
        includeOrchardWitnesses: true,
        priorIronwoodFrontier:
            ironwoodFrontier == null || ironwoodFrontier.isEmpty
            ? null
            : ironwoodFrontier,
        blocks: const [],
      ),
    );
    final saplingAnchor = anchors.saplingAnchor;
    if (saplingAnchor == null || saplingAnchor.length != 64) {
      throw StateError('Sapling Path B boundary scan has no Sapling root');
    }
    final ironwoodAnchor = anchors.ironwoodAnchor;
    final scan = zcash.ZcashScanResult(
      scannedBlocks: 0,
      discoveredNotes: request.state.sapling.notes.length,
      totalValue: request.state.sapling.notes.fold(
        0,
        (sum, note) => sum + note.value,
      ),
      notes: request.state.sapling.notes,
      spends: request.state.sapling.spends,
      saplingAnchor: saplingAnchor,
      ironwoodAnchor: ironwoodAnchor == null || ironwoodAnchor.isEmpty
          ? zcash.orchardFamilyEmptyTreeRootHex
          : ironwoodAnchor,
    );
    final provingParameters = await request.resolveSaplingProvingParameters();
    final prepared = zcash.prepareNativeSaplingPayment(
      scan: scan,
      output: output,
      saplingChangeAddress: request.saplingChangeAddress,
      targetHeight: request.targetHeight,
      expiryHeight: request.expiryHeight,
      provingParameters: provingParameters,
      network: _nativeNetwork(request.network),
      seedHex: request.seedHex,
      reservations: request.pendingSends,
      maxNotes: maxSpendNotes,
      regtestNu63ActivationHeight: request.regtestNu63ActivationHeight,
      now: DateTime.now().toUtc(),
      allowExperimentalIronwoodBuild: true,
    );
    request.pendingSends.addPreparedSaplingPayment(
      prepared,
      createdHeight: request.targetHeight - 1,
    );
    return ZcashPreparedSaplingPayment(
      prepared: prepared,
      sessionGeneration: request.sessionGeneration,
      encodedRecipient: output.encodedAddress,
      selectedReceiver: output.selectedReceiver,
      selectedReceiverAddress: output.receiverAddress,
      actualOutputPool: output.actualOutputPool,
      memo: output.memo,
    );
  }
}

final class _StackSpendMaterialSource
    implements zcash.ZcashSpendMaterialSource {
  const _StackSpendMaterialSource({
    required this.network,
    required this.client,
    required this.scanExecutor,
  });

  @override
  final String network;
  final ZcashLightwalletdSyncClient client;
  final ZcashScanExecutor scanExecutor;

  @override
  Future<zcash.ZcashLightwalletdScanSource> fetchRange(int start, int end) =>
      client.getBlockRange(start, end);

  @override
  Future<zcash.TreeState> fetchTreeState(int height) =>
      client.getTreeState(height);

  @override
  Future<zcash.ZcashScanResult> scan(zcash.ScanInputEnvelope input) =>
      scanExecutor.scan(input);
}

zcash.ZcashNetwork _nativeNetwork(CryptoCurrencyNetwork network) =>
    switch (network) {
      CryptoCurrencyNetwork.main => zcash.ZcashNetwork.mainnet,
      CryptoCurrencyNetwork.test => zcash.ZcashNetwork.testnet,
      CryptoCurrencyNetwork.regtest => zcash.ZcashNetwork.regtest,
      CryptoCurrencyNetwork.stage || CryptoCurrencyNetwork.test4 =>
        throw StateError('Unsupported Zcash network: $network'),
    };

zcash.ZcashAddressNetwork _addressNetwork(CryptoCurrencyNetwork network) =>
    switch (network) {
      CryptoCurrencyNetwork.main => zcash.ZcashAddressNetwork.mainnet,
      CryptoCurrencyNetwork.test => zcash.ZcashAddressNetwork.testnet,
      CryptoCurrencyNetwork.regtest => zcash.ZcashAddressNetwork.regtest,
      CryptoCurrencyNetwork.stage || CryptoCurrencyNetwork.test4 =>
        throw StateError('Unsupported Zcash network: $network'),
    };
