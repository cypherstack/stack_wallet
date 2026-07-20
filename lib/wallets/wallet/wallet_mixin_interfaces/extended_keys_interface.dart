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
    // supportedHardenedDerivationPaths is built 1:1 (and in order) from
    // supportedDerivationPathTypes, so index i of each lines up. We need the
    // DerivePathType to pick the SLIP-0132 version bytes (xpub/ypub/zpub).
    final types = cryptoCurrency.supportedDerivationPathTypes;
    final paths = cryptoCurrency.supportedHardenedDerivationPaths;

    final master = await getRootHDNode();
    final fingerprint = master.fingerprint.toRadixString(16);

    final futures = List.generate(paths.length, (i) async {
      final node = master.derivePath(paths[i]);

      return XPub(
        path: paths[i],
        encoded: node.hdPublicKey.encode(
          cryptoCurrency.slip132PubVersion(types[i]),
        ),
      );
    });

    return (fingerprint: fingerprint, xpubs: await Future.wait(futures));
  }

  Future<XPrivData> getXPrivs() async {
    // See getXPubs(): types[i] lines up with paths[i].
    final types = cryptoCurrency.supportedDerivationPathTypes;
    final paths = cryptoCurrency.supportedHardenedDerivationPaths;

    final master = await getRootHDNode();
    final fingerprint = master.fingerprint.toRadixString(16);

    final futures = List.generate(paths.length, (i) async {
      final node = master.derivePath(paths[i]);

      return XPriv(
        path: paths[i],
        encoded: node.encode(cryptoCurrency.slip132PrivVersion(types[i])),
      );
    });

    return XPrivData(
      walletId: walletId,
      fingerprint: fingerprint,
      xprivs: [
        XPriv(
          path: "Master",
          // A master xprv has no BIP49/84 script type; keep it generic.
          encoded: master.encode(cryptoCurrency.networkParams.privHDPrefix),
        ),
        ...(await Future.wait(futures)),
      ],
    );
  }
}
