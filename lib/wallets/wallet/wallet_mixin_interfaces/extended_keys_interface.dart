import 'package:coin/coin.dart' as coin;

import '../../../models/keys/xpriv_data.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import 'electrumx_interface.dart';

abstract class XKey {
  XKey({required this.path});
  final String path;

  @override
  String toString() => "Path: $path";
}

class XPub extends XKey {
  XPub({required super.path, required this.encoded});
  final String encoded;

  @override
  String toString() => "XPub { path: $path, encoded: $encoded }";
}

class XPriv extends XKey {
  XPriv({required super.path, required this.encoded});
  final String encoded;

  @override
  String toString() => "XPriv { path: $path, encoded: $encoded }";
}

mixin ExtendedKeysInterface<T extends ElectrumXCurrencyInterface>
    on ElectrumXInterface<T> {
  Future<({List<XPub> xpubs, String fingerprint})> getXPubs() async {
    final paths = cryptoCurrency.supportedHardenedDerivationPaths;

    final master = await getRootHDNode();
    final fingerprint = master.fingerprint.toRadixString(16);

    final futures = paths.map((path) async {
      final node = master.derivePath(path) as coin.DerivedSecretKey;

      return XPub(
        path: path,
        encoded: node.toPublic().encode(
              version: cryptoCurrency.networkParams.pubHDPrefix,
            ),
      );
    });

    return (
      fingerprint: fingerprint,
      xpubs: await Future.wait(futures),
    );
  }

  Future<XPrivData> getXPrivs() async {
    final paths = cryptoCurrency.supportedHardenedDerivationPaths;

    final master = await getRootHDNode();
    final fingerprint = master.fingerprint.toRadixString(16);

    final futures = paths.map((path) async {
      final node = master.derivePath(path) as coin.DerivedSecretKey;

      return XPriv(
        path: path,
        encoded: node.encode(
          version: cryptoCurrency.networkParams.privHDPrefix,
        ),
      );
    });

    return XPrivData(
      walletId: walletId,
      fingerprint: fingerprint,
      xprivs: [
        XPriv(
          path: "Master",
          encoded: master.encode(
            version: cryptoCurrency.networkParams.privHDPrefix,
          ),
        ),
        ...(await Future.wait(futures)),
      ],
    );
  }
}
