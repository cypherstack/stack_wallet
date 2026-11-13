import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/zcash_wallet.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_account_session.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_send.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_wallet_state_controller.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

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
    coinName: 'zcash',
    isFailover: false,
    isDown: false,
    torEnabled: false,
    clearnetEnabled: true,
    isPrimary: true,
  );
}

final class SendClient
    implements ZcashLightwalletdSyncClient, ZcashLightwalletdSendClient {
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
      zcash.LightdInfo(chainName: 'main');

  @override
  Future<int> getTipHeight() async => 42;

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
  FixturePreparedSend({required super.sessionGeneration})
    : super(
        encodedRecipient: 'u1fixture',
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
    return FixturePreparedSend(sessionGeneration: request.sessionGeneration);
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

final class UnusedScanExecutor implements ZcashScanExecutor {
  @override
  Future<zcash.ZcashScanResult> scan(zcash.ScanInputEnvelope envelope) =>
      throw StateError('routing refusal must happen before scanning');
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

    final reviewed = prepared.copyWith(note: 'local-only review note');
    final confirmed = await wallet.confirmSend(txData: reviewed);

    expect(confirmed.txid, prepared.txid);
    expect(service.broadcastPrepared, isA<FixturePreparedSend>());
    expect(client.submitted, [
      Uint8List.fromList([0, 255, 16]),
    ]);
    await wallet.exit();
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
}

Future<ZcashWallet> _wallet(
  SendClient client,
  RecordingSendService service,
  String id,
) async {
  final wallet = await Wallet.create(
    walletInfo: WalletInfo(
      walletId: 'zcash-send-$id',
      name: 'Zcash send fixture',
      mainAddressType: AddressType.zcashUnified,
      coinName: 'zcash',
      restoreHeight: 43,
    ),
    mainDB: MainDB.instance,
    secureStorageInterface: MemorySecrets(),
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
  await wallet.init(isRestore: true);
  return wallet;
}
