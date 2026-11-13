import 'dart:math';

import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../crypto_currency/crypto_currency.dart';
import 'zcash_send.dart';

typedef ZcashTreeStateFetcher = Future<zcash.TreeState> Function(int height);

final class ZcashZip318PreparationRequest {
  ZcashZip318PreparationRequest({
    required this.network,
    required this.sessionGeneration,
    required Iterable<zcash.ZcashScannedNote> orchardNotes,
    required Iterable<zcash.ZcashObservedSpend> orchardSpends,
    required Set<String> reservedNullifiers,
    required this.observedTipHeight,
    required this.scheduledTransfer,
    required this.recipientAddress,
    required this.ufvk,
    required this.seedHex,
    required this.parameters,
    required this.consent,
    required this.fetchTreeState,
  }) : orchardNotes = List.unmodifiable(orchardNotes),
       orchardSpends = List.unmodifiable(orchardSpends),
       reservedNullifiers = Set.unmodifiable(reservedNullifiers);

  final CryptoCurrencyNetwork network;
  final int sessionGeneration;
  final List<zcash.ZcashScannedNote> orchardNotes;
  final List<zcash.ZcashObservedSpend> orchardSpends;
  final Set<String> reservedNullifiers;
  final int observedTipHeight;
  final zcash.Zip318ScheduledTransfer scheduledTransfer;
  final String recipientAddress;
  final String ufvk;
  final String seedHex;
  final zcash.Zip318Parameters parameters;
  final zcash.Zip318ConsentChecklist consent;
  final ZcashTreeStateFetcher fetchTreeState;
}

abstract interface class ZcashZip318Backend {
  ZcashZip318ResolvedOutput resolveOutput({
    required CryptoCurrencyNetwork network,
    required String encodedRecipient,
    required int amountZatoshis,
    required int targetHeight,
    required int expiryHeight,
  });

  zcash.Zip318TransferPlan planTransfer({
    required CryptoCurrencyNetwork network,
    required zcash.Zip318ScheduledTransfer transfer,
    required zcash.Zip318FundingSelection funding,
    required zcash.Zip318BoundaryAnchors anchors,
    required int observedTipHeight,
    required String recipientAddress,
    required String ufvk,
    required zcash.Zip318Parameters parameters,
  });

  zcash.IronwoodBuildResult build({
    required CryptoCurrencyNetwork network,
    required zcash.Zip318TransferPlan plan,
    required String seedHex,
    int account = 0,
  });
}

final class ZcashZip318ResolvedOutput {
  const ZcashZip318ResolvedOutput({
    required this.encodedAddress,
    required this.receiverAddress,
    required this.selectedReceiver,
    required this.actualOutputPool,
  });

  final String encodedAddress;
  final String receiverAddress;
  final zcash.ZcashAddressReceiverType selectedReceiver;
  final zcash.ProposalOutputPool actualOutputPool;
}

final class ZcashNativeZip318Backend implements ZcashZip318Backend {
  const ZcashNativeZip318Backend();

  @override
  ZcashZip318ResolvedOutput resolveOutput({
    required CryptoCurrencyNetwork network,
    required String encodedRecipient,
    required int amountZatoshis,
    required int targetHeight,
    required int expiryHeight,
  }) {
    final nativeNetwork = _nativeNetwork(network);
    final addressNetwork = _addressNetwork(network);
    final metadata = zcash.decodeNativeAddress(
      address: encodedRecipient,
      network: nativeNetwork,
    );
    final receivers =
        metadata.receiverType == zcash.ZcashAddressReceiverType.unified
        ? zcash.inventoryUnifiedAddressReceivers(
            address: encodedRecipient,
            network: nativeNetwork,
          )
        : null;
    final output = zcash.resolveProposalOutput(
      recipient: zcash.ProposalRecipient(
        address: encodedRecipient,
        amountZatoshis: amountZatoshis,
      ),
      address: metadata,
      unifiedReceivers: receivers,
      network: addressNetwork,
      targetHeight: targetHeight,
      transactionExpiryHeight: expiryHeight,
      currentUnixTime: DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
    );
    return ZcashZip318ResolvedOutput(
      encodedAddress: output.encodedAddress,
      receiverAddress: output.receiverAddress,
      selectedReceiver: output.selectedReceiver,
      actualOutputPool: output.actualOutputPool,
    );
  }

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
  }) => zcash.planNativeZip318Transfer(
    transfer: transfer,
    funding: funding,
    anchors: anchors,
    observedTipHeight: observedTipHeight,
    recipientAddress: recipientAddress,
    ufvk: ufvk,
    network: _nativeNetwork(network).ffiLabel,
    activationHeight: parameters.nu63ActivationHeight,
    parameters: parameters,
  );

  @override
  zcash.IronwoodBuildResult build({
    required CryptoCurrencyNetwork network,
    required zcash.Zip318TransferPlan plan,
    required String seedHex,
    int account = 0,
  }) => zcash.buildNativeIronwoodTransaction(
    network: _nativeNetwork(network),
    targetHeight: plan.targetHeight,
    expiryHeight: plan.expiryHeight,
    regtestNu63ActivationHeight: network == CryptoCurrencyNetwork.regtest
        ? plan.parameters.nu63ActivationHeight
        : null,
    anchor: zcash.IronwoodAnchorSource.anchor(plan.ironwoodAnchorHex),
    inputs: const [],
    orchardSpends: [
      zcash.IronwoodBuildOrchardSpendNote.fromScannedNote(
        plan.funding.note,
        anchorHex: plan.orchardAnchorHex,
      ),
    ],
    orchardChangeZatoshis: plan.orchardChangeZatoshis,
    seedHex: seedHex,
    account: account,
    ironwoodOutput: zcash.IronwoodBuildOutput(
      address: plan.recipientAddress,
      valueZatoshis: plan.ironwoodOutputZatoshis,
    ),
    allowExperimentalIronwoodBuild: true,
  );
}

final class ZcashPreparedZip318Migration extends ZcashPreparedWalletSend {
  ZcashPreparedZip318Migration({
    required this.plan,
    required this.transaction,
    required super.sessionGeneration,
    required super.encodedRecipient,
    required super.selectedReceiver,
    required super.selectedReceiverAddress,
  }) : super(actualOutputPool: zcash.ProposalOutputPool.ironwood, memo: null) {
    if (!transaction.zip318Canonical ||
        !transaction.spendsOrchard ||
        transaction.ironwoodOutputZatoshis != plan.ironwoodOutputZatoshis ||
        transaction.orchardInputZatoshis != plan.funding.note.value ||
        transaction.orchardChangeZatoshis !=
            (plan.orchardChangeZatoshis ?? 0) ||
        transaction.feeZatoshis != plan.feeZatoshis ||
        transaction.expiryHeight != plan.expiryHeight ||
        transaction.ironwoodAnchor.toLowerCase() !=
            plan.ironwoodAnchorHex.toLowerCase()) {
      throw StateError('Native ZIP 318 build diverged from the approved plan');
    }
    requireValueConservation();
  }

  final zcash.Zip318TransferPlan plan;
  final zcash.IronwoodBuildResult transaction;

  @override
  int get amountZatoshis => plan.ironwoodOutputZatoshis;
  @override
  int get changeZatoshis => plan.orchardChangeZatoshis ?? 0;
  @override
  int get expiryHeight => plan.expiryHeight;
  @override
  int get feeZatoshis => plan.feeZatoshis;
  @override
  int get inputZatoshis => plan.funding.note.value;
  @override
  List<zcash.ZcashScannedNote> get selectedNotes => [plan.funding.note];
  @override
  ZcashSendSourcePool get sourcePool => ZcashSendSourcePool.orchard;
  @override
  String get transactionHex => transaction.transactionHex;
  @override
  String get txid => transaction.txid;
}

enum ZcashZip318PendingBroadcastState {
  prepared,
  submitting,
  acknowledged,
  indeterminate,
}

final class ZcashZip318PendingRecord {
  const ZcashZip318PendingRecord({
    required this.transactionHex,
    required this.txid,
    required this.sourceNullifier,
    required this.encodedRecipient,
    required this.selectedReceiverAddress,
    required this.amountZatoshis,
    required this.feeZatoshis,
    required this.orchardChangeZatoshis,
    required this.expiryHeight,
    required this.createdHeight,
    required this.state,
  });

  final String transactionHex;
  final String txid;
  final String sourceNullifier;
  final String encodedRecipient;
  final String selectedReceiverAddress;
  final int amountZatoshis;
  final int feeZatoshis;
  final int orchardChangeZatoshis;
  final int expiryHeight;
  final int createdHeight;
  final ZcashZip318PendingBroadcastState state;

  ZcashZip318PendingRecord withState(ZcashZip318PendingBroadcastState state) =>
      ZcashZip318PendingRecord(
        transactionHex: transactionHex,
        txid: txid,
        sourceNullifier: sourceNullifier,
        encodedRecipient: encodedRecipient,
        selectedReceiverAddress: selectedReceiverAddress,
        amountZatoshis: amountZatoshis,
        feeZatoshis: feeZatoshis,
        orchardChangeZatoshis: orchardChangeZatoshis,
        expiryHeight: expiryHeight,
        createdHeight: createdHeight,
        state: state,
      );

  Map<String, Object?> toJson() => {
    'version': 1,
    'transaction': transactionHex,
    'txid': txid,
    'source_nullifier': sourceNullifier,
    'encoded_recipient': encodedRecipient,
    'selected_receiver': selectedReceiverAddress,
    'amount_zatoshis': amountZatoshis,
    'fee_zatoshis': feeZatoshis,
    'orchard_change_zatoshis': orchardChangeZatoshis,
    'expiry_height': expiryHeight,
    'created_height': createdHeight,
    'state': state.name,
  };

  factory ZcashZip318PendingRecord.fromJson(Map<String, Object?> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported ZIP 318 pending record');
    }
    T field<T>(String key) => json[key] is T
        ? json[key] as T
        : throw FormatException('Invalid ZIP 318 pending field: $key');
    final stateName = field<String>('state');
    final states = ZcashZip318PendingBroadcastState.values.where(
      (candidate) => candidate.name == stateName,
    );
    if (states.length != 1) {
      throw const FormatException('Invalid ZIP 318 pending state');
    }
    return ZcashZip318PendingRecord(
      transactionHex: field('transaction'),
      txid: field('txid'),
      sourceNullifier: field('source_nullifier'),
      encodedRecipient: field('encoded_recipient'),
      selectedReceiverAddress: field('selected_receiver'),
      amountZatoshis: field('amount_zatoshis'),
      feeZatoshis: field('fee_zatoshis'),
      orchardChangeZatoshis: field('orchard_change_zatoshis'),
      expiryHeight: field('expiry_height'),
      createdHeight: field('created_height'),
      state: states.single,
    );
  }
}

final class ZcashZip318PendingState {
  ZcashZip318PendingState();

  final List<ZcashZip318PendingRecord> _records = [];

  List<ZcashZip318PendingRecord> get records => List.unmodifiable(_records);

  Set<String> reservedNullifiersAt(int chainHeight) => {
    for (final record in _records)
      if (chainHeight < record.expiryHeight) record.sourceNullifier,
  };

  void addPrepared(
    ZcashPreparedZip318Migration prepared, {
    required int createdHeight,
  }) {
    final nullifier = prepared.plan.funding.note.nullifier;
    if (nullifier == null || nullifier.isEmpty) {
      throw StateError('ZIP 318 source note has no nullifier');
    }
    if (_records.any(
      (record) =>
          record.txid.toLowerCase() == prepared.txid.toLowerCase() ||
          record.sourceNullifier == nullifier,
    )) {
      throw StateError(
        'ZIP 318 transaction or source note is already reserved',
      );
    }
    _records.add(
      ZcashZip318PendingRecord(
        transactionHex: prepared.transactionHex,
        txid: prepared.txid,
        sourceNullifier: nullifier,
        encodedRecipient: prepared.encodedRecipient,
        selectedReceiverAddress: prepared.selectedReceiverAddress,
        amountZatoshis: prepared.amountZatoshis,
        feeZatoshis: prepared.feeZatoshis,
        orchardChangeZatoshis: prepared.changeZatoshis,
        expiryHeight: prepared.expiryHeight,
        createdHeight: createdHeight,
        state: ZcashZip318PendingBroadcastState.prepared,
      ),
    );
  }

  void requireBroadcastable(
    ZcashPreparedZip318Migration prepared, {
    required int chainHeight,
  }) {
    final matches = _records.where(
      (record) => record.txid.toLowerCase() == prepared.txid.toLowerCase(),
    );
    if (matches.length != 1) {
      throw StateError('Persist the ZIP 318 reservation before broadcast');
    }
    final record = matches.single;
    if (record.state != ZcashZip318PendingBroadcastState.prepared ||
        record.transactionHex != prepared.transactionHex ||
        record.sourceNullifier != prepared.plan.funding.note.nullifier) {
      throw StateError('ZIP 318 pending record does not match the artifact');
    }
    if (chainHeight >= record.expiryHeight) {
      throw StateError('ZIP 318 migration expired and must be rebuilt');
    }
  }

  void mark(String txid, ZcashZip318PendingBroadcastState state) {
    final index = _records.indexWhere(
      (record) => record.txid.toLowerCase() == txid.toLowerCase(),
    );
    if (index < 0) throw StateError('Unknown ZIP 318 transaction');
    _records[index] = _records[index].withState(state);
  }

  void releasePrepared(String txid) {
    final index = _records.indexWhere(
      (record) => record.txid.toLowerCase() == txid.toLowerCase(),
    );
    if (index < 0) return;
    if (_records[index].state != ZcashZip318PendingBroadcastState.prepared) {
      throw StateError('A submitted ZIP 318 migration remains reserved');
    }
    _records.removeAt(index);
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'records': [for (final record in _records) record.toJson()],
  };

  factory ZcashZip318PendingState.fromJson(Map<String, Object?> json) {
    if (json['version'] != 1 || json['records'] is! List) {
      throw const FormatException('Invalid ZIP 318 pending state');
    }
    final state = ZcashZip318PendingState();
    for (final value in json['records']! as List) {
      if (value is! Map) {
        throw const FormatException('Invalid ZIP 318 pending record');
      }
      state._records.add(
        ZcashZip318PendingRecord.fromJson(value.cast<String, Object?>()),
      );
    }
    return state;
  }
}

final class ZcashZip318BroadcastReceipt {
  const ZcashZip318BroadcastReceipt({
    required this.txid,
    required this.sourceNullifier,
    required this.broadcastHeight,
  });

  final String txid;
  final String sourceNullifier;
  final int broadcastHeight;
}

abstract interface class ZcashZip318MigrationService {
  Future<ZcashPreparedZip318Migration> prepare(
    ZcashZip318PreparationRequest request,
  );

  Future<ZcashZip318BroadcastReceipt> broadcast({
    required ZcashPreparedZip318Migration prepared,
    required ZcashZip318PendingState pending,
    required zcash.Zip318BroadcastSession session,
    required int chainHeight,
    required Future<void> Function() persist,
    required Future<String> Function(String transactionHex) submit,
  });
}

final class ZcashProductionZip318MigrationService
    implements ZcashZip318MigrationService {
  ZcashProductionZip318MigrationService({
    this.backend = const ZcashNativeZip318Backend(),
    Random? random,
  }) : _random = random ?? Random.secure();

  final ZcashZip318Backend backend;
  final Random _random;

  @override
  Future<ZcashPreparedZip318Migration> prepare(
    ZcashZip318PreparationRequest request,
  ) async {
    if (!request.consent.isSatisfied) {
      throw StateError(
        'ZIP 318 migration consent is incomplete: '
        '${request.consent.unmetRequirements.join(', ')}',
      );
    }
    if (request.observedTipHeight < request.scheduledTransfer.broadcastHeight ||
        request.observedTipHeight >= request.scheduledTransfer.expiryHeight) {
      throw zcash.Zip318PlanException(
        zcash.Zip318PlanRefusal.offSchedule,
        'ZIP 318 migration is not due at height '
        '${request.observedTipHeight}',
      );
    }
    final activationHeight = request.parameters.nu63ActivationHeight;
    if (activationHeight == null) {
      throw StateError('ZIP 318 requires a known NU6.3 activation height');
    }
    if (request.observedTipHeight <= activationHeight) {
      throw zcash.Zip318PlanException(
        zcash.Zip318PlanRefusal.anchorBeforeActivation,
        'ZIP 318 requires an observed Ironwood tree above NU6.3 activation',
      );
    }
    final spent = {for (final spend in request.orchardSpends) spend.nullifier};
    final available = [
      for (final note in request.orchardNotes)
        if (note.nullifier != null &&
            !spent.contains(note.nullifier) &&
            !request.reservedNullifiers.contains(note.nullifier))
          note,
    ];
    final funding = zcash.Zip318FundingSelection.select(
      transfer: request.scheduledTransfer,
      notes: available,
    );
    final targetHeight = max(
      request.scheduledTransfer.broadcastHeight,
      request.observedTipHeight + 1,
    );
    final output = backend.resolveOutput(
      network: request.network,
      encodedRecipient: request.recipientAddress,
      amountZatoshis: request.scheduledTransfer.denominationZatoshis,
      targetHeight: targetHeight,
      expiryHeight: request.scheduledTransfer.expiryHeight,
    );
    if (output.actualOutputPool != zcash.ProposalOutputPool.ironwood ||
        output.selectedReceiver != zcash.ZcashAddressReceiverType.orchard) {
      throw StateError(
        'ZIP 318 must select an Orchard receiver and create Ironwood output',
      );
    }
    final anchors = await zcash.Zip318BoundaryAnchors.draw(
      activationHeight: request.parameters.nu63ActivationHeight,
      fundingNoteHeight: funding.note.height,
      observedTipHeight: request.observedTipHeight,
      broadcastHeight: request.scheduledTransfer.broadcastHeight,
      fetch: request.fetchTreeState,
      rng: _random,
      parameters: request.parameters,
    );
    final plan = backend.planTransfer(
      network: request.network,
      transfer: request.scheduledTransfer,
      funding: funding,
      anchors: anchors,
      observedTipHeight: request.observedTipHeight,
      recipientAddress: output.receiverAddress,
      ufvk: request.ufvk,
      parameters: request.parameters,
    );
    plan.checkDueAt(request.observedTipHeight);
    final transaction = backend.build(
      network: request.network,
      plan: plan,
      seedHex: request.seedHex,
    );
    return ZcashPreparedZip318Migration(
      plan: plan,
      transaction: transaction,
      sessionGeneration: request.sessionGeneration,
      encodedRecipient: output.encodedAddress,
      selectedReceiver: output.selectedReceiver,
      selectedReceiverAddress: output.receiverAddress,
    );
  }

  @override
  Future<ZcashZip318BroadcastReceipt> broadcast({
    required ZcashPreparedZip318Migration prepared,
    required ZcashZip318PendingState pending,
    required zcash.Zip318BroadcastSession session,
    required int chainHeight,
    required Future<void> Function() persist,
    required Future<String> Function(String transactionHex) submit,
  }) async {
    pending.requireBroadcastable(prepared, chainHeight: chainHeight);
    session.claim(prepared.plan, chainHeight: chainHeight);
    pending.mark(prepared.txid, ZcashZip318PendingBroadcastState.submitting);
    await persist();
    final String acknowledged;
    try {
      acknowledged = await submit(prepared.transactionHex);
    } catch (_) {
      pending.mark(
        prepared.txid,
        ZcashZip318PendingBroadcastState.indeterminate,
      );
      await persist();
      rethrow;
    }
    if (acknowledged.isNotEmpty &&
        acknowledged.toLowerCase() != prepared.txid.toLowerCase()) {
      pending.mark(
        prepared.txid,
        ZcashZip318PendingBroadcastState.indeterminate,
      );
      await persist();
      throw StateError('ZIP 318 node acknowledged a different transaction');
    }
    pending.mark(prepared.txid, ZcashZip318PendingBroadcastState.acknowledged);
    await persist();
    return ZcashZip318BroadcastReceipt(
      txid: prepared.txid,
      sourceNullifier: prepared.plan.funding.note.nullifier!,
      broadcastHeight: chainHeight,
    );
  }
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
