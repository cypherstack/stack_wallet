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
      final node = master.derivePath(path);

      return XPub(
        path: path,
        encoded: node.hdPublicKey.encode(
          cryptoCurrency.networkParams.pubHDPrefix,
          // 0x04b24746,
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
      final node = master.derivePath(path);

      return XPriv(
        path: path,
        encoded: node.encode(
          cryptoCurrency.networkParams.privHDPrefix,
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
            cryptoCurrency.networkParams.privHDPrefix,
          ),
        ),
        ...(await Future.wait(futures)),
      ],
    );
  }
}
