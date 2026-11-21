import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:regtest_support/regtest_support.dart';
import 'package:stackwallet/app_config.dart';
import 'package:stackwallet/models/node_model.dart';

import '../../integration_test/regtest_support/stack_test_environment.dart';
import '../../integration_test/regtest_support/stack_wallet_fixture.dart';
import '../support/isar_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeTestIsar);

  test(
    'isolates Stack storage, credentials, preferences, and endpoint delivery',
    () async {
      final environment = await StackTestEnvironment.open();
      final root = environment.root;
      expect(root.existsSync(), isTrue);
      expect(environment.prefs.isInitialized, isTrue);

      await environment.secrets.write(key: 'fixture-token', value: 'secret');
      expect(await environment.secrets.read(key: 'fixture-token'), 'secret');

      final currency = AppConfig.coins.first;
      final endpoints = EndpointBundle.mapHost(
        hostEndpoints: {'wallet': Uri.parse('https://127.0.0.1:9067')},
        deviceHost: '10.0.2.2',
      );
      final delivery = StackNodeEndpointDelivery(
        currency: currency,
        endpointName: 'wallet',
        nodeFactory: (uri) => NodeModel(
          host: uri.host,
          port: uri.port,
          name: 'regtest',
          id: 'regtest-node',
          useSSL: uri.scheme == 'https',
          enabled: true,
          coinName: currency.identifier,
          isFailover: false,
          isDown: false,
          torEnabled: false,
          clearnetEnabled: true,
          isPrimary: true,
        ),
      );

      await delivery(
        environment,
        endpoints,
        StackEndpointAudience.device,
        RegtestCancellation(),
      );

      final primary = environment.nodes.getPrimaryNodeFor(currency: currency);
      expect(primary, isNotNull);
      expect(primary!.host, '10.0.2.2');
      expect(primary.port, 9067);
      expect(primary.useSSL, isTrue);

      await environment.close();
      await environment.close();
      if (!Platform.isWindows) expect(root.existsSync(), isFalse);
    },
  );
}
