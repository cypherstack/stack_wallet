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
import 'package:stackwallet/services/exchange/rosen/rosen_protocol.dart';
import 'package:stackwallet/exceptions/exchange/exchange_exception.dart';

void main() {
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
      expect(token.tokenContract, RosenApi.rsFiroContract);
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

  test('Rosen refresh retains the request and rejects funded or stale saves', () async {
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
        var refreshed = await RosenExchange.saveRefreshedTrade(initial, quote);
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
        expect(() => RosenExchange.currentUnfunded(initial), throwsA(changed));
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
  });
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
      'tokenContract': RosenApi.rsFiroContract,
      'metadata': RosenProtocol.metadata(
        fromFiro: fromFiro,
        destination: destination,
        bridgeFee: BigInt.from(123),
        networkFee: BigInt.from(456),
      ),
    }),
  );
}
