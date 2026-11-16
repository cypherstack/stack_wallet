import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/epicbox_config_model.dart';
import 'package:stackwallet/models/epicbox_server_model.dart';
import 'package:stackwallet/utilities/default_epicboxes.dart';
import 'package:stackwallet/utilities/epic_regtest_config.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  test('Epic defaults follow only the explicit regtest build flag', () {
    final node = Epiccash(CryptoCurrencyNetwork.main)
        .defaultNode(isPrimary: true);
    final relay = DefaultEpicBoxes.defaultEpicBoxServer;
    final relayConfig = EpicBoxConfigModel.fromServer(relay);

    if (EpicRegtestConfig.enabled) {
      expect(node.host, EpicRegtestConfig.nodeHost);
      expect(node.port, EpicRegtestConfig.nodePort);
      expect(node.useSSL, isFalse);
      expect(relay.host, EpicRegtestConfig.relayHost);
      expect(relay.port, EpicRegtestConfig.relayPort);
      expect(relay.useSSL, isFalse);
      expect(relayConfig.protocolInsecure, isTrue);
      expect(EpicRegtestConfig.chain, 'usertesting');
      expect(EpicRegtestConfig.relayScheme, 'ws');
      expect(
        () => EpicRegtestConfig.desktopDataDir(const []),
        throwsArgumentError,
      );
    } else {
      expect(node.host, 'https://epic.stackwallet.com');
      expect(node.port, 3413);
      expect(node.useSSL, isTrue);
      expect(relay.host, 'epicbox.epiccash.com');
      expect(relay.port, 443);
      expect(relay.useSSL, isTrue);
      expect(relayConfig.protocolInsecure, isFalse);
      expect(EpicRegtestConfig.chain, 'mainnet');
      expect(EpicRegtestConfig.relayScheme, 'wss');
      expect(EpicRegtestConfig.desktopDataDir(const []), isNull);
    }

    expect(
      EpicRegtestConfig.desktopDataDir(const ['-d', '/tmp/isolated-stack']),
      '/tmp/isolated-stack',
    );
  });

  test('custom relay transport security survives server conversion', () {
    const secure = EpicBoxServerModel(
      id: 'secure',
      host: 'secure.example',
      name: 'Secure',
      port: 443,
      useSSL: true,
    );
    const insecure = EpicBoxServerModel(
      id: 'insecure',
      host: '127.0.0.1',
      name: 'Insecure',
      port: 43420,
      useSSL: false,
    );

    expect(EpicBoxConfigModel.fromServer(secure).protocolInsecure, isFalse);
    expect(EpicBoxConfigModel.fromServer(insecure).protocolInsecure, isTrue);
  });
}
