import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/networking/http.dart';
import 'package:stackwallet/services/price.dart';
import 'package:stackwallet/services/price_service.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import '../hive/hive_ce_test_utils.dart';
import '../price_test.mocks.dart';

class _Service extends PriceService {
  _Service() : super('USD');

  int contractQueries = 0;
  Completer<Set<String>>? contracts;
  Completer<Set<String>>? solContracts;
  int solQueries = 0;

  @override
  Future<Set<String>> get tokenContractAddressesToCheck {
    contractQueries++;
    return contracts?.future ?? Future.value({});
  }

  @override
  Future<Set<String>> get solTokenContractAddressesToCheck {
    solQueries++;
    return solContracts?.future ?? Future.value({});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setUpHiveCeTest();
    await DB.instance.hive.openBox<dynamic>(DB.boxNamePriceCache);
    await DB.instance.hive.openBox<dynamic>(DB.boxNamePrefs);
    await DB.instance.put<dynamic>(
      boxName: DB.boxNamePrefs,
      key: 'externalCalls',
      value: true,
    );
    final client = MockHTTP();
    when(
      client.get(
        url: anyNamed('url'),
        headers: anyNamed('headers'),
        proxyInfo: anyNamed('proxyInfo'),
      ),
    ).thenAnswer(
      (_) async => Response(
        utf8.encode(
          '[{"id":"bitcoin","name":"Bitcoin","current_price":50000}]',
        ),
        200,
      ),
    );
    final priceAPI = PriceAPI(client)
      ..resetLastCalledToForceNextCallToUpdateCache();
    final prices = await priceAPI.getPricesAnd24hChange(baseCurrency: 'USD');
    expect(
      prices[Bitcoin(CryptoCurrencyNetwork.main)]?.value,
      Decimal.fromInt(50000),
    );
  });
  tearDown(tearDownHiveCeTest);

  test('disposal during a price read discards the result', () async {
    final service = _Service();
    final pending = service.updatePrice();
    service.dispose();
    await pending;

    expect(service.getPrice(Bitcoin(CryptoCurrencyNetwork.main)), isNull);
    expect(service.contractQueries, 0);
    service.start(true);
    await service.updatePrice();
    expect(service.contractQueries, 0);
  });

  test('disposal during a contract query stops the update', () async {
    final service = _Service()..contracts = Completer<Set<String>>();
    final pending = service.updatePrice();
    await Future<void>.delayed(Duration.zero);
    expect(service.contractQueries, 1);
    service.dispose();
    service.contracts!.complete({'token'});
    await pending;
    expect(service.getTokenPrice('token'), isNull);
    expect(service.solQueries, 0);
  });

  test(
    'disposal during a Solana contract query suppresses notification',
    () async {
      final service = _Service()..solContracts = Completer<Set<String>>();
      var notifications = 0;
      service.addListener(() => notifications++);
      final pending = service.updatePrice();
      await Future<void>.delayed(Duration.zero);
      expect(service.solQueries, 1);
      service.dispose();
      service.solContracts!.complete({'token'});
      await pending;
      expect(service.getTokenPrice('token'), isNull);
      expect(notifications, 0);
    },
  );

  testWidgets('disposal cancels polling and prevents restarting', (
    tester,
  ) async {
    final service = _Service();
    service.start(false);
    service.dispose();
    service.start(true);
    await tester.pump(service.updateInterval * 2);
    expect(service.contractQueries, 0);
    expect(service.getPrice(Bitcoin(CryptoCurrencyNetwork.main)), isNull);
  });

  for (final disposed in [false, true]) {
    final outcome = disposed
        ? 'discarded after disposal'
        : 'reported while active';
    test('a late query error is $outcome', () async {
      final service = _Service()..contracts = Completer<Set<String>>();
      final pending = service.updatePrice();
      await Future<void>.delayed(Duration.zero);
      expect(service.contractQueries, 1);
      if (disposed) service.dispose();
      final observed = expectLater(
        pending,
        disposed ? completes : throwsA(isA<StateError>()),
      );
      service.contracts!.completeError(StateError('database closed'));
      await observed;
      if (!disposed) service.dispose();
    });
  }
}
