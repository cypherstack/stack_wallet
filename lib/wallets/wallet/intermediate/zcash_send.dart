import 'dart:typed_data';

import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../crypto_currency/crypto_currency.dart';
import 'zcash_account_session.dart';
import 'zcash_wallet_state_controller.dart';

enum ZcashSendSourcePool { ironwood, sapling }

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

  final zcash.IronwoodPreparedSend prepared;

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
    required this.recipient,
    required this.amountZatoshis,
    required this.memo,
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
  final String recipient;
  final int amountZatoshis;
  final Uint8List? memo;
  final int targetHeight;
  final int expiryHeight;
  final Future<zcash.SaplingProvingParameters> Function()
  resolveSaplingProvingParameters;
  final int? regtestNu63ActivationHeight;
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
  const ZcashProductionWalletSendService({this.maxSpendNotes = 50});

  final int maxSpendNotes;

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
        await zcash.broadcastIronwoodSend(
          send: prepared.prepared,
          chainHeight: chainHeight,
          pendingSends: pendingSends,
          isRejection: (error) => error is ZcashBroadcastRejectedException,
          submit: (transactionHex) async {
            await persist();
            await submit(transactionHex);
            return '';
          },
        );
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
      default:
        throw StateError('Unknown Zcash prepared-send artifact');
    }
  }

  @override
  Future<ZcashPreparedWalletSend> prepare(
    ZcashSendPreparationRequest request,
  ) async {
    final output = _resolveOutput(request);
    if (output.actualOutputPool != zcash.ProposalOutputPool.ironwood) {
      throw UnsupportedError(
        'Stack can route this recipient to ${output.actualOutputPool.name}, '
        'but the backend cannot yet persist a durable reservation for that '
        'actual output pool',
      );
    }

    final ironwood = await _tryPrepareIronwood(request, output);
    if (ironwood != null) return ironwood;
    return _prepareSaplingPathB(request, output);
  }

  zcash.ProposalOutput _resolveOutput(ZcashSendPreparationRequest request) {
    final nativeNetwork = _nativeNetwork(request.network);
    final metadata = zcash.decodeNativeAddress(
      address: request.recipient,
      network: nativeNetwork,
    );
    final inventory =
        metadata.receiverType == zcash.ZcashAddressReceiverType.unified
        ? zcash.inventoryUnifiedAddressReceivers(
            address: request.recipient,
            network: nativeNetwork,
          )
        : null;
    return zcash.resolveProposalOutput(
      recipient: zcash.ProposalRecipient(
        address: request.recipient,
        amountZatoshis: request.amountZatoshis,
        memo: request.memo,
      ),
      address: metadata,
      unifiedReceivers: inventory,
      network: _addressNetwork(request.network),
      targetHeight: request.targetHeight,
      transactionExpiryHeight: request.expiryHeight,
      currentUnixTime: DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Future<ZcashPreparedIronwoodSend?> _tryPrepareIronwood(
    ZcashSendPreparationRequest request,
    zcash.ProposalOutput output,
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

    final material = await zcash.acquireNativeSpendMaterial(
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
    try {
      final prepared = zcash.prepareNativeIronwoodSend(
        network: _nativeNetwork(request.network),
        scan: material.scan,
        toAddress: output.receiverAddress,
        amountZatoshis: output.amountZatoshis,
        targetHeight: request.targetHeight,
        expiryHeight: request.expiryHeight,
        seedHex: request.seedHex,
        reservations: request.pendingSends,
        maxNotes: maxSpendNotes,
        memo: output.memo,
        regtestNu63ActivationHeight: request.regtestNu63ActivationHeight,
        now: DateTime.now().toUtc(),
        allowExperimentalIronwoodBuild: true,
      );
      request.pendingSends.addPrepared(
        prepared,
        actualDestinationPool: zcash.IronwoodDestinationPool.ironwood,
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
    final boundary = await request.scanExecutor.scan(
      zcash.ScanInputEnvelope(
        network: _nativeNetwork(request.network).ffiLabel,
        priorSaplingFrontier: request.state.cursor.priorSaplingFrontier,
        priorOrchardFrontier: request.state.cursor.priorOrchardFrontier,
        priorIronwoodFrontier: request.state.cursor.priorIronwoodFrontier,
        blocks: const [],
      ),
    );
    final scan = zcash.ZcashScanResult(
      scannedBlocks: 0,
      discoveredNotes: request.state.sapling.notes.length,
      totalValue: request.state.sapling.notes.fold(
        0,
        (sum, note) => sum + note.value,
      ),
      notes: request.state.sapling.notes,
      spends: request.state.sapling.spends,
      saplingAnchor: boundary.saplingAnchor,
      ironwoodAnchor: boundary.ironwoodAnchor,
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
