import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_transparent_receiver_discovery.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

const _viewingKeys = zcash.ZcashViewingKeys(
  network: zcash.ZcashAddressNetwork.mainnet,
  accountIndex: 0,
  transparent: zcash.ZcashTransparentViewingKeys(
    available: true,
    externalIvk: '00',
    internalIvk: '11',
    defaultExternalAddress: 't-address',
    defaultExternalIndex: 0,
  ),
  sapling: zcash.ZcashSaplingViewingKey(available: false),
  orchard: zcash.ZcashOrchardViewingKey(available: false),
);

void main() {
  test('rejects a non-positive transparent discovery gap at runtime', () {
    expect(
      () => ZcashTransparentReceiverDiscovery(
        network: zcash.ZcashNetwork.mainnet,
        viewingKeys: _viewingKeys,
        gapLimit: 0,
      ),
      throwsArgumentError,
    );
  });

  test('rejects a hard child limit below the discovery gap', () {
    expect(
      () => ZcashTransparentReceiverDiscovery(
        network: zcash.ZcashNetwork.mainnet,
        viewingKeys: _viewingKeys,
        gapLimit: 20,
        hardChildLimit: 19,
      ),
      throwsArgumentError,
    );
  });
}
