import 'package:coinlib/coinlib.dart';

abstract class CoinParams {
  static const bitcoin = BitcoinParams();
}

class BitcoinParams {
  const BitcoinParams();

  final NetworkParams mainNet = const NetworkParams(
    wifPrefix: 0x80,
    p2pkhPrefix: 0x00,
    p2shPrefix: 0x05,
    privHDPrefix: 0x0488ade4,
    pubHDPrefix: 0x0488b21e,
    bech32Hrp: "bc",
    messagePrefix: '\x18Bitcoin Signed Message:\n',
  );

  final NetworkParams testNet = const NetworkParams(
    wifPrefix: 0xef,
    p2pkhPrefix: 0x6f,
    p2shPrefix: 0xc4,
    privHDPrefix: 0x04358394,
    pubHDPrefix: 0x043587cf,
    bech32Hrp: "tb",
    messagePrefix: "\x18Bitcoin Signed Message:\n",
  );
}
