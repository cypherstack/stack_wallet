import '../../../models/keys/xpriv_data.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import 'electrumx_interface.dart';

typedef XPub = ({String path, String xpub});
typedef XPriv = ({String path, String xpriv});

mixin ExtendedKeysInterface<T extends ElectrumXCurrencyInterface>
    on ElectrumXInterface<T> {
  Future<({List<XPub> xpubs, String fingerprint})> getXPubs() async {
    final paths = cryptoCurrency.supportedDerivationPathTypes.map(
      (e) => (
        path: e,
        addressType: e.getAddressType(),
      ),
    );

    final master = await getRootHDNode();
    final fingerprint = master.fingerprint.toRadixString(16);

    final futures = paths.map((e) async {
      String path = cryptoCurrency.constructDerivePath(
        derivePathType: e.path,
        chain: 0,
        index: 0,
      );
      // trim chain and address index
      path = path.substring(0, path.lastIndexOf("'") + 1);
      final node = master.derivePath(path);

      return (
        path: path,
        xpub: node.hdPublicKey.encode(
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
    final paths = cryptoCurrency.supportedDerivationPathTypes.map(
      (e) => (
        path: e,
        addressType: e.getAddressType(),
      ),
    );

    final master = await getRootHDNode();
    final fingerprint = master.fingerprint.toRadixString(16);

    final futures = paths.map((e) async {
      String path = cryptoCurrency.constructDerivePath(
        derivePathType: e.path,
        chain: 0,
        index: 0,
      );
      // trim chain and address index
      path = path.substring(0, path.lastIndexOf("'") + 1);
      final node = master.derivePath(path);

      return (
        path: path,
        xpriv: node.encode(
          cryptoCurrency.networkParams.privHDPrefix,
        ),
      );
    });

    return XPrivData(
      walletId: walletId,
      fingerprint: fingerprint,
      xprivs: [
        (
          path: "Master",
          xpriv: master.encode(
            cryptoCurrency.networkParams.privHDPrefix,
          ),
        ),
        ...(await Future.wait(futures)),
      ],
    );
  }
}
