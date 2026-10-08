import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/exceptions/exchange/exchange_exception.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/trade_wallet_lookup.dart';
import 'package:stackwallet/networking/http.dart';
import 'package:stackwallet/services/ethereum/ethereum_api.dart';
import 'package:stackwallet/services/exchange/rosen/rosen_api.dart';
import 'package:stackwallet/services/exchange/rosen/rosen_exchange.dart';
import 'package:stackwallet/services/exchange/rosen/rosen_protocol.dart';
import 'package:stackwallet/utilities/default_eth_tokens.dart';

import 'rosen_test_utils.dart';

void main() {
  final exchange = RosenExchange.instance;
  final changed = isA<ExchangeException>().having(
    (e) => e.type,
    'type',
    ExchangeExceptionType.quoteChanged,
  );

  for (final fromFiro in [true, false]) {
    final from = fromFiro ? 'FIRO' : 'rsFIRO';
    final to = fromFiro ? 'rsFIRO' : 'FIRO';
    final fromNetwork = fromFiro ? 'firo' : 'eth';
    final toNetwork = fromFiro ? 'eth' : 'firo';
    final destination = fromFiro
        ? '0x00112233445566778899aabbccddeeff00112233'
        : RosenApi.firoLockAddress;

    group('$from → $to exchange', () {
      late Directory directory;
      late Box<Trade> trades;
      late Box<TradeWalletLookup> lookups;
      late Map<String, dynamic> feeBox;
      late List<Map<String, dynamic>> events;
      late RosenTestHttp http;
      late HTTP previousEthereumClient;
      late _ReceiptHttp receiptHttp;

      setUp(() async {
        directory = await Directory.systemTemp.createTemp('rosen-exchange-');
        final hive = DB.instance.hive;
        hive.init(directory.path);
        if (!hive.isAdapterRegistered(Trade.typeId)) {
          hive.registerAdapter(TradeAdapter());
        }
        final lookupAdapter = TradeWalletLookupAdapter();
        if (!hive.isAdapterRegistered(lookupAdapter.typeId)) {
          hive.registerAdapter(lookupAdapter);
        }
        trades = await hive.openBox<Trade>(DB.boxNameTradesV2);
        lookups = await hive.openBox<TradeWalletLookup>(DB.boxNameTradeLookup);
        feeBox = rosenFeeBox();
        events = [];
        previousEthereumClient = EthereumAPI.client;
        receiptHttp = _ReceiptHttp();
        EthereumAPI.client = receiptHttp;
        http = RosenTestHttp((url) {
          if (url.host == 'app.rosen.tech') {
            switch (url.path) {
              case '/api/v1/heights':
                return [
                  {'network': 'firo', 'height': 1378335},
                  {'network': 'ethereum', 'height': 25992101},
                ];
              case '/api/v1/events':
                return {'items': events};
            }
          }
          expect(url.host, 'api.ergoplatform.com');
          expect(url.path, contains('/boxes/unspent/byTokenId/'));
          return {
            'items': [feeBox],
            'total': 1,
          };
        });
      });
      tearDown(() async {
        EthereumAPI.client = previousEthereumClient;
        await lookups.close();
        await trades.close();
        await directory.delete(recursive: true);
      });

      Future<Estimate> estimate() async {
        final response = await exchange.getEstimates(
          from,
          fromNetwork,
          to,
          toNetwork,
          Decimal.fromInt(100),
          false,
          false,
        );
        expect(response.exception, isNull);
        return response.value!.single;
      }

      Future<Trade> create(Estimate quote) async {
        final response = await exchange.createTrade(
          from: from,
          fromNetwork: fromNetwork,
          to: to,
          toNetwork: toNetwork,
          amount: Decimal.fromInt(100),
          fixedRate: false,
          reversed: false,
          addressTo: destination,
          addressRefund: '',
          refundExtraId: '',
          estimate: quote,
        );
        expect(response.exception, isNull);
        return response.value!;
      }

      void changeFees() {
        // A valid replacement schedule: zero base fees, unchanged percentage.
        feeBox['additionalRegisters'] = {
          ...rosenFeeRegisters,
          'R6': {'serializedValue': '1d020600000000000006000000000000'},
        };
      }

      test(
        'range, quote and trade preserve the route and exact amounts',
        () async {
          await http.run(() async {
            final range = await exchange.getRange(
              from,
              fromNetwork,
              to,
              toNetwork,
              false,
            );
            expect(range.exception, isNull);
            expect(
              range.value!.min,
              Decimal.parse(fromFiro ? '11.30965571' : '11.30013622'),
            );
            expect(range.value!.max, Decimal.parse('184467440737.09551615'));
            final quote = await estimate();
            expect(
              quote.estimatedAmount,
              Decimal.parse(fromFiro ? '88.6903443' : '88.69986379'),
            );
            final trade = await create(quote);
            expect(trade.payInAmount, '100');
            expect(trade.payOutAmount, quote.estimatedAmount.toString());
            expect(trade.payInCurrency, from);
            expect(trade.payOutCurrency, to);
            expect(trade.payInNetwork, fromNetwork);
            expect(trade.payOutNetwork, toNetwork);
            expect(trade.payOutAddress, destination);
            expect(
              trade.payInAddress,
              fromFiro
                  ? RosenApi.firoLockAddress
                  : RosenApi.ethereumLockAddress,
            );
            expect(trade.status, 'Waiting');
            expect(trade.payInTxid, isEmpty);
            final data = jsonDecode(trade.other!) as Map;
            expect(data['tokenContract'], DefaultTokens.rsFiro.address);
            expect(data['bridgeFee'], '1129513169');
            expect(data['networkFee'], fromFiro ? '1452401' : '500452');
            expect(data.containsKey('metadata'), isFalse);
            expect(
              RosenExchange.validatedMetadata(trade),
              RosenProtocol.metadata(
                fromFiro: fromFiro,
                destination: destination,
                bridgeFee: BigInt.parse(data['bridgeFee'] as String),
                networkFee: BigInt.parse(data['networkFee'] as String),
              ),
            );
            await trades.put(trade.uuid, trade);
            expect(
              (await exchange.getTrade(trade.tradeId)).value!.uuid,
              trade.uuid,
            );
            expect((await exchange.getTrades()).value!.single.uuid, trade.uuid);
            expect(
              (await exchange.getTrade('missing')).exception!.type,
              ExchangeExceptionType.orderNotFound,
            );
          });
        },
      );

      test(
        'changed fees reject an old estimate before creating a trade',
        () async {
          await http.run(() async {
            final quote = await estimate();
            changeFees();
            final response = await exchange.createTrade(
              from: from,
              fromNetwork: fromNetwork,
              to: to,
              toNetwork: toNetwork,
              amount: Decimal.fromInt(100),
              fixedRate: false,
              reversed: false,
              addressTo: destination,
              addressRefund: '',
              refundExtraId: '',
              estimate: quote,
            );
            expect(response.value, isNull);
            expect(response.exception, changed);
            expect(trades.values, isEmpty);
            final refreshed = await estimate();
            expect(refreshed.rateId, isNot(quote.rateId));
            expect(
              (await create(refreshed)).payOutAmount,
              refreshed.estimatedAmount.toString(),
            );
          });
        },
      );

      test('funding rechecks both live fees and persisted state', () async {
        await http.run(() async {
          final trade = await create(await estimate());
          await trades.put(trade.uuid, trade);
          final height = fromFiro ? 1378335 : 25992101;
          await RosenExchange.validateFunding(trade, sourceHeight: height);
          changeFees();
          await expectLater(
            RosenExchange.validateFunding(trade, sourceHeight: height),
            throwsA(changed),
          );
          feeBox = rosenFeeBox();
          final concurrent = RosenTestHttp((url) async {
            expect(url.host, 'api.ergoplatform.com');
            await trades.put(
              trade.uuid,
              trade.copyWith(payInTxid: 'ab' * 32, status: 'Confirming'),
            );
            return {
              'items': [feeBox],
              'total': 1,
            };
          });
          await concurrent.run(() async {
            await expectLater(
              RosenExchange.validateFunding(trade, sourceHeight: height),
              throwsA(
                isA<StateError>().having(
                  (e) => e.message,
                  'message',
                  'Only an unfunded Rosen swap can be refreshed or sent.',
                ),
              ),
            );
          });
          expect(concurrent.requests, hasLength(1));
        });
      });

      test('polling rejects mismatched events and requires a payout', () async {
        await http.run(() async {
          final trade = (await create(await estimate()))
              .copyWith(payInTxid: 'ab' * 32, status: 'Confirming');
          await trades.put(trade.uuid, trade);
          expect(
            (await exchange.updateTrade(trade)).value!.status,
            'Confirming',
          );
          final fees = jsonDecode(trade.other!) as Map;
          final event = <String, dynamic>{
            'sourceTxId': '0x${trade.payInTxid.toUpperCase()}',
            'fromChain': fromFiro ? 'firo' : 'ethereum',
            'toChain': fromFiro ? 'ethereum' : 'firo',
            'toAddress': fromFiro ? destination.toUpperCase() : destination,
            'sourceChainTokenId': fromFiro
                ? 'FIRO'
                : DefaultTokens.rsFiro.address.toUpperCase(),
            'bridgeFee': fees['bridgeFee'],
            'networkFee': fees['networkFee'],
            'amount': '10000000000',
            'status': 'completed',
            'paymentTxId': null,
          };
          for (final mismatch in {
            'fromChain': 'ergo',
            'toChain': 'ergo',
            'toAddress': 'wrong-recipient',
            'sourceChainTokenId': 'wrong-token',
            'bridgeFee': '1',
            'networkFee': '1',
            'amount': '9999999999',
          }.entries) {
            events = [
              {...event, mismatch.key: mismatch.value},
            ];
            final result = await exchange.updateTrade(trade);
            expect(result.value, isNull, reason: mismatch.key);
            expect(
              result.exception!.message,
              contains('Rosen event does not match this swap.'),
              reason: mismatch.key,
            );
          }
          for (final payout in [null, 'invalid', 'cd' * 32]) {
            events = [
              {...event, 'paymentTxId': payout},
            ];
            final result = await exchange.updateTrade(trade);
            expect(result.exception, isNull);
            expect(
              result.value!.status,
              payout == 'cd' * 32 ? 'Finished' : 'Sending',
            );
            expect(result.value!.payOutTxid, payout == 'cd' * 32 ? payout : '');
          }
          final finished = trade.copyWith(
            status: 'Finished',
            payOutTxid: 'cd' * 32,
          );
          final concurrent = RosenTestHttp((url) async {
            expect(url.path, '/api/v1/events');
            await trades.put(trade.uuid, finished);
            return {'items': <Map<String, dynamic>>[]};
          });
          await concurrent.run(() async {
            final result = await exchange.updateTrade(trade);
            expect(result.exception, isNull);
            expect(result.value!.status, 'Finished');
            expect(result.value!.payOutTxid, finished.payOutTxid);
          });
          expect(concurrent.requests, hasLength(1));
          expect(trades.get(trade.uuid)!.payInTxid, trade.payInTxid);
        });
      });

      if (!fromFiro) {
        test('polling detects a failed Ethereum receipt', () async {
          await http.run(() async {
            var trade = (await create(await estimate()))
                .copyWith(payInTxid: 'ab' * 32, status: 'Confirming');
            final data = jsonDecode(trade.other!) as Map<String, dynamic>;
            trade = trade.copyWith(
              other: jsonEncode({
                ...data,
                'funding': {
                  'walletId': 'wallet',
                  'txid': 'ab' * 32,
                  'raw': '00',
                  'state': 'submitting',
                },
              }),
            );
            await trades.put(trade.uuid, trade);
            for (final (status, expected) in [
              (null, 'Confirming'),
              ('0x1', 'Confirming'),
            ]) {
              receiptHttp.status = status;
              final result = await exchange.updateTrade(trade);
              expect(result.exception, isNull);
              expect(result.value!.status, expected);
            }
            expect(
              (jsonDecode(trades.get(trade.uuid)!.other!)
                  as Map)['funding']['state'],
              'broadcast',
            );
            expect(lookups.get(trade.uuid)!.walletIds, ['wallet']);
            receiptHttp.status = '0x0';
            receiptHttp.latestBlock = receiptHttp.receiptBlock;
            var result = await exchange.updateTrade(trade);
            expect(result.exception, isNull);
            expect(result.value!.status, 'Confirming');
            receiptHttp.latestBlock =
                receiptHttp.receiptBlock +
                RosenApi.ethereumConfirmationWindow -
                1;
            result = await exchange.updateTrade(trade);
            expect(result.exception, isNull);
            expect(result.value!.status, 'Failed');
            receiptHttp.status = '0x2';
            final malformed = await exchange.updateTrade(trade);
            expect(malformed.value, isNull);
            expect(malformed.exception, isNotNull);

            expect(receiptHttp.urls, hasLength(7));
            expect(
              receiptHttp.bodies
                  .map((body) => (jsonDecode(body) as Map)['method'])
                  .where((method) => method == 'eth_blockNumber'),
              hasLength(2),
            );
            final request = jsonDecode(receiptHttp.bodies.last) as Map;
            expect(
              receiptHttp.urls.last,
              Uri.parse(EthereumAPI.stackBaseServer),
            );
            expect(
              receiptHttp.headers.last['content-type'],
              'application/json',
            );
            expect(request, {
              'jsonrpc': '2.0',
              'method': 'eth_getTransactionReceipt',
              'params': ['0x${'ab' * 32}'],
              'id': 1,
            });
          });
        });
      }
    });
  }
}

class _ReceiptHttp extends HTTP {
  String? status;
  int receiptBlock = 100;
  int latestBlock = 100;
  final urls = <Uri>[];
  final headers = <Map<String, String>>[];
  final bodies = <String>[];

  @override
  Future<Response> post({
    required Uri url,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    required ({InternetAddress host, int port})? proxyInfo,
  }) async {
    urls.add(url);
    this.headers.add(headers ?? const {});
    final requestBody = body! as String;
    bodies.add(requestBody);
    final request = jsonDecode(requestBody) as Map;
    return Response(
      utf8.encode(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'result': request['method'] == 'eth_blockNumber'
              ? '0x${latestBlock.toRadixString(16)}'
              : status == null
              ? null
              : {
                  'transactionHash': '0x${'ab' * 32}',
                  'status': status,
                  'blockNumber': '0x${receiptBlock.toRadixString(16)}',
                },
        }),
      ),
      200,
    );
  }
}
