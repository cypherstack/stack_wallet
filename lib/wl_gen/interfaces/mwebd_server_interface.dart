import '../../wallets/crypto_currency/crypto_currency.dart';

export '../generated/mwebd_server_interface_impl.dart';

abstract class MwebdServerInterface {
  const MwebdServerInterface();

  Future<({OpaqueMwebdServer server, int port})> createAndStartServer(
    CryptoCurrencyNetwork net, {
    required String chain,
    required String dataDir,
    required String peer,
    String proxy = "",
    required int serverPort,
  });

  Future<({String chain, String dataDir, String peer})> stopServer(
    OpaqueMwebdServer server,
  );

  Future<Status?> getServerStatus(OpaqueMwebdServer? server);
}

// local copy
class Status {
  final int blockHeaderHeight;
  final int mwebHeaderHeight;
  final int mwebUtxosHeight;
  final int blockTime;

  Status({
    required this.blockHeaderHeight,
    required this.mwebHeaderHeight,
    required this.mwebUtxosHeight,
    required this.blockTime,
  });

  @override
  String toString() {
    return 'Status('
        'blockHeaderHeight: $blockHeaderHeight, '
        'mwebHeaderHeight: $mwebHeaderHeight, '
        'mwebUtxosHeight: $mwebUtxosHeight, '
        'blockTime: $blockTime'
        ')';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Status &&
          blockHeaderHeight == other.blockHeaderHeight &&
          mwebHeaderHeight == other.mwebHeaderHeight &&
          mwebUtxosHeight == other.mwebUtxosHeight &&
          blockTime == other.blockTime;

  @override
  int get hashCode => Object.hash(
    blockHeaderHeight,
    mwebHeaderHeight,
    mwebUtxosHeight,
    blockTime,
  );
}

final class OpaqueMwebdServer {
  final Object _value;

  const OpaqueMwebdServer(this._value);

  T get<T>() => _value as T;
}
