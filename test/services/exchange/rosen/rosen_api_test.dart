import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/exchange/rosen/rosen_api.dart';

import 'rosen_test_utils.dart';

void main() {
  final amount = BigInt.from(10000000000);
  const feePath =
      '/api/v1/boxes/unspent/byTokenId/'
      'e2ed4d64393222db666f20e67803e9e6fbe6d64531e14ff52ddd95615b0cbf17';
  const txid =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  for (final suppliedHeight in [false, true]) {
    test('quotes both routes with supplied height: $suppliedHeight', () async {
      for (final fromFiro in [true, false]) {
        final http = RosenTestHttp((url) {
          if (url.path == '/api/v1/heights') {
            expect(url.host, 'app.rosen.tech');
            return [
              {'network': 'ethereum', 'height': '25992101'},
              {'network': 'firo', 'height': 1378335},
            ];
          }
          expect(url.host, 'api.ergoplatform.com');
          expect(url.path, feePath);
          expect(url.queryParameters, {'offset': '0', 'limit': '100'});
          return {
            'items': [rosenFeeBox()],
            'total': 1,
          };
        });
        await http.run(() async {
          final quote = await RosenApi.instance.quote(
            fromFiro: fromFiro,
            amount: amount,
            sourceHeight: suppliedHeight
                ? (fromFiro ? 1378335 : 25992101)
                : null,
          );
          expect(quote.bridgeFee, BigInt.from(1129513169));
          expect(quote.networkFee, BigInt.from(fromFiro ? 1452401 : 500452));
          expect(
            quote.receiveAmount,
            amount - quote.bridgeFee - quote.networkFee,
          );
        });
        expect(http.requests, hasLength(suppliedHeight ? 1 : 2));
      }
    });
  }

  test('paginates past unrelated, spent and forked fee boxes', () async {
    final ignored = [
      {...rosenFeeBox(), 'assets': <Map<String, dynamic>>[]},
      {
        ...rosenFeeBox(),
        'assets': [
          (rosenFeeBox()['assets'] as List).first,
          {'tokenId': 'unrelated-token'},
        ],
      },
      {
        ...rosenFeeBox(),
        'assets': [
          (rosenFeeBox()['assets'] as List).last,
          {'tokenId': 'unrelated-token'},
        ],
      },
      {...rosenFeeBox(), 'spentTransactionId': txid},
      {...rosenFeeBox(), 'mainChain': false},
    ];
    final http = RosenTestHttp((url) {
      expect(url.path, feePath);
      expect(url.queryParameters['limit'], '100');
      return {
        'items': url.queryParameters['offset'] == '0'
            ? ignored
            : [rosenFeeBox()],
        'total': '${ignored.length + 1}',
      };
    });
    await http.run(() async {
      final quote = await RosenApi.instance.quote(
        fromFiro: true,
        amount: amount,
        sourceHeight: 1378335,
      );
      expect(quote.bridgeFee, BigInt.from(1129513169));
    });
    expect(http.requests.map((url) => url.queryParameters['offset']), [
      '0',
      '${ignored.length}',
    ]);
  });

  for (final count in [0, 2]) {
    test('rejects $count active FIRO fee configurations', () async {
      final http = RosenTestHttp(
        (_) => {
          'items': List.generate(count, (_) => rosenFeeBox()),
          'total': count,
        },
      );
      await http.run(() async {
        await expectLater(
          RosenApi.instance.quote(
            fromFiro: true,
            amount: amount,
            sourceHeight: 1378335,
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Expected one active Rosen FIRO fee configuration',
            ),
          ),
        );
      });
    });
  }

  test('rejects incomplete fee pagination', () async {
    final http = RosenTestHttp(
      (_) => {'items': <Map<String, dynamic>>[], 'total': 1},
    );
    await http.run(() async {
      await expectLater(
        RosenApi.instance.quote(
          fromFiro: true,
          amount: amount,
          sourceHeight: 1378335,
        ),
        throwsFormatException,
      );
    });
    expect(http.requests, hasLength(1));
  });

  test('refuses fees changing during the confirmation window', () async {
    final http = RosenTestHttp(
      (_) => {
        'items': [rosenFeeBox()],
        'total': 1,
      },
    );
    await http.run(() async {
      Future<RosenQuote> quote(int height) => RosenApi.instance.quote(
        fromFiro: true,
        amount: amount,
        sourceHeight: height,
      );
      expect((await quote(1373152)).bridgeFee, BigInt.from(1425897447));
      await expectLater(
        quote(1373153),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Rosen fees are changing. Please try again shortly.',
          ),
        ),
      );
      expect((await quote(1373163)).bridgeFee, BigInt.from(1129513169));
    });
  });

  test('surfaces HTTP failures instead of treating them as no event', () async {
    final http = RosenTestHttp(
      (_) => {'items': <Map<String, dynamic>>[]},
      statusCode: 503,
    );
    await http.run(() async {
      await expectLater(
        RosenApi.instance.getEvent(txid),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Rosen API returned HTTP 503',
          ),
        ),
      );
    });
  });

  test('rejects malformed source IDs before requesting events', () async {
    final http = RosenTestHttp((_) => fail('Unexpected network request'));
    await http.run(() async {
      for (final invalid in [
        '',
        txid.substring(1),
        '${txid}0',
        'g${txid.substring(1)}',
      ]) {
        await expectLater(
          RosenApi.instance.getEvent(invalid),
          throwsFormatException,
        );
      }
    });
    expect(http.requests, isEmpty);
  });

  test(
    'normalizes source IDs but requires a unique exact event match',
    () async {
      final event = {
        'sourceTxId': '0x${txid.toUpperCase()}',
        'status': 'pending',
      };
      final unrelated = [
        {'sourceTxId': '${txid}00'},
        {'sourceTxId': txid.substring(1)},
        {'sourceTxId': null},
      ];
      for (final count in [0, 1, 2]) {
        final http = RosenTestHttp((url) {
          expect(url.host, 'app.rosen.tech');
          expect(url.path, '/api/v1/events');
          expect(url.queryParameters, {'sourceTxId*': txid, 'limit': '100'});
          return {
            'items': [...unrelated, ...List.filled(count, event)],
          };
        });
        await http.run(() async {
          final result = RosenApi.instance.getEvent('0x${txid.toUpperCase()}');
          if (count > 1) {
            await expectLater(result, throwsStateError);
          } else {
            expect(await result, count == 0 ? null : event);
          }
        });
      }
    },
  );
}
