import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:regtest_support/regtest_support.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/zcash_wallet.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_account_session.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_send.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_wallet_state_controller.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_zip318_migration.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../integration_test/zcash_regtest/zcash_stack_regtest_adapter.dart';
import '../support/isar_test_utils.dart';
import 'support/xelis_test_fakes.dart';

final class SendNodes extends Fake implements NodeService {
  @override
  NodeModel? getPrimaryNodeFor({required CryptoCurrency currency}) => NodeModel(
    host: 'https://send.example',
    port: 443,
    name: 'send',
    id: 'send',
    useSSL: true,
    enabled: true,
    coinName: currency.identifier,
    isFailover: false,
    isDown: false,
    torEnabled: false,
    clearnetEnabled: true,
    isPrimary: true,
  );
}

final class SendClient
    implements
        ZcashLightwalletdSyncClient,
        ZcashLightwalletdTransparentClient,
        ZcashLightwalletdSendClient {
  SendClient({this.chainName = 'main'});

  final String chainName;
  final List<Uint8List> submitted = [];

  @override
  Future<void> close() async {}

  @override
  Future<String?> getBlockHash(int height) async => null;

  @override
  Future<zcash.ZcashLightwalletdScanSource> getBlockRange(int start, int end) =>
      throw StateError('caught-up fixture must not request blocks');

  @override
  Future<zcash.LightdInfo> getInfo() async =>
      zcash.LightdInfo(chainName: chainName);

  @override
  Future<int> getTipHeight() async => 42;

  @override
  Future<ZcashTransparentActivityResult> getTransparentAddressActivity(
    List<String> addresses, {
    required int startHeight,
    required int chainHeight,
  }) async => ZcashTransparentActivityResult.empty;

  @override
  Future<zcash.ZcashTransparentRefresh> getTransparentRefresh(
    zcash.ZcashTransparentState state, {
    int maxRangeSize = 1000,
    int maxUtxos = 10000,
  }) async => zcash.ZcashTransparentRefresh(
    network: state.network,
    accountFingerprint: state.accountFingerprint,
    queriedAddresses: state.addresses,
    chainHeight: 42,
    chainTipHash: '44' * 32,
    canonicalBlockHashes: {42: '44' * 32},
    unspentOutputs: const [],
    observedSpends: const [],
  );

  @override
  Future<zcash.TreeState> getTreeState(int height) async => zcash.TreeState(
    hash: List.filled(32, '00').join(),
    height: height,
    time: 1,
  );

  @override
  Future<ZcashSubmissionAcknowledgement> submitTransaction(
    Uint8List transaction,
  ) async {
    submitted.add(Uint8List.fromList(transaction));
    return const ZcashSubmissionAcknowledgement(errorCode: 0, errorMessage: '');
  }
}

final class FixturePreparedSend extends ZcashPreparedWalletSend {
  FixturePreparedSend({
    required super.sessionGeneration,
    required String requestedAddress,
  }) : super(
         encodedRecipient: requestedAddress,
         selectedReceiver: zcash.ZcashAddressReceiverType.orchard,
         selectedReceiverAddress: 'u1selected-ironwood',
         actualOutputPool: zcash.ProposalOutputPool.ironwood,
         memo: Uint8List.fromList([0x68, 0x69]),
       );

  @override
  int get amountZatoshis => 40000;
  @override
  int get changeZatoshis => 50000;
  @override
  int get expiryHeight => 83;
  @override
  int get feeZatoshis => 10000;
  @override
  int get inputZatoshis => 100000;
  @override
  ZcashSendSourcePool get sourcePool => ZcashSendSourcePool.ironwood;
  @override
  List<zcash.ZcashScannedNote> get selectedNotes => const [
    zcash.ZcashScannedNote(
      height: 40,
      tx: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      output: 0,
      value: 100000,
      pool: 'ironwood',
      nullifier:
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
    ),
  ];
  @override
  String get transactionHex => '00ff10';
  @override
  String get txid => List.filled(32, '11').join();
}

final class RecordingSendService implements ZcashWalletSendService {
  ZcashSendPreparationRequest? request;
  ZcashPreparedWalletSend? broadcastPrepared;

  @override
  Future<ZcashPreparedWalletSend> prepare(
    ZcashSendPreparationRequest request,
  ) async {
    this.request = request;
    return FixturePreparedSend(
      sessionGeneration: request.sessionGeneration,
      requestedAddress: request.recipient,
    );
  }

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
    broadcastPrepared = prepared;
    await persist();
    await submit(prepared.transactionHex);
  }
}

final class RecordingZip318Service implements ZcashZip318MigrationService {
  ZcashZip318PreparationRequest? request;
  ZcashPreparedZip318Migration? broadcastPrepared;

  @override
  Future<ZcashPreparedZip318Migration> prepare(
    ZcashZip318PreparationRequest request,
  ) async {
    this.request = request;
    return _fixtureZip318Prepared(
      sessionGeneration: request.sessionGeneration,
      requestedAddress: request.recipientAddress,
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
    broadcastPrepared = prepared;
    pending.requireBroadcastable(prepared, chainHeight: chainHeight);
    session.claim(prepared.plan, chainHeight: chainHeight);
    pending.mark(prepared.txid, ZcashZip318PendingBroadcastState.submitting);
    await persist();
    await submit(prepared.transactionHex);
    pending.mark(prepared.txid, ZcashZip318PendingBroadcastState.acknowledged);
    await persist();
    return ZcashZip318BroadcastReceipt(
      txid: prepared.txid,
      sourceNullifier: prepared.plan.funding.note.nullifier!,
      broadcastHeight: chainHeight,
    );
  }
}

final class UnusedScanExecutor implements ZcashScanExecutor {
  @override
  Future<zcash.ZcashScanResult> scan(zcash.ScanInputEnvelope envelope) =>
      throw StateError('routing refusal must happen before scanning');
}

final class FixtureSpendMaterialProvider
    implements ZcashIronwoodSpendMaterialProvider {
  @override
  Future<zcash.ZcashSpendMaterial> acquire({
    required ZcashSendPreparationRequest request,
    required List<zcash.ZcashScannedNote> candidates,
  }) async => zcash.ZcashSpendMaterial.verified(
    accountFingerprint: request.state.accountFingerprint,
    pool: 'ironwood',
    anchorHeight: request.targetHeight - 1,
    anchorBlockHash: '44' * 32,
    scan: zcash.ZcashScanResult(
      scannedBlocks: 1,
      discoveredNotes: candidates.length,
      totalValue: candidates.fold(0, (sum, note) => sum + note.value),
      notes: candidates,
      scannedHeightRange: zcash.CompactBlockScanRange(
        start: candidates
            .map((note) => note.height)
            .reduce((left, right) => left < right ? left : right),
        end: request.targetHeight - 1,
      ),
      ironwoodAnchor: 'cc' * 32,
    ),
  );
}

final class FixtureIronwoodPaymentBackend
    implements zcash.IronwoodPaymentBackend {
  final List<zcash.IronwoodPaymentNativeRequest> builds = [];

  @override
  zcash.IronwoodFeeQuote quote(zcash.IronwoodPaymentNativeRequest request) {
    final input = request.ironwoodSpends.fold<int>(
      0,
      (sum, spend) => sum + spend.valueZatoshis,
    );
    final nonIronwood = request.outputs.fold<int>(
      0,
      (sum, output) => sum + output.valueZatoshis,
    );
    return zcash.IronwoodFeeQuote(
      network: zcash.ZcashAddressNetwork.regtest,
      feeZatoshis: 10000,
      feeRule: 'zip317',
      consensusBranchId: 'nu6.3',
      totalInputZatoshis: input,
      nonIronwoodOutputZatoshis: nonIronwood,
      maxIronwoodOutputZatoshis: input - nonIronwood - 10000,
      ironwoodSpends: request.ironwoodSpends.length,
      orchardSpends: 0,
      saplingSpends: 0,
      transparentInputs: 0,
    );
  }

  @override
  zcash.IronwoodBuildResult build(zcash.IronwoodPaymentNativeRequest request) {
    builds.add(request);
    final input = request.ironwoodSpends.fold<int>(
      0,
      (sum, spend) => sum + spend.valueZatoshis,
    );
    final nonIronwood = request.outputs.fold<int>(
      0,
      (sum, output) => sum + output.valueZatoshis,
    );
    final transparent = request.outputs.where(
      (output) => output.address.startsWith('t'),
    );
    final sapling = request.outputs.where(
      (output) => output.address.startsWith('z'),
    );
    return zcash.IronwoodBuildResult(
      network: zcash.ZcashAddressNetwork.regtest,
      transactionHex: 'ff' * 20,
      txid: 'ee' * 32,
      version: 'v6',
      expiryHeight: request.expiryHeight!,
      feeZatoshis: 10000,
      feeRule: 'zip317',
      proofValidity: 'real',
      ironwoodAnchor: request.anchorHex,
      ironwoodAnchorSource: 'anchor',
      vin: 0,
      vout: transparent.length,
      saplingOutputs: sapling.isEmpty ? 0 : 2,
      ironwoodActions: 1,
      ironwoodSpends: request.ironwoodSpends.length,
      ironwoodChangeOutputs: request.ironwoodChangeZatoshis == null ? 0 : 1,
      totalInputZatoshis: input,
      ironwoodInputZatoshis: input,
      ironwoodChangeZatoshis: request.ironwoodChangeZatoshis ?? 0,
      nonIronwoodOutputZatoshis: nonIronwood,
      ironwoodOutputZatoshis: request.ironwoodOutput.valueZatoshis!,
      rng: 'system',
    );
  }
}

final class FixtureParameterSource implements zcash.SaplingParameterSource {
  const FixtureParameterSource(this.bytes);

  final Map<String, List<int>> bytes;

  @override
  Stream<List<int>> open(zcash.SaplingParameterArtifact artifact) =>
      Stream.value(bytes[artifact.fileName]!);
}

ZcashPreparedZip318Migration _fixtureZip318Prepared({
  required int sessionGeneration,
  required String requestedAddress,
}) {
  const parameters = zcash.Zip318Parameters(
    nu63ActivationHeight: 10,
    meanDelayBlocks: 1,
    maxDelayBlocks: 2,
    anchorBoundaryModulus: 5,
    anchorAgeCapBoundaries: 8,
    expiryModulusBlocks: 100,
  );
  const transfer = zcash.Zip318ScheduledTransfer(
    denominationZatoshis: 1000000,
    feeZatoshis: 15000,
    broadcastHeight: 42,
    expiryHeight: 100,
  );
  final note = zcash.ZcashScannedNote(
    height: 11,
    tx: 'aa' * 32,
    output: 0,
    value: 2000000,
    pool: 'orchard',
    nullifier: 'bb' * 32,
    recipient: requestedAddress,
    rseed: 'cc' * 32,
    rho: 'dd' * 32,
    noteVersion: 'v2',
    witness: 'ee' * 40,
  );
  final plan = zcash.Zip318TransferPlan.forTransfer(
    transfer: transfer,
    funding: zcash.Zip318FundingSelection(note: note, changeZatoshis: 985000),
    anchorHeight: 20,
    orchardAnchorHex: '11' * 32,
    ironwoodAnchorHex: '22' * 32,
    observedTipHeight: 42,
    recipientAddress: requestedAddress,
    parameters: parameters,
  );
  return ZcashPreparedZip318Migration(
    plan: plan,
    transaction: zcash.IronwoodBuildResult(
      network: zcash.ZcashAddressNetwork.regtest,
      transactionHex: '0a0b0c',
      txid: '33' * 32,
      version: 'v6',
      consensusBranchId: 'nu6.3',
      expiryHeight: 100,
      feeZatoshis: 15000,
      feeRule: 'zip317',
      proofValidity: 'real',
      ironwoodAnchor: '22' * 32,
      ironwoodAnchorSource: 'anchor',
      vin: 0,
      vout: 0,
      ironwoodActions: 1,
      orchardSpends: 1,
      orchardActions: 2,
      orchardChangeOutputs: 1,
      zip318Canonical: true,
      totalInputZatoshis: 2000000,
      orchardInputZatoshis: 2000000,
      orchardChangeZatoshis: 985000,
      nonIronwoodOutputZatoshis: 0,
      ironwoodOutputZatoshis: 1000000,
      rng: 'system',
    ),
    sessionGeneration: sessionGeneration,
    encodedRecipient: requestedAddress,
    selectedReceiver: zcash.ZcashAddressReceiverType.orchard,
    selectedReceiverAddress: requestedAddress,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeTestIsar);
  late Directory root;

  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('stack_zcash_send_');
    StackFileSystem.setDesktopOverrideDir(root.path);
  });
  tearDownAll(() => root.delete(recursive: true));

  setUp(() async {
    await MainDB.instance.initMainDB();
    addTearDown(() async {
      if (MainDB.instance.isar.isOpen) await MainDB.instance.isar.close();
    });
  });

  test('note and prepared-send inspection is regtest-only', () {
    final wallet = ZcashWallet(CryptoCurrencyNetwork.main);

    expect(
      () => wallet.synchronizedStateInspection,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('regtest-only'),
        ),
      ),
    );
    expect(
      () => wallet.preparedSendFor(TxData()),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('regtest-only'),
        ),
      ),
    );
  });

  test('prepare and confirm preserve one exact backend artifact', () async {
    final client = SendClient();
    final service = RecordingSendService();
    final wallet = await _wallet(client, service, 'exact-artifact');
    final address = (await wallet.getCurrentReceivingAddress())!.value;

    final prepared = await wallet.prepareSend(
      txData: TxData(
        recipients: [
          TxRecipient(
            address: address,
            amount: Amount(rawValue: BigInt.from(40000), fractionDigits: 8),
            isChange: false,
            addressType: AddressType.zcashUnified,
          ),
        ],
        memo: 'hi',
      ),
    );

    expect(prepared.raw, '00ff10');
    expect(prepared.txid, List.filled(32, '11').join());
    expect(prepared.fee!.raw, BigInt.from(10000));
    expect(service.request!.memo, [0x68, 0x69]);
    expect(service.request!.amountZatoshis, 40000);
    expect(service.request!.targetHeight, 43);
    expect(service.request!.ironwoodChangeAddress, address);

    final reviewed = prepared.copyWith(note: 'local-only review note');
    final confirmed = await wallet.confirmSend(txData: reviewed);

    expect(confirmed.txid, prepared.txid);
    expect(service.broadcastPrepared, isA<FixturePreparedSend>());
    expect(client.submitted, [
      Uint8List.fromList([0, 255, 16]),
    ]);
    await wallet.exit();
  });

  test('regtest adapter preserves encoded address, selected receiver, actual '
      'pool, sources, change, and fee', () async {
    final client = SendClient(chainName: 'test');
    final service = RecordingSendService();
    final wallet = await _wallet(
      client,
      service,
      'typed-adapter',
      network: CryptoCurrencyNetwork.regtest,
    );
    const capabilities = ZcashStackTransferCapabilities();
    final receiver = await capabilities.receiver(
      wallet,
      ZcashRegtestPool.ironwood,
    );

    final prepared = await capabilities.prepare(
      wallet,
      TransferRequest(
        address: receiver,
        pool: ZcashRegtestPool.ironwood,
        value: BigInt.from(40000),
      ),
    );

    prepared.requireValueConserved();
    expect(prepared.native.encodedAddress, receiver);
    expect(prepared.native.selectedReceiver, ZcashRegtestReceiver.orchard);
    expect(prepared.native.selectedReceiverAddress, 'u1selected-ironwood');
    expect(prepared.native.actualOutputPool, ZcashRegtestPool.ironwood);
    expect(prepared.native.sourcePool, ZcashRegtestPool.ironwood);
    expect(prepared.sources.single.value, BigInt.from(100000));
    expect(prepared.change.single.value, BigInt.from(50000));
    expect(prepared.fee, BigInt.from(10000));

    final receipt = await capabilities.confirm(wallet, prepared);
    receipt.requireValueConserved();
    receipt.requireActualDestinationPool(ZcashRegtestPool.ironwood);
    expect(client.submitted, [
      Uint8List.fromList([0, 255, 16]),
    ]);
    await wallet.exit();
  });

  test('wallet migration path reserves, broadcasts, and restores ZIP 318 '
      'state', () async {
    final secrets = MemorySecrets();
    final client = SendClient(chainName: 'test');
    final migrationService = RecordingZip318Service();
    final wallet = await _wallet(
      client,
      RecordingSendService(),
      'zip318-wallet-path',
      network: CryptoCurrencyNetwork.regtest,
      migrationService: migrationService,
      secureStorage: secrets,
    );
    final recipient = (await wallet.getCurrentReceivingAddress())!.value;
    const transfer = zcash.Zip318ScheduledTransfer(
      denominationZatoshis: 1000000,
      feeZatoshis: 15000,
      broadcastHeight: 42,
      expiryHeight: 100,
    );
    const parameters = zcash.Zip318Parameters(
      nu63ActivationHeight: 10,
      meanDelayBlocks: 1,
      maxDelayBlocks: 2,
      anchorBoundaryModulus: 5,
      anchorAgeCapBoundaries: 8,
      expiryModulusBlocks: 100,
    );
    const consent = zcash.Zip318ConsentChecklist(
      disclosedPoolCrossingAmounts: true,
      displayedOrchardBalanceAtRisk: true,
      confirmedFullSchedule: true,
      presentedNetworkPrivacyOptions: true,
      separatesSyncFromBroadcast: true,
      limitsOverdueCatchUp: true,
    );

    final prepared = await wallet.prepareOrchardMigration(
      txData: TxData(
        recipients: [
          TxRecipient(
            address: recipient,
            amount: Amount(rawValue: BigInt.from(1000000), fractionDigits: 8),
            isChange: false,
            addressType: AddressType.zcashUnified,
          ),
        ],
      ),
      scheduledTransfer: transfer,
      parameters: parameters,
      consent: consent,
    );
    final native = wallet.preparedSendFor(prepared);
    expect(native, isA<ZcashPreparedZip318Migration>());
    expect(native.encodedRecipient, recipient);
    expect(native.selectedReceiver, zcash.ZcashAddressReceiverType.orchard);
    expect(native.actualOutputPool, zcash.ProposalOutputPool.ironwood);
    expect(prepared.raw, '0a0b0c');
    expect(prepared.fee!.raw, BigInt.from(15000));

    await wallet.confirmSend(txData: prepared);
    expect(migrationService.broadcastPrepared, same(native));
    expect(client.submitted, [
      Uint8List.fromList([10, 11, 12]),
    ]);
    await wallet.exit();

    final restoredService = RecordingZip318Service();
    final restored = await Wallet.load(
      walletId: 'zcash-send-zip318-wallet-path',
      mainDB: MainDB.instance,
      secureStorageInterface: secrets,
      nodeService: SendNodes(),
      prefs: SessionPrefs(),
    ) as ZcashWallet;
    restored.configureAccountSessionFactory(
      (network) => ZcashAccountSession(
        network: network,
        clientFactory: (_) => SendClient(chainName: 'test'),
      ),
    );
    restored.configureSendService(RecordingSendService());
    restored.configureZip318MigrationService(restoredService);
    restored.configureRegtestConsensus(nu63ActivationHeight: 130);
    await restored.init();
    await expectLater(
      restored.prepareOrchardMigration(
        txData: TxData(
          recipients: [
            TxRecipient(
              address: recipient,
              amount: Amount(rawValue: BigInt.from(1000000), fractionDigits: 8),
              isChange: false,
              addressType: AddressType.zcashUnified,
            ),
          ],
        ),
        scheduledTransfer: transfer,
        parameters: parameters,
        consent: consent,
      ),
      throwsA(isA<StateError>()),
    );
    expect(restoredService.request!.reservedNullifiers, {'bb' * 32});
    await restored.exit();
  });

  test(
    'confirmation refuses any replacement of prepared transaction bytes',
    () async {
      final service = RecordingSendService();
      final wallet = await _wallet(SendClient(), service, 'mismatch');
      final address = (await wallet.getCurrentReceivingAddress())!.value;
      final prepared = await wallet.prepareSend(
        txData: TxData(
          recipients: [
            TxRecipient(
              address: address,
              amount: Amount(rawValue: BigInt.from(40000), fractionDigits: 8),
              isChange: false,
              addressType: AddressType.zcashUnified,
            ),
          ],
        ),
      );

      await expectLater(
        wallet.confirmSend(txData: prepared.copyWith(raw: 'ff')),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        wallet.confirmSend(
          txData: prepared.copyWith(
            recipients: [
              prepared.recipients!.single.copyWith(
                address: 'u1review-tampered',
              ),
            ],
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect(service.broadcastPrepared, isNull);
      await wallet.cancelSend(txData: prepared);
      await wallet.exit();
    },
  );

  test(
    'production routing refuses memo bytes for actual transparent output',
    () async {
      const phrase =
          'abandon abandon abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon about';
      final seed = zcash.nativeMnemonicToSeed(phrase);
      final address = await zcash.deriveAddress(
        seedHex: seed.seedHex,
        network: zcash.ZcashNetwork.mainnet,
      );
      final state = zcash.ZcashWalletSyncState.atBirthday(
        cursor: zcash.ZcashLightwalletdSyncCursor.origin(height: 1),
        network: zcash.ZcashAddressNetwork.mainnet,
        accountFingerprint: 'fixture-account',
      );

      await expectLater(
        const ZcashProductionWalletSendService().prepare(
          ZcashSendPreparationRequest(
            network: CryptoCurrencyNetwork.main,
            sessionGeneration: 1,
            state: state,
            pendingSends: zcash.IronwoodPendingSendState(),
            syncClient: SendClient(),
            scanExecutor: UnusedScanExecutor(),
            seedHex: seed.seedHex,
            saplingChangeAddress: address.saplingAddress!,
            ironwoodChangeAddress: address.ua,
            recipient: address.transparentAddress!,
            amountZatoshis: 40000,
            memo: Uint8List.fromList([0, 255, 1]),
            targetHeight: 43,
            expiryHeight: 83,
            resolveSaplingProvingParameters: () =>
                throw StateError('must not resolve proving parameters'),
          ),
        ),
        throwsA(
          isA<zcash.ProposalRoutingException>().having(
            (e) => e.refusal,
            'refusal',
            zcash.ProposalRoutingRefusal.transparentMemo,
          ),
        ),
      );
    },
  );

  test('production routing does not reject a valid transparent output before '
      'selecting source funds', () async {
    const phrase =
        'abandon abandon abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon about';
    final seed = zcash.nativeMnemonicToSeed(phrase);
    final address = await zcash.deriveAddress(
      seedHex: seed.seedHex,
      network: zcash.ZcashNetwork.mainnet,
    );
    final state = zcash.ZcashWalletSyncState.atBirthday(
      cursor: zcash.ZcashLightwalletdSyncCursor.origin(height: 1),
      network: zcash.ZcashAddressNetwork.mainnet,
      accountFingerprint: 'fixture-account',
    );

    await expectLater(
      const ZcashProductionWalletSendService().prepare(
        ZcashSendPreparationRequest(
          network: CryptoCurrencyNetwork.main,
          sessionGeneration: 1,
          state: state,
          pendingSends: zcash.IronwoodPendingSendState(),
          syncClient: SendClient(),
          scanExecutor: UnusedScanExecutor(),
          seedHex: seed.seedHex,
          saplingChangeAddress: address.saplingAddress!,
          ironwoodChangeAddress: address.ua,
          recipient: address.transparentAddress!,
          amountZatoshis: 40000,
          memo: null,
          targetHeight: 43,
          expiryHeight: 83,
          resolveSaplingProvingParameters: () =>
              throw StateError('no source funds in this fixture'),
        ),
      ),
      throwsA(isNot(isA<UnsupportedError>())),
    );
  });

  test('production prepares and durably reserves Ironwood payments to every '
      'ordinary destination pool', () async {
    const phrase =
        'abandon abandon abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon about';
    final seed = zcash.nativeMnemonicToSeed(phrase);
    final address = await zcash.deriveAddress(
      seedHex: seed.seedHex,
      network: zcash.ZcashNetwork.regtest,
    );
    final parameterRoot = await Directory.systemTemp.createTemp(
      'stack_zcash_routed_params_',
    );
    addTearDown(() => parameterRoot.delete(recursive: true));
    final spendBytes = [1, 2, 3];
    final outputBytes = [4, 5, 6];
    final manifest = zcash.SaplingParameterManifest(
      version: 'fixture-v1',
      spend: zcash.SaplingParameterArtifact(
        fileName: 'spend.params',
        expectedBytes: spendBytes.length,
        sha256Hex: sha256.convert(spendBytes).toString(),
      ),
      output: zcash.SaplingParameterArtifact(
        fileName: 'output.params',
        expectedBytes: outputBytes.length,
        sha256Hex: sha256.convert(outputBytes).toString(),
      ),
    );
    final parameters =
        await zcash.SaplingProvingParameterCache(
          cacheRoot: parameterRoot,
          manifest: manifest,
        ).resolve(
          source: FixtureParameterSource({
            manifest.spend.fileName: spendBytes,
            manifest.output.fileName: outputBytes,
          }),
        );
    var provingParameterResolutions = 0;

    for (final destination in [
      (
        address: address.ua,
        pool: zcash.ProposalOutputPool.ironwood,
        pendingPool: zcash.IronwoodDestinationPool.ironwood,
      ),
      (
        address: address.saplingAddress!,
        pool: zcash.ProposalOutputPool.sapling,
        pendingPool: zcash.IronwoodDestinationPool.sapling,
      ),
      (
        address: address.transparentAddress!,
        pool: zcash.ProposalOutputPool.transparent,
        pendingPool: zcash.IronwoodDestinationPool.transparent,
      ),
    ]) {
      final state = _ironwoodFundedState();
      final pending = zcash.IronwoodPendingSendState();
      final backend = FixtureIronwoodPaymentBackend();
      final prepared =
          await ZcashProductionWalletSendService(
            spendMaterialProvider: FixtureSpendMaterialProvider(),
            ironwoodPaymentBackend: backend,
          ).prepare(
            ZcashSendPreparationRequest(
              network: CryptoCurrencyNetwork.regtest,
              sessionGeneration: 1,
              state: state,
              pendingSends: pending,
              syncClient: SendClient(chainName: 'test'),
              scanExecutor: UnusedScanExecutor(),
              seedHex: seed.seedHex,
              saplingChangeAddress: address.saplingAddress!,
              ironwoodChangeAddress: address.ua,
              recipient: destination.address,
              amountZatoshis: 40000,
              memo: null,
              targetHeight: 43,
              expiryHeight: 83,
              resolveSaplingProvingParameters: () async {
                provingParameterResolutions++;
                return parameters;
              },
              regtestNu63ActivationHeight: 40,
            ),
          );

      expect(prepared, isA<ZcashPreparedIronwoodSend>());
      expect(prepared.actualOutputPool, destination.pool);
      expect(prepared.encodedRecipient, destination.address);
      expect(pending.records, hasLength(1));
      expect(pending.records.single.recipient, destination.address);
      expect(
        pending.records.single.actualDestinationPool,
        destination.pendingPool,
      );
      expect(pending.records.single.amountZatoshis, 40000);
      expect(pending.records.single.feeZatoshis, 10000);
      final build = backend.builds.single;
      expect(
        build.provingParameters != null,
        destination.pool == zcash.ProposalOutputPool.sapling,
      );
      if (destination.pool == zcash.ProposalOutputPool.ironwood) {
        expect(build.outputs, isEmpty);
        expect(build.ironwoodOutput.address, destination.address);
      } else {
        expect(build.outputs.single.address, destination.address);
        expect(build.ironwoodOutput.address, address.ua);
      }
    }

    expect(provingParameterResolutions, 1);
  });

  test('routed payment broadcast preserves restart, rejection, and '
      'indeterminate reservation semantics', () async {
    final acknowledged = await _prepareTransparentIronwoodPayment();
    final restored = zcash.IronwoodPendingSendState.fromJson(
      acknowledged.pending.toJson(),
    );
    var persisted = 0;
    await acknowledged.service.broadcast(
      prepared: acknowledged.prepared,
      pendingSends: restored,
      chainHeight: 43,
      persist: () async => persisted++,
      submit: (_) async =>
          const ZcashSubmissionAcknowledgement(errorCode: 0, errorMessage: ''),
    );
    expect(persisted, 1);
    expect(
      restored.records.single.broadcastState,
      zcash.IronwoodPendingBroadcastState.acknowledged,
    );

    final rejected = await _prepareTransparentIronwoodPayment();
    await expectLater(
      rejected.service.broadcast(
        prepared: rejected.prepared,
        pendingSends: rejected.pending,
        chainHeight: 43,
        persist: () async {},
        submit: (_) async => throw const ZcashBroadcastRejectedException(
          errorCode: -26,
          message: 'consensus rejected',
        ),
      ),
      throwsA(
        isA<zcash.IronwoodBroadcastException>().having(
          (error) => error.refusal,
          'refusal',
          zcash.IronwoodBroadcastRefusal.rejected,
        ),
      ),
    );
    expect(rejected.pending.records, isEmpty);

    final indeterminate = await _prepareTransparentIronwoodPayment();
    await expectLater(
      indeterminate.service.broadcast(
        prepared: indeterminate.prepared,
        pendingSends: indeterminate.pending,
        chainHeight: 43,
        persist: () async {},
        submit: (_) async => throw StateError('connection closed'),
      ),
      throwsA(
        isA<zcash.IronwoodBroadcastException>().having(
          (error) => error.refusal,
          'refusal',
          zcash.IronwoodBroadcastRefusal.undetermined,
        ),
      ),
    );
    expect(
      indeterminate.pending.records.single.broadcastState,
      zcash.IronwoodPendingBroadcastState.indeterminate,
    );
  });
}

zcash.ZcashWalletSyncState _ironwoodFundedState() {
  const fingerprint = 'fixture-account';
  final state = zcash.ZcashWalletSyncState.atBirthday(
    cursor: zcash.ZcashLightwalletdSyncCursor.origin(height: 1),
    network: zcash.ZcashAddressNetwork.regtest,
    accountFingerprint: fingerprint,
  );
  state.ironwood.apply(
    zcash.ZcashScanResult(
      scannedBlocks: 1,
      discoveredNotes: 1,
      totalValue: 100000,
      notes: [
        zcash.ZcashScannedNote(
          height: 40,
          tx: 'aa' * 32,
          output: 0,
          value: 100000,
          pool: 'ironwood',
          nullifier: 'bb' * 32,
          commitmentPosition: 0,
          recipient: 'uregtest1-wallet-note',
          rseed: '11' * 32,
          rho: '22' * 32,
          noteVersion: 'v3',
          witness: '33' * 40,
        ),
      ],
      scannedHeightRange: const zcash.CompactBlockScanRange(start: 40, end: 40),
      ironwoodAnchor: 'cc' * 32,
    ),
    accountFingerprint: fingerprint,
  );
  return state;
}

Future<
  ({
    ZcashProductionWalletSendService service,
    zcash.IronwoodPendingSendState pending,
    ZcashPreparedWalletSend prepared,
  })
>
_prepareTransparentIronwoodPayment() async {
  const phrase =
      'abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon about';
  final seed = zcash.nativeMnemonicToSeed(phrase);
  final address = await zcash.deriveAddress(
    seedHex: seed.seedHex,
    network: zcash.ZcashNetwork.regtest,
  );
  final pending = zcash.IronwoodPendingSendState();
  final service = ZcashProductionWalletSendService(
    spendMaterialProvider: FixtureSpendMaterialProvider(),
    ironwoodPaymentBackend: FixtureIronwoodPaymentBackend(),
  );
  final prepared = await service.prepare(
    ZcashSendPreparationRequest(
      network: CryptoCurrencyNetwork.regtest,
      sessionGeneration: 1,
      state: _ironwoodFundedState(),
      pendingSends: pending,
      syncClient: SendClient(chainName: 'test'),
      scanExecutor: UnusedScanExecutor(),
      seedHex: seed.seedHex,
      saplingChangeAddress: address.saplingAddress!,
      ironwoodChangeAddress: address.ua,
      recipient: address.transparentAddress!,
      amountZatoshis: 40000,
      memo: null,
      targetHeight: 43,
      expiryHeight: 83,
      resolveSaplingProvingParameters: () =>
          throw StateError('transparent output needs no Sapling parameters'),
      regtestNu63ActivationHeight: 40,
    ),
  );
  return (service: service, pending: pending, prepared: prepared);
}

Future<ZcashWallet> _wallet(
  SendClient client,
  RecordingSendService service,
  String id, {
  CryptoCurrencyNetwork network = CryptoCurrencyNetwork.main,
  ZcashZip318MigrationService? migrationService,
  SecureStorageInterface? secureStorage,
}) async {
  final currency = Zcash(network);
  final wallet = await Wallet.create(
    walletInfo: WalletInfo(
      walletId: 'zcash-send-$id',
      name: 'Zcash send fixture',
      mainAddressType: AddressType.zcashUnified,
      coinName: currency.identifier,
      restoreHeight: 43,
    ),
    mainDB: MainDB.instance,
    secureStorageInterface: secureStorage ?? MemorySecrets(),
    nodeService: SendNodes(),
    prefs: SessionPrefs(),
    mnemonic:
        'abandon abandon abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon about',
    mnemonicPassphrase: '',
  ) as ZcashWallet;
  wallet.configureAccountSessionFactory(
    (network) =>
        ZcashAccountSession(network: network, clientFactory: (_) => client),
  );
  wallet.configureSendService(service);
  if (migrationService != null) {
    wallet.configureZip318MigrationService(migrationService);
  }
  if (network == CryptoCurrencyNetwork.regtest) {
    wallet.configureRegtestConsensus(nu63ActivationHeight: 130);
  }
  await wallet.init(isRestore: true);
  return wallet;
}
