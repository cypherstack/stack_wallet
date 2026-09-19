import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
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
import 'package:wallet/wallet.dart' as eth;
import 'package:web3dart/web3dart.dart' as web3;

void main() {
  group('Rosen funding rejects unsafe transactions before RPC or signing', () {
    final trade = _rosenRequest(false);
    final recipient = TxRecipient(
      address: trade.payInAddress,
      amount: Amount(rawValue: BigInt.from(100000000), fractionDigits: 8),
      isChange: false,
      addressType: Ethereum(CryptoCurrencyNetwork.main).defaultAddressType,
    );
    final transaction = web3.Transaction(
      to: eth.EthereumAddress.fromHex(DefaultTokens.rsFiro.address),
      value: eth.EtherAmount.zero(),
      data: RosenProtocol.transferData(
        lockAddress: trade.payInAddress,
        amount: recipient.amount.raw,
        metadata: RosenExchange.validatedMetadata(trade),
      ).toUint8ListFromHex,
    );
    final prepared = TxData(
      recipients: [recipient],
      chainId: BigInt.one,
      web3dartTransaction: transaction,
    );
    Matcher rejected(String message) =>
        throwsA(isA<StateError>().having((e) => e.message, 'message', message));

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

      // These statuses drive existing swap history icons and notification polling.
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

          // A status poll captured before refresh must not restore old metadata.
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
  _FundingWallet({bool viewOnly = false}) : info = _FundingWalletInfo(viewOnly);

  @override
  final WalletInfo info;
  @override
  final Ethereum cryptoCurrency = Ethereum(CryptoCurrencyNetwork.main);
  @override
  final Prefs prefs = _FundingPrefs();

  static final rpcBoundary = UnsupportedError('Funding test RPC boundary');
  int rpcAttempts = 0;

  @override
  web3.Web3Client getEthClient() {
    rpcAttempts++;
    throw rpcBoundary;
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

Trade _rosenRequest(bool fromFiro) {
  final destination = fromFiro
      ? '0x00112233445566778899aabbccddeeff00112233'
      : RosenApi.firoLockAddress;
  final now = DateTime.utc(2020);
  return Trade(
    uuid: 'rosen-refresh-$fromFiro',
    tradeId: 'rosen-refresh-$fromFiro',
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
      'metadata': RosenProtocol.metadata(
        fromFiro: fromFiro,
        destination: destination,
        bridgeFee: BigInt.from(123),
        networkFee: BigInt.from(456),
      ),
    }),
  );
}
