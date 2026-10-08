import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/exceptions/electrumx/no_such_transaction.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/trade_wallet_lookup.dart';
import 'package:stackwallet/exceptions/json_rpc/json_rpc_exception.dart';
import 'package:stackwallet/services/trade_service.dart';
import 'package:stackwallet/models/exchange/change_now/cn_exchange_transaction_status.dart';
import 'package:stackwallet/services/exchange/exchange.dart';
import 'package:stackwallet/services/exchange/rosen/rosen_api.dart';
import 'package:stackwallet/services/exchange/rosen/rosen_exchange.dart';
import 'package:stackwallet/services/exchange/rosen/rosen_funding.dart';
import 'package:stackwallet/services/exchange/rosen/rosen_protocol.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/default_eth_tokens.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/exceptions/exchange/exchange_exception.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/ethereum_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/firo_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/firo_op_return.dart';
import 'package:wallet/wallet.dart' as eth;
import 'package:web3dart/json_rpc.dart' show RPCError;
import 'package:web3dart/web3dart.dart' as web3;

import 'rosen/rosen_test_utils.dart';

void main() {
  group('Rosen funding rejects unsafe transactions before RPC or signing', () {
    final trade = _rosenRequest(false);
    late Directory directory;
    late Box<Trade> trades;
    final recipient = TxRecipient(
      address: trade.payInAddress,
      amount: Amount(rawValue: BigInt.from(100000000), fractionDigits: 8),
      isChange: false,
      addressType: Ethereum(CryptoCurrencyNetwork.main).defaultAddressType,
    );
    final maxFee = BigInt.from(30);
    final priorityFee = BigInt.from(2);
    const gasLimit = 120000;
    const nonce = 7;
    final transaction = web3.Transaction(
      to: eth.EthereumAddress.fromHex(DefaultTokens.rsFiro.address),
      value: eth.EtherAmount.zero(),
      data: RosenProtocol.transferData(
        lockAddress: trade.payInAddress,
        amount: recipient.amount.raw,
        metadata: RosenExchange.validatedMetadata(trade),
      ).toUint8ListFromHex,
      maxGas: gasLimit,
      nonce: nonce,
      maxFeePerGas: eth.EtherAmount.inWei(maxFee),
      maxPriorityFeePerGas: eth.EtherAmount.inWei(priorityFee),
    );
    final prepared = TxData(
      recipients: [recipient],
      fee: Amount(rawValue: BigInt.from(gasLimit) * maxFee, fractionDigits: 18),
      chainId: BigInt.one,
      nonce: nonce,
      web3dartTransaction: transaction,
    );
    Matcher rejected(String message) =>
        throwsA(isA<StateError>().having((e) => e.message, 'message', message));

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('rosen-guards-');
      final hive = DB.instance.hive;
      hive.init(directory.path);
      if (!hive.isAdapterRegistered(Trade.typeId)) {
        hive.registerAdapter(TradeAdapter());
      }
      trades = await hive.openBox<Trade>(DB.boxNameTradesV2);
      await trades.put(trade.uuid, trade);
    });

    tearDown(() async {
      await trades.close();
      await directory.delete(recursive: true);
    });

    test(
      'view-only and wrong-source wallets cannot prepare or confirm',
      () async {
        for (final (wallet, request) in [
          (_FundingWallet(viewOnly: true), trade),
          (_FundingWallet(), _rosenRequest(true)),
        ]) {
          await expectLater(
            RosenFunding.prepareSend(wallet: wallet, trade: request),
            rejected('Choose a spendable wallet on the source network.'),
          );
          await expectLater(
            RosenFunding.confirmSend(
              wallet: wallet,
              trade: request,
              txData: prepared,
            ),
            rejected('Invalid bridge source wallet.'),
          );
          expect(wallet.rpcAttempts, 0);
        }
      },
    );

    test(
      'recipient, amount and recipient-count changes are rejected',
      () async {
        final wallet = _FundingWallet();
        final half = Amount(rawValue: BigInt.from(50000000), fractionDigits: 8);
        final cases = <String, List<TxRecipient>?>{
          'missing recipients': null,
          'empty recipients': [],
          'change only': [recipient.copyWith(isChange: true)],
          'wrong amount': [recipient.copyWith(amount: half)],
          'two recipients with the correct total': [
            recipient.copyWith(amount: half),
            recipient.copyWith(amount: half),
          ],
          'wrong recipient': [
            recipient.copyWith(address: DefaultTokens.rsFiro.address),
          ],
        };
        for (final entry in cases.entries) {
          await expectLater(
            RosenFunding.confirmSend(
              wallet: wallet,
              trade: trade,
              txData: TxData(
                recipients: entry.value,
                chainId: prepared.chainId,
                web3dartTransaction: transaction,
              ),
            ),
            rejected('The transaction does not match this bridge swap.'),
            reason: entry.key,
          );
        }
        expect(wallet.rpcAttempts, 0);
      },
    );

    test(
      'invalid rsFIRO envelopes are rejected and release the send lock',
      () async {
        final wallet = _FundingWallet();
        final cases = <String, TxData>{
          'missing transaction': TxData(
            recipients: [recipient],
            chainId: BigInt.one,
          ),
          'missing chain': TxData(
            recipients: [recipient],
            web3dartTransaction: transaction,
          ),
          'wrong chain': prepared.copyWith(chainId: BigInt.from(11155111)),
          'wrong displayed fee': prepared.copyWith(
            fee: Amount(
              rawValue: prepared.fee!.raw + BigInt.one,
              fractionDigits: 18,
            ),
          ),
          'wrong prepared nonce': prepared.copyWith(nonce: nonce + 1),
          for (final entry in <String, web3.Transaction>{
            'missing token': web3.Transaction(
              value: transaction.value,
              data: transaction.data,
            ),
            'wrong token': transaction.copyWith(
              to: eth.EthereumAddress.fromHex(trade.payInAddress),
            ),
            'native ETH value': transaction.copyWith(
              value: eth.EtherAmount.inWei(BigInt.one),
            ),
            'missing calldata': web3.Transaction(
              to: transaction.to,
              value: transaction.value,
            ),
            'altered calldata': transaction.copyWith(
              data: ('${transaction.data!.toHex}00').toUint8ListFromHex,
            ),
            'legacy gas price': transaction.copyWith(
              gasPrice: eth.EtherAmount.inWei(BigInt.one),
            ),
            'zero gas limit': transaction.copyWith(maxGas: 0),
            'wrong transaction nonce': transaction.copyWith(nonce: nonce + 1),
            'priority above max fee': transaction.copyWith(
              maxPriorityFeePerGas: eth.EtherAmount.inWei(maxFee + BigInt.one),
            ),
          }.entries)
            entry.key: prepared.copyWith(web3dartTransaction: entry.value),
        };
        for (final entry in cases.entries) {
          await expectLater(
            RosenFunding.confirmSend(
              wallet: wallet,
              trade: trade,
              txData: entry.value,
            ),
            rejected('Invalid rsFIRO bridge transaction.'),
            reason: entry.key,
          );
        }
        expect(wallet.rpcAttempts, 0);

        // The valid control passes these guards after every failed attempt, but
        // stops at the fake client's boundary without node access or signing.
        await expectLater(
          RosenFunding.confirmSend(
            wallet: wallet,
            trade: trade,
            txData: prepared,
          ),
          throwsA(same(_FundingWallet.rpcBoundary)),
        );
        expect(wallet.rpcAttempts, 1);
      },
    );

    test('an unresolved journal blocks another swap from the wallet', () async {
      final wallet = _FundingWallet();
      final pending = _rosenRequest(false, suffix: '-pending').copyWith(
        payInTxid: '11' * 32,
        status: 'Confirming',
        other: jsonEncode({
          ...jsonDecode(_rosenRequest(false).other!) as Map,
          RosenFunding.fundingKey: {
            'walletId': wallet.walletId,
            'txid': '11' * 32,
            'raw': '0200',
            'state': RosenFunding.submittingState,
          },
        }),
      );
      await trades.put(pending.uuid, pending);

      await expectLater(
        RosenFunding.confirmSend(
          wallet: wallet,
          trade: trade,
          txData: prepared,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'A previous Rosen deposit from this wallet is still being '
                'submitted.',
          ),
        ),
      );
      expect(wallet.rpcAttempts, 1);
    });
  });

  test(
    'Rosen is a swap provider with distinct native and Ethereum assets',
    () async {
      final exchange = Exchange.fromName('Rosen Bridge');
      expect(exchange, same(RosenExchange.instance));
      expect(exchange.supportsRefundAddress, isFalse);

      final currencies = (await exchange.getAllCurrencies(false)).value!;
      expect(currencies, hasLength(2));
      final firo = currencies.singleWhere((coin) => coin.ticker == 'FIRO');
      final token = currencies.singleWhere((coin) => coin.ticker == 'rsFIRO');
      expect(firo.getFuzzyNet(), 'firo');
      expect(firo.tokenContract, isNull);
      expect(token.getFuzzyNet(), 'eth');
      expect(token.tokenContract, DefaultTokens.rsFiro.address);
      expect(token.supportsEstimatedRate, isTrue);
      expect(token.supportsFixedRate, isFalse);
      expect((await exchange.getAllCurrencies(true)).value, isEmpty);

      // These statuses drive existing history icons and notification polling.
      for (final status in [
        'Waiting',
        'Confirming',
        'Exchanging',
        'Finished',
      ]) {
        expect(
          changeNowTransactionStatusFromStringIgnoreCase(status).name,
          status,
        );
      }
    },
  );
  test(
    'a late swap poll cannot erase a bridge deposit or completion',
    () async {
      final directory = await Directory.systemTemp.createTemp('rosen-trades-');
      final db = DB.instance;
      db.hive.init(directory.path);
      if (!db.hive.isAdapterRegistered(Trade.typeId)) {
        db.hive.registerAdapter(TradeAdapter());
      }
      final box = await db.hive.openBox<Trade>(DB.boxNameTradesV2);
      final service = TradesService();
      final waiting = Trade.fromMap({
        'uuid': 'rosen-test',
        'tradeId': 'rosen-test',
        'rateType': 'estimated',
        'direction': 'direct',
        'timestamp': '2026-09-17T00:00:00Z',
        'updatedAt': '2026-09-17T00:00:00Z',
        'payInCurrency': 'FIRO',
        'payInAmount': '1',
        'payInAddress': 'lock',
        'payInNetwork': 'firo',
        'payInExtraId': '',
        'payInTxid': '',
        'payOutCurrency': 'rsFIRO',
        'payOutAmount': '0.9',
        'payOutAddress': 'recipient',
        'payOutNetwork': 'eth',
        'payOutExtraId': '',
        'payOutTxid': '',
        'refundAddress': '',
        'refundExtraId': '',
        'status': 'Waiting',
        'exchangeName': RosenExchange.exchangeName,
      });
      try {
        await service.add(trade: waiting, shouldNotifyListeners: false);
        final funded = waiting.copyWith(
          payInTxid: 'deposit',
          status: 'Confirming',
        );
        await Future.wait([
          service.edit(trade: funded, shouldNotifyListeners: false),
          service.edit(trade: waiting, shouldNotifyListeners: false),
        ]);
        expect(service.get(waiting.tradeId)!.payInTxid, 'deposit');
        expect(service.get(waiting.tradeId)!.status, 'Confirming');
        await service.edit(
          trade: funded.copyWith(status: 'Verifying'),
          shouldNotifyListeners: false,
        );
        await service.edit(trade: funded, shouldNotifyListeners: false);
        expect(service.get(waiting.tradeId)!.status, 'Verifying');
        final finished = funded.copyWith(
          status: 'Finished',
          payOutTxid: 'payout',
        );
        await Future.wait([
          service.edit(trade: finished, shouldNotifyListeners: false),
          service.edit(trade: funded, shouldNotifyListeners: false),
        ]);
        expect(service.get(waiting.tradeId)!.status, 'Finished');
        expect(service.get(waiting.tradeId)!.payOutTxid, 'payout');
      } finally {
        service.dispose();
        await box.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('Rosen records signed funding durably and idempotently', () async {
    final directory = await Directory.systemTemp.createTemp('rosen-funding-');
    final db = DB.instance;
    db.hive.init(directory.path);
    if (!db.hive.isAdapterRegistered(Trade.typeId)) {
      db.hive.registerAdapter(TradeAdapter());
    }
    final lookupAdapter = TradeWalletLookupAdapter();
    if (!db.hive.isAdapterRegistered(lookupAdapter.typeId)) {
      db.hive.registerAdapter(lookupAdapter);
    }
    final trades = await db.hive.openBox<Trade>(DB.boxNameTradesV2);
    final lookups = await db.hive.openBox<TradeWalletLookup>(
      DB.boxNameTradeLookup,
    );
    final trade = _rosenRequest(false);
    final txid = '11' * 32;
    const raw = '0200';
    try {
      await trades.put(trade.uuid, trade);
      await expectLater(
        RosenFunding.recordFundingIntent(
          trade: trade.copyWith(
            updatedAt: trade.updatedAt.add(const Duration(seconds: 1)),
          ),
          walletId: 'wallet',
          txid: txid,
          raw: raw,
        ),
        throwsA(
          isA<ExchangeException>().having(
            (e) => e.type,
            'type',
            ExchangeExceptionType.quoteChanged,
          ),
        ),
      );
      await RosenFunding.recordFundingIntent(
        trade: trade,
        walletId: 'wallet',
        txid: txid,
        raw: raw,
      );
      await RosenFunding.recordFundingIntent(
        trade: trade,
        walletId: 'wallet',
        txid: txid,
        raw: raw,
      );

      final stored = trades.get(trade.uuid)!;
      expect(stored.payInTxid, txid);
      expect(stored.status, 'Confirming');
      expect((jsonDecode(stored.other!) as Map)[RosenFunding.fundingKey], {
        'walletId': 'wallet',
        'txid': txid,
        'raw': raw,
        'state': RosenFunding.submittingState,
      });
      expect(lookups.get(trade.uuid)!.txid, txid);
      await expectLater(
        RosenFunding.recordFundingIntent(
          trade: trade,
          walletId: 'wallet',
          txid: '22' * 32,
          raw: raw,
        ),
        throwsStateError,
      );
      await expectLater(
        RosenFunding.recordFundingIntent(
          trade: trade,
          walletId: 'wallet',
          txid: txid,
          raw: '0300',
        ),
        throwsStateError,
      );

      final repairable = _rosenRequest(false, suffix: '-lookup-repair');
      await trades.put(repairable.uuid, repairable);
      await lookups.close();
      await RosenFunding.recordFundingIntent(
        trade: repairable,
        walletId: 'wallet',
        txid: '33' * 32,
        raw: raw,
      );
      expect(
        _fundingState(trades.get(repairable.uuid)!),
        RosenFunding.submittingState,
      );
    } finally {
      if (lookups.isOpen) await lookups.close();
      await trades.close();
      await directory.delete(recursive: true);
    }
  });

  test('Rosen replays only the journaled chain transaction', () async {
    final directory = await Directory.systemTemp.createTemp('rosen-recovery-');
    final db = DB.instance;
    db.hive.init(directory.path);
    if (!db.hive.isAdapterRegistered(Trade.typeId)) {
      db.hive.registerAdapter(TradeAdapter());
    }
    final lookupAdapter = TradeWalletLookupAdapter();
    if (!db.hive.isAdapterRegistered(lookupAdapter.typeId)) {
      db.hive.registerAdapter(lookupAdapter);
    }
    final trades = await db.hive.openBox<Trade>(DB.boxNameTradesV2);
    final lookups = await db.hive.openBox<TradeWalletLookup>(
      DB.boxNameTradeLookup,
    );
    const raw = '0x0200';
    final txid = web3.bytesToHex(
      web3.keccak256(raw.toUint8ListFromHex),
      include0x: true,
    );

    Future<Trade> journal(
      String suffix,
      _RecoveryClient client, {
      int? nonce,
    }) async {
      final trade = _recoveryTrade(false, suffix: suffix);
      final wallet = _FundingWallet(
        client: client,
        walletId: 'recovery-wallet-$suffix',
      );
      await trades.put(trade.uuid, trade);
      await RosenFunding.recordFundingIntent(
        trade: trade,
        walletId: wallet.walletId,
        txid: txid,
        raw: raw,
        nonce: nonce,
        sourceHeight: nonce == null ? null : 25992000,
      );
      return RosenFunding.recoverFundingIntent(wallet: wallet, trade: trade);
    }

    final http = RosenTestHttp((url) {
      expect(url.host, 'api.ergoplatform.com');
      return {
        'items': [rosenFeeBox()],
        'total': 1,
      };
    });
    try {
      await http.run(() async {
        final rejected = _RecoveryClient(txid: txid, failures: 1);
        await expectLater(journal('rejected', rejected), throwsStateError);
        var stored = trades.get(
          _recoveryTrade(false, suffix: 'rejected').uuid,
        )!;
        expect(_fundingState(stored), RosenFunding.submittingState);
        await lookups.delete(stored.uuid);
        final wallet = _FundingWallet(
          client: rejected,
          walletId: 'recovery-wallet-rejected',
        );
        await RosenFunding.recoverFundingIntent(wallet: wallet, trade: stored);
        stored = trades.get(stored.uuid)!;
        expect(_fundingState(stored), RosenFunding.broadcastState);
        expect(rejected.sentRaw, [raw, raw]);
        expect(lookups.get(stored.uuid)!.walletIds, [
          'recovery-wallet-rejected',
        ]);

        final lost = _RecoveryClient(txid: txid, loseFirstResponse: true);
        final recovered = await journal('lost', lost);
        expect(_fundingState(recovered), RosenFunding.broadcastState);
        expect(lost.sentRaw, [raw]);
        expect(lost.lookups, 2);

        final receiptOnly = _RecoveryClient(txid: txid, receiptKnown: true);
        final receiptRecovered = await journal('receipt', receiptOnly);
        expect(_fundingState(receiptRecovered), RosenFunding.broadcastState);
        expect(receiptOnly.sentRaw, isEmpty);

        final blockIndexed = _RecoveryClient(
          txid: txid,
          confirmedNonce: 8,
          nonceTransitionHeight: 25992025,
          blockTransactionHash: txid,
        );
        final blockRecovered = await journal(
          'block-indexed',
          blockIndexed,
          nonce: 7,
        );
        expect(_fundingState(blockRecovered), RosenFunding.broadcastState);
        expect(blockRecovered.status, 'Confirming');
        expect(blockIndexed.sentRaw, isEmpty);

        final delegatedNonce = _RecoveryClient(
          txid: txid,
          confirmedNonce: 8,
          nonceTransitionHeight: 25992025,
          includeNonceTransaction: false,
        );
        final delegated = await journal(
          'delegated-nonce',
          delegatedNonce,
          nonce: 7,
        );
        expect(delegated.status, 'Failed');
        expect(RosenFunding.fundingWalletId(delegated), isNull);
        expect(delegatedNonce.sentRaw, isEmpty);

        final pendingNonce = _RecoveryClient(
          txid: txid,
          confirmedNonce: 8,
          nonceTransitionHeight: 25992200,
        );
        await expectLater(
          journal('pending-nonce', pendingNonce, nonce: 7),
          throwsStateError,
        );
        final pendingTrade = trades.get(
          _recoveryTrade(false, suffix: 'pending-nonce').uuid,
        )!;
        expect(_fundingState(pendingTrade), RosenFunding.needsAttentionState);
        expect(RosenFunding.fundingWalletId(pendingTrade), isNotNull);
        expect(pendingNonce.sentRaw, isEmpty);

        final malformedBlock = _RecoveryClient(
          txid: txid,
          confirmedNonce: 8,
          nonceTransitionHeight: 25992025,
          malformedBlock: true,
        );
        await expectLater(
          journal('malformed-block', malformedBlock, nonce: 7),
          throwsFormatException,
        );
        final malformedTrade = trades.get(
          _recoveryTrade(false, suffix: 'malformed-block').uuid,
        )!;
        expect(RosenFunding.fundingWalletId(malformedTrade), isNotNull);
        expect(malformedBlock.sentRaw, isEmpty);

        final prunedState = _RecoveryClient(
          txid: txid,
          confirmedNonce: 8,
          historicalStateUnavailableBefore: 25992052,
        );
        await expectLater(
          journal('pruned-state', prunedState, nonce: 7),
          throwsStateError,
        );
        final pruned = trades.get(
          _recoveryTrade(false, suffix: 'pruned-state').uuid,
        )!;
        expect(_fundingState(pruned), RosenFunding.needsAttentionState);
        expect(RosenFunding.fundingWalletId(pruned), isNotNull);
        expect(prunedState.sentRaw, isEmpty);

        final prunedExact = _RecoveryClient(
          txid: txid,
          confirmedNonce: 8,
          historicalStateUnavailableBefore: 25992052,
          knownAfterLookups: 2,
        );
        final prunedRecovered = await journal(
          'pruned-exact',
          prunedExact,
          nonce: 7,
        );
        expect(_fundingState(prunedRecovered), RosenFunding.broadcastState);
        expect(prunedExact.sentRaw, isEmpty);

        final prunedBlock = _RecoveryClient(
          txid: txid,
          confirmedNonce: 8,
          nonceTransitionHeight: 25992025,
          blockRpcError: 'block history pruned',
        );
        await expectLater(
          journal('pruned-block', prunedBlock, nonce: 7),
          throwsStateError,
        );
        final blockMissing = trades.get(
          _recoveryTrade(false, suffix: 'pruned-block').uuid,
        )!;
        expect(_fundingState(blockMissing), RosenFunding.needsAttentionState);
        expect(RosenFunding.fundingWalletId(blockMissing), isNotNull);
        expect(prunedBlock.sentRaw, isEmpty);

        final prunedBlockExact = _RecoveryClient(
          txid: txid,
          confirmedNonce: 8,
          nonceTransitionHeight: 25992025,
          blockRpcError: 'block history pruned',
          knownAfterLookups: 2,
        );
        final blockFound = await journal(
          'pruned-block-exact',
          prunedBlockExact,
          nonce: 7,
        );
        expect(_fundingState(blockFound), RosenFunding.broadcastState);
        expect(prunedBlockExact.sentRaw, isEmpty);

        final unavailable = _RecoveryClient(
          txid: txid,
          confirmedNonce: 8,
          historicalStateUnavailableBefore: 25992052,
          historicalStateError: 'historical state query rate limited',
        );
        await expectLater(
          journal('history-rpc-error', unavailable, nonce: 7),
          throwsA(isA<RPCError>()),
        );
        final unavailableTrade = trades.get(
          _recoveryTrade(false, suffix: 'history-rpc-error').uuid,
        )!;
        expect(RosenFunding.fundingWalletId(unavailableTrade), isNotNull);
        expect(unavailable.sentRaw, isEmpty);

        const firoRaw =
            '0100000001000000000000000000000000000000000000000000000000000000'
            '00000000000000000000ffffffff0100000000000000000000000000';
        const conflictRaw =
            '0100000001000000000000000000000000000000000000000000000000000000'
            '00000000000000000000ffffffff0101000000000000000000000000';
        final firoTxid = firoTransactionFromHex(firoRaw).txid;
        final conflictTxid = decodeFiroTransaction(conflictRaw).txid;
        final firoTrade = _recoveryTrade(true, suffix: 'firo');
        final electrum = _RecoveryElectrumClient(
          txid: firoTxid,
          raw: firoRaw,
          loseFirstResponse: true,
        );
        final firoWallet = _FiroRecoveryWallet(electrum);
        await trades.put(firoTrade.uuid, firoTrade);
        await RosenFunding.recordFundingIntent(
          trade: firoTrade,
          walletId: firoWallet.walletId,
          txid: firoTxid,
          raw: firoRaw,
        );
        final firoRecovered = await RosenFunding.recoverFundingIntent(
          wallet: firoWallet,
          trade: firoTrade,
        );
        expect(_fundingState(firoRecovered), RosenFunding.broadcastState);
        expect(electrum.sentRaw, [firoRaw]);
        expect(electrum.lookups, 2);

        final historyFiro = _recoveryTrade(true, suffix: 'firo-history');
        final historyElectrum = _RecoveryElectrumClient(
          txid: firoTxid,
          raw: firoRaw,
          conflictTxid: firoTxid,
          conflictRaw: firoRaw,
        )..conflictVisible = true;
        final historyFiroWallet = _FiroRecoveryWallet(historyElectrum);
        await trades.put(historyFiro.uuid, historyFiro);
        await RosenFunding.recordFundingIntent(
          trade: historyFiro,
          walletId: historyFiroWallet.walletId,
          txid: firoTxid,
          raw: firoRaw,
          sourceHeight: 1378335,
          firoInputs: [
            {'txid': '00' * 32, 'vout': 0, 'scripthash': 'input-script'},
          ],
        );
        final historyRecovered = await RosenFunding.recoverFundingIntent(
          wallet: historyFiroWallet,
          trade: historyFiro,
        );
        expect(_fundingState(historyRecovered), RosenFunding.broadcastState);
        expect(historyElectrum.candidateLookups, 1);
        expect(historyElectrum.sentRaw, isEmpty);

        final mismatchedFiro = _recoveryTrade(true, suffix: 'firo-mismatch');
        final mismatchedElectrum = _RecoveryElectrumClient(
          txid: firoTxid,
          raw: firoRaw,
          conflictTxid: conflictTxid,
          conflictRaw: firoRaw,
        )..conflictVisible = true;
        final mismatchedWallet = _FiroRecoveryWallet(mismatchedElectrum);
        await trades.put(mismatchedFiro.uuid, mismatchedFiro);
        await RosenFunding.recordFundingIntent(
          trade: mismatchedFiro,
          walletId: mismatchedWallet.walletId,
          txid: firoTxid,
          raw: firoRaw,
          sourceHeight: 1378335,
          firoInputs: [
            {'txid': '00' * 32, 'vout': 0, 'scripthash': 'input-script'},
          ],
        );
        await expectLater(
          RosenFunding.recoverFundingIntent(
            wallet: mismatchedWallet,
            trade: mismatchedFiro,
          ),
          throwsFormatException,
        );
        expect(
          RosenFunding.fundingWalletId(trades.get(mismatchedFiro.uuid)!),
          mismatchedWallet.walletId,
        );
        expect(mismatchedElectrum.sentRaw, isEmpty);

        final rejectedFiro = _recoveryTrade(true, suffix: 'firo-rejected');
        final rejectedElectrum = _RecoveryElectrumClient(
          txid: firoTxid,
          raw: firoRaw,
          rpcFailure: true,
          conflictTxid: conflictTxid,
          conflictRaw: conflictRaw,
        );
        final rejectedFiroWallet = _FiroRecoveryWallet(rejectedElectrum);
        await trades.put(rejectedFiro.uuid, rejectedFiro);
        await RosenFunding.recordFundingIntent(
          trade: rejectedFiro,
          walletId: rejectedFiroWallet.walletId,
          txid: firoTxid,
          raw: firoRaw,
          sourceHeight: 1378335,
          firoInputs: [
            {'txid': '11' * 32, 'vout': 0, 'scripthash': 'input-script'},
            {'txid': '00' * 32, 'vout': 0, 'scripthash': 'input-script'},
          ],
        );
        await expectLater(
          RosenFunding.recoverFundingIntent(
            wallet: rejectedFiroWallet,
            trade: rejectedFiro,
          ),
          throwsStateError,
        );
        final rejectedFiroStored = trades.get(rejectedFiro.uuid)!;
        expect(
          _fundingState(rejectedFiroStored),
          RosenFunding.needsAttentionState,
        );
        expect(rejectedFiroStored.status, 'Verifying');
        expect(
          RosenFunding.fundingWalletId(rejectedFiroStored),
          rejectedFiroWallet.walletId,
        );
        await expectLater(
          RosenFunding.recoverFundingIntent(
            wallet: rejectedFiroWallet,
            trade: rejectedFiroStored,
          ),
          throwsStateError,
        );
        expect(
          RosenFunding.fundingWalletId(trades.get(rejectedFiro.uuid)!),
          rejectedFiroWallet.walletId,
        );
        rejectedElectrum.conflictHeight = 1378326;
        final superseded = await RosenFunding.recoverFundingIntent(
          wallet: rejectedFiroWallet,
          trade: trades.get(rejectedFiro.uuid)!,
        );
        expect(superseded.status, 'Failed');
        expect(_fundingState(superseded), RosenFunding.failedState);
        expect(RosenFunding.fundingWalletId(superseded), isNull);
        expect(rejectedElectrum.sentRaw, [firoRaw]);

        final rateLimited = _RecoveryClient(
          txid: txid,
          failures: 1,
          rpcFailure: true,
        );
        await expectLater(
          journal('rate-limited', rateLimited),
          throwsA(isA<RPCError>()),
        );
        var retrying = trades.get(
          _recoveryTrade(false, suffix: 'rate-limited').uuid,
        )!;
        expect(_fundingState(retrying), RosenFunding.submittingState);
        retrying = await RosenFunding.recoverFundingIntent(
          wallet: _FundingWallet(
            client: rateLimited,
            walletId: 'recovery-wallet-rate-limited',
          ),
          trade: retrying,
        );
        expect(_fundingState(retrying), RosenFunding.broadcastState);
        expect(rateLimited.sentRaw, [raw, raw]);

        final wrongChain = _RecoveryClient(
          txid: txid,
          chainId: BigInt.from(11155111),
        );
        await expectLater(
          journal('wrong-chain', wrongChain),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'The Ethereum node must use mainnet.',
            ),
          ),
        );
        expect(wrongChain.sentRaw, isEmpty);

        final nonceTooLow = _RecoveryClient(
          txid: txid,
          failures: 1,
          rpcFailure: true,
          rpcMessage: 'nonce too low',
          confirmedNonce: 7,
        );
        await expectLater(
          journal('nonce', nonceTooLow, nonce: 7),
          throwsStateError,
        );
        var nonceTrade = trades.get(
          _recoveryTrade(false, suffix: 'nonce').uuid,
        )!;
        expect(_fundingState(nonceTrade), RosenFunding.needsAttentionState);
        nonceTooLow.confirmedNonce = 8;
        nonceTrade = await RosenFunding.recoverFundingIntent(
          wallet: _FundingWallet(
            client: nonceTooLow,
            walletId: 'recovery-wallet-nonce',
          ),
          trade: nonceTrade,
        );
        expect(nonceTrade.status, 'Failed');
        expect(RosenFunding.fundingWalletId(nonceTrade), isNull);
        expect(nonceTooLow.sentRaw, [raw]);

        final stale = _rosenRequest(false, suffix: 'stale');
        final staleClient = _RecoveryClient(txid: txid);
        final staleWallet = _FundingWallet(
          client: staleClient,
          walletId: 'recovery-wallet-stale',
        );
        await trades.put(stale.uuid, stale);
        await RosenFunding.recordFundingIntent(
          trade: stale,
          walletId: staleWallet.walletId,
          txid: txid,
          raw: raw,
        );
        await expectLater(
          RosenFunding.recoverFundingIntent(wallet: staleWallet, trade: stale),
          throwsStateError,
        );
        final staleStored = trades.get(stale.uuid)!;
        expect(staleStored.status, 'Verifying');
        expect(_fundingState(staleStored), RosenFunding.needsAttentionState);
        expect(staleClient.sentRaw, isEmpty);
        await trades.put(
          staleStored.uuid,
          staleStored.copyWith(status: 'Confirming'),
        );
        await expectLater(
          RosenFunding.recoverFundingIntent(
            wallet: staleWallet,
            trade: staleStored,
          ),
          throwsStateError,
        );
        expect(trades.get(stale.uuid)!.status, 'Verifying');
      });
    } finally {
      await lookups.close();
      await trades.close();
      await directory.delete(recursive: true);
    }
  });

  test(
    'Rosen refresh retains the request and rejects funded or stale saves',
    () async {
      final directory = await Directory.systemTemp.createTemp('rosen-refresh-');
      final db = DB.instance;
      db.hive.init(directory.path);
      if (!db.hive.isAdapterRegistered(Trade.typeId)) {
        db.hive.registerAdapter(TradeAdapter());
      }
      final box = await db.hive.openBox<Trade>(DB.boxNameTradesV2);
      final service = TradesService();
      final changed = isA<ExchangeException>().having(
        (e) => e.type,
        'type',
        ExchangeExceptionType.quoteChanged,
      );
      try {
        for (final fromFiro in [true, false]) {
          final initial = _rosenRequest(fromFiro);
          await service.add(trade: initial, shouldNotifyListeners: false);
          final quote = RosenQuote(
            bridgeFee: BigInt.from(456),
            networkFee: BigInt.from(123),
            minimum: BigInt.from(580),
            receiveAmount: BigInt.from(100000000 - 579),
          );
          var refreshed = await RosenExchange.saveRefreshedTrade(
            initial,
            quote,
          );
          expect(refreshed.uuid, initial.uuid);
          expect(refreshed.payInAmount, initial.payInAmount);
          expect(refreshed.payOutAddress, initial.payOutAddress);
          expect(
            refreshed.payOutAmount,
            initial.payOutAmount,
          ); // Same total, new components.
          expect(refreshed.other, isNot(initial.other));
          expect(
            (jsonDecode(refreshed.other!) as Map).containsKey('metadata'),
            isFalse,
          );
          expect(
            RosenExchange.validatedMetadata(refreshed),
            RosenProtocol.metadata(
              fromFiro: fromFiro,
              destination: initial.payOutAddress,
              bridgeFee: quote.bridgeFee,
              networkFee: quote.networkFee,
            ),
          );
          expect(
            () => RosenExchange.currentUnfunded(initial),
            throwsA(changed),
          );
          await expectLater(
            RosenExchange.saveRefreshedTrade(initial, quote),
            throwsA(changed),
          );

          // A poll captured before refresh must not restore old quote data.
          await service.edit(trade: initial, shouldNotifyListeners: false);
          expect(box.get(initial.uuid)!.other, refreshed.other);
          expect(box.get(initial.uuid)!.updatedAt, refreshed.updatedAt);
          for (final fees in [(700, 200), (50, 20)]) {
            final nextQuote = RosenQuote(
              bridgeFee: BigInt.from(fees.$1),
              networkFee: BigInt.from(fees.$2),
              minimum: BigInt.from(fees.$1 + fees.$2 + 1),
              receiveAmount: BigInt.from(100000000 - fees.$1 - fees.$2),
            );
            refreshed = await RosenExchange.saveRefreshedTrade(
              refreshed,
              nextQuote,
            );
            expect(
              refreshed.payOutAmount,
              RosenProtocol.formatAmount(nextQuote.receiveAmount),
            );
            expect(
              RosenExchange.validatedMetadata(refreshed),
              RosenProtocol.metadata(
                fromFiro: fromFiro,
                destination: initial.payOutAddress,
                bridgeFee: nextQuote.bridgeFee,
                networkFee: nextQuote.networkFee,
              ),
            );
          }
          await expectLater(
            RosenExchange.saveRefreshedTrade(
              refreshed,
              RosenQuote(
                bridgeFee: BigInt.one,
                networkFee: BigInt.one,
                minimum: BigInt.from(100000001),
                receiveAmount: BigInt.from(99999998),
              ),
            ),
            throwsFormatException,
          );
          expect(
            RosenExchange.sameVersion(box.get(initial.uuid)!, refreshed),
            isTrue,
          );
          final funded = refreshed.copyWith(
            payInTxid: 'deposit',
            status: 'Confirming',
          );
          await service.edit(trade: funded, shouldNotifyListeners: false);
          await expectLater(
            RosenExchange.saveRefreshedTrade(refreshed, quote),
            throwsStateError,
          );
          expect(
            () => RosenExchange.refreshCandidate(funded, quote),
            throwsStateError,
          );
          expect(
            () => RosenExchange.refreshCandidate(
              refreshed.copyWith(status: 'Finished'),
              quote,
            ),
            throwsStateError,
          );
          await service.edit(trade: initial, shouldNotifyListeners: false);
          final stored = box.get(initial.uuid)!;
          expect(stored.payInTxid, 'deposit');
          expect(stored.status, 'Confirming');
          expect(stored.other, refreshed.other);
          expect(stored.payOutAmount, refreshed.payOutAmount);
        }
      } finally {
        service.dispose();
        await box.close();
        await directory.delete(recursive: true);
      }
    },
  );
}

class _FundingWallet extends Fake implements EthereumWallet {
  _FundingWallet({
    bool viewOnly = false,
    this.client,
    this.walletId = 'funding-wallet',
  }) : info = _FundingWalletInfo(viewOnly);

  @override
  final WalletInfo info;
  @override
  final Ethereum cryptoCurrency = Ethereum(CryptoCurrencyNetwork.main);
  @override
  final Prefs prefs = _FundingPrefs();
  @override
  final String walletId;
  final web3.Web3Client? client;

  static final rpcBoundary = UnsupportedError('Funding test RPC boundary');
  int rpcAttempts = 0;

  @override
  web3.Web3Client getEthClient() {
    rpcAttempts++;
    if (client != null) return client!;
    throw rpcBoundary;
  }

  @override
  Future<eth.EthereumAddress> getMyWeb3Address() async =>
      eth.EthereumAddress.fromHex('0x00112233445566778899aabbccddeeff00112233');
}

class _RecoveryClient extends Fake implements web3.Web3Client {
  _RecoveryClient({
    required this.txid,
    this.failures = 0,
    this.loseFirstResponse = false,
    this.rpcFailure = false,
    this.rpcMessage = 'rejected',
    this.confirmedNonce = 0,
    this.nonceTransitionHeight,
    this.blockTransactionHash,
    this.includeNonceTransaction = true,
    this.malformedBlock = false,
    this.blockRpcError,
    this.historicalStateUnavailableBefore,
    this.historicalStateError = 'missing trie node',
    this.knownAfterLookups,
    BigInt? chainId,
    this.receiptKnown = false,
  }) : chainId = chainId ?? BigInt.one;

  final String txid;
  int failures;
  final bool loseFirstResponse;
  final bool rpcFailure;
  final String rpcMessage;
  int confirmedNonce;
  final int? nonceTransitionHeight;
  final String? blockTransactionHash;
  final bool includeNonceTransaction;
  final bool malformedBlock;
  final String? blockRpcError;
  final int? historicalStateUnavailableBefore;
  final String historicalStateError;
  final int? knownAfterLookups;
  final BigInt chainId;
  final bool receiptKnown;
  bool known = false;
  int lookups = 0;
  final sentRaw = <String>[];

  @override
  Future<web3.TransactionInformation?> getTransactionByHash(String hash) async {
    lookups++;
    expect(hash, txid);
    if (!known && (knownAfterLookups == null || lookups < knownAfterLookups!)) {
      return null;
    }
    return web3.TransactionInformation.fromMap({
      'blockHash': null,
      'blockNumber': null,
      'from': '0x00112233445566778899aabbccddeeff00112233',
      'gas': '21000',
      'gasPrice': '1',
      'hash': txid,
      'input': '0x00',
      'nonce': '0',
      'to': '0x00112233445566778899aabbccddeeff00112233',
      'transactionIndex': null,
      'value': '0',
      'v': '1',
      'r': '0x1',
      's': '0x1',
    });
  }

  @override
  Future<String> sendRawTransaction(Uint8List transaction) async {
    sentRaw.add(web3.bytesToHex(transaction, include0x: true));
    if (failures > 0) {
      failures--;
      if (rpcFailure) throw RPCError(-32000, rpcMessage, null);
      throw StateError('rejected');
    }
    if (loseFirstResponse && !known) {
      known = true;
      throw StateError('response lost');
    }
    known = true;
    return txid;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<BigInt> getChainId() async => chainId;

  @override
  Future<int> getBlockNumber() async => 25992101;

  @override
  Future<int> getTransactionCount(
    eth.EthereumAddress address, {
    web3.BlockNum? atBlock,
  }) async {
    if (atBlock?.useAbsolute == true &&
        historicalStateUnavailableBefore != null &&
        atBlock!.blockNum < historicalStateUnavailableBefore!) {
      throw RPCError(-32000, historicalStateError, null);
    }
    final transition = nonceTransitionHeight;
    if (transition != null && atBlock?.useAbsolute == true) {
      return atBlock!.blockNum < transition
          ? confirmedNonce - 1
          : confirmedNonce;
    }
    return confirmedNonce;
  }

  @override
  Future<web3.TransactionReceipt?> getTransactionReceipt(String hash) async {
    expect(hash, txid);
    if (!receiptKnown) return null;
    return web3.TransactionReceipt(
      transactionHash: txid.toUint8ListFromHex,
      transactionIndex: 0,
      blockHash: Uint8List(32),
      cumulativeGasUsed: BigInt.zero,
    );
  }

  @override
  Future<T> makeRPCCall<T>(String function, [List<dynamic>? params]) async {
    expect(function, 'eth_getBlockByNumber');
    expect(params, hasLength(2));
    expect(params![1], isTrue);
    if (nonceTransitionHeight != null) {
      expect(params[0], '0x${nonceTransitionHeight!.toRadixString(16)}');
    }
    if (blockRpcError case final error?) {
      throw RPCError(-32000, error, null);
    }
    return <String, dynamic>{
      'number': params[0],
      'transactions': [
        if (malformedBlock)
          txid
        else if (includeNonceTransaction)
          {
            'from': '0x00112233445566778899aabbccddeeff00112233',
            'nonce': '0x7',
            'hash': blockTransactionHash ?? '0x${'aa' * 32}',
          }
        else
          {
            'from': '0x112233445566778899aabbccddeeff0011223344',
            'nonce': '0x1',
            'hash': '0x${'bb' * 32}',
          },
      ],
    } as T;
  }
}

class _FiroRecoveryWallet extends Fake implements FiroWallet {
  _FiroRecoveryWallet(this.electrumXClient);

  @override
  final ElectrumXClient electrumXClient;
  @override
  final Firo cryptoCurrency = Firo(CryptoCurrencyNetwork.main);
  @override
  final WalletInfo info = _FundingWalletInfo(false);
  @override
  final String walletId = 'firo-recovery-wallet';

  @override
  Future<int> fetchChainHeight({int retries = 1}) async => 1378335;
}

class _RecoveryElectrumClient extends Fake implements ElectrumXClient {
  _RecoveryElectrumClient({
    required this.txid,
    required this.raw,
    this.loseFirstResponse = false,
    this.rpcFailure = false,
    this.conflictTxid,
    this.conflictRaw,
  });

  final String txid;
  final String raw;
  final bool loseFirstResponse;
  final bool rpcFailure;
  final String? conflictTxid;
  final String? conflictRaw;
  bool conflictVisible = false;
  int conflictHeight = 1378335;
  bool known = false;
  int lookups = 0;
  int candidateLookups = 0;
  final sentRaw = <String>[];

  @override
  Future<dynamic> request({
    required String command,
    List<dynamic> args = const [],
    String? requestID,
    int retries = 2,
    Duration requestTimeout = const Duration(seconds: 60),
  }) async {
    expect(command, 'blockchain.transaction.get');
    if (args.length == 2 &&
        args[1] == false &&
        args.first == conflictTxid &&
        (conflictTxid != txid || lookups > 0)) {
      candidateLookups++;
      if (conflictRaw == null) {
        throw StateError('Missing conflict raw transaction.');
      }
      return conflictRaw;
    }
    lookups++;
    expect(args, [txid, false]);
    if (!known) throw NoSuchTransactionException('not found', txid);
    return raw;
  }

  @override
  Future<List<Map<String, dynamic>>> getHistory({
    required String scripthash,
    String? requestID,
  }) async {
    expect(scripthash, 'input-script');
    return [
      if (conflictVisible && conflictTxid != null)
        {'tx_hash': conflictTxid, 'height': conflictHeight},
    ];
  }

  @override
  Future<String> broadcastTransaction({
    required String rawTx,
    String? requestID,
  }) async {
    sentRaw.add(rawTx);
    if (rpcFailure) {
      conflictVisible = true;
      throw JsonRpcException('transaction was rejected by network rules');
    }
    if (loseFirstResponse && !known) {
      known = true;
      throw StateError('response lost');
    }
    known = true;
    return txid;
  }
}

class _FundingWalletInfo extends Fake implements WalletInfo {
  _FundingWalletInfo(this.isViewOnly);

  @override
  final bool isViewOnly;
}

class _FundingPrefs extends Fake implements Prefs {
  @override
  bool get useTor => false;
}

String _fundingState(Trade trade) =>
    (jsonDecode(trade.other!) as Map)[RosenFunding.fundingKey]['state']
        as String;

Trade _recoveryTrade(bool fromFiro, {required String suffix}) {
  final trade = _rosenRequest(fromFiro, suffix: suffix);
  final amount = BigInt.from(10000000000);
  final quote = RosenQuote.fromRegisters(
    rosenFeeRegisters,
    fromFiro: fromFiro,
    height: fromFiro ? 1378335 : 25992101,
    amount: amount,
  );
  final data = jsonDecode(trade.other!) as Map<String, dynamic>;
  return trade.copyWith(
    payInAmount: RosenProtocol.formatAmount(amount),
    payOutAmount: RosenProtocol.formatAmount(quote.receiveAmount),
    other: jsonEncode({
      ...data,
      'bridgeFee': quote.bridgeFee.toString(),
      'networkFee': quote.networkFee.toString(),
    }),
  );
}

Trade _rosenRequest(bool fromFiro, {String suffix = ''}) {
  final destination = fromFiro
      ? '0x00112233445566778899aabbccddeeff00112233'
      : RosenApi.firoLockAddress;
  final now = DateTime.utc(2020);
  return Trade(
    uuid: 'rosen-refresh-$fromFiro$suffix',
    tradeId: 'rosen-refresh-$fromFiro$suffix',
    rateType: 'estimated',
    direction: 'direct',
    timestamp: now,
    updatedAt: now,
    payInCurrency: fromFiro ? 'FIRO' : 'rsFIRO',
    payInAmount: '1',
    payInAddress: fromFiro
        ? RosenApi.firoLockAddress
        : RosenApi.ethereumLockAddress,
    payInNetwork: fromFiro ? 'firo' : 'eth',
    payInExtraId: '',
    payInTxid: '',
    payOutCurrency: fromFiro ? 'rsFIRO' : 'FIRO',
    payOutAmount: '0.99999421',
    payOutAddress: destination,
    payOutNetwork: fromFiro ? 'eth' : 'firo',
    payOutExtraId: '',
    payOutTxid: '',
    refundAddress: '',
    refundExtraId: '',
    status: 'Waiting',
    exchangeName: RosenExchange.exchangeName,
    other: jsonEncode({
      'version': 1,
      'bridgeFee': '123',
      'networkFee': '456',
      'tokenContract': DefaultTokens.rsFiro.address,
    }),
  );
}
