import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/epicbox_config_model.dart';

void main() {
  test('serializes the insecure flag under the key the plugin reads', () {
    const config = EpicBoxConfigModel(
      host: 'relay.example',
      port: 8443,
      protocolInsecure: true,
      addressIndex: 2,
    );

    final json = jsonDecode(config.toString()) as Map<String, dynamic>;

    expect(json['epicbox_protocol_unsecure'], true);
    expect(json.containsKey('epicbox_protocol_insecure'), isFalse);
    expect(json['epicbox_domain'], 'relay.example');
    expect(json['epicbox_port'], 8443);
    expect(json['epicbox_address_index'], 2);
  });

  test('round-trips through fromString', () {
    const config = EpicBoxConfigModel(
      host: 'relay.example',
      port: 8443,
      protocolInsecure: true,
      addressIndex: 1,
    );

    final restored = EpicBoxConfigModel.fromString(config.toString());

    expect(restored.host, 'relay.example');
    expect(restored.port, 8443);
    expect(restored.protocolInsecure, true);
    expect(restored.addressIndex, 1);
  });

  test('reads configs saved with the earlier key names', () {
    final saved = EpicBoxConfigModel.fromString(
      jsonEncode({
        'epicbox_domain': 'relay.example',
        'epicbox_port': 443,
        'epicbox_protocol_insecure': true,
        'epicbox_address_index': 0,
      }),
    );
    expect(saved.protocolInsecure, true);

    final legacy = EpicBoxConfigModel.fromString(
      jsonEncode({
        'domain': 'relay.example',
        'port': 443,
        'protocol_insecure': true,
        'address_index': 0,
      }),
    );
    expect(legacy.host, 'relay.example');
    expect(legacy.protocolInsecure, true);
  });

  test('defaults to a secure connection when no flag was saved', () {
    final config = EpicBoxConfigModel.fromString(
      jsonEncode({'epicbox_domain': 'relay.example', 'epicbox_port': 443}),
    );
    expect(config.protocolInsecure, false);
    expect(config.addressIndex, 0);
  });

  test('copyWith applies its arguments', () {
    const config = EpicBoxConfigModel(host: 'relay.example', port: 443);

    final changed = config.copyWith(
      port: 8443,
      protocolInsecure: true,
      addressIndex: 3,
    );

    expect(changed.host, 'relay.example');
    expect(changed.port, 8443);
    expect(changed.protocolInsecure, true);
    expect(changed.addressIndex, 3);
    expect(config.copyWith().port, 443);
  });
}
