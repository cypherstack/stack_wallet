import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/bip39_hd_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

class Bitcoincash extends Bip39HDCurrency {
  Bitcoincash(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.bitcoin;
      case CryptoCurrencyNetwork.test:
        coin = Coin.bitcoinTestNet;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  String get genesisHash {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f";
      case CryptoCurrencyNetwork.test:
        return "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943";
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  Amount get dustLimit => Amount(
        rawValue: BigInt.from(546),
        fractionDigits: fractionDigits,
      );

  @override
  coinlib.NetworkParams get networkParams {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return const coinlib.NetworkParams(
          wifPrefix: 0x80,
          p2pkhPrefix: 0x00,
          p2shPrefix: 0x05,
          privHDPrefix: 0x0488ade4,
          pubHDPrefix: 0x0488b21e,
          bech32Hrp: "bc",
          messagePrefix: '\x18Bitcoin Signed Message:\n',
        );
      case CryptoCurrencyNetwork.test:
        return const coinlib.NetworkParams(
          wifPrefix: 0xef,
          p2pkhPrefix: 0x6f,
          p2shPrefix: 0xc4,
          privHDPrefix: 0x04358394,
          pubHDPrefix: 0x043587cf,
          bech32Hrp: "tb",
          messagePrefix: "\x18Bitcoin Signed Message:\n",
        );
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  String constructDerivePath({
    required DerivePathType derivePathType,
    int account = 0,
    required int chain,
    required int index,
  }) {
    String coinType;

    switch (networkParams.wifPrefix) {
      case 0x80:
        switch (derivePathType) {
          case DerivePathType.bip44:
            coinType = "145"; // bch mainnet
            break;
          case DerivePathType.bch44: // bitcoin.com wallet specific
            coinType = "0"; // bch mainnet
            break;
          default:
            throw Exception(
                "DerivePathType $derivePathType not supported for coinType");
        }
        break;
      case 0xef:
        coinType = "1"; // btc testnet
        break;
      default:
        throw Exception("Invalid Bitcoin network wif used!");
    }

    final int purpose;
    switch (derivePathType) {
      case DerivePathType.bip44:
      case DerivePathType.bch44:
        purpose = 44;
        break;
      default:
        throw Exception("DerivePathType $derivePathType not supported");
    }

    return "m/$purpose'/$coinType'/$account'/$chain/$index";
  }

  @override
  ({coinlib.Address address, AddressType addressType}) getAddressForPublicKey({
    required coinlib.ECPublicKey publicKey,
    required DerivePathType derivePathType,
  }) {
    switch (derivePathType) {
      case DerivePathType.bip44:
      case DerivePathType.bch44:
        final addr = coinlib.P2PKHAddress.fromPublicKey(
          publicKey,
          version: networkParams.p2pkhPrefix,
        );

        return (address: addr, addressType: AddressType.p2sh);

      default:
        throw Exception("DerivePathType $derivePathType not supported");
    }
  }

  @override
  // change this to change the number of confirms a tx needs in order to show as confirmed
  int get minConfirms => 0; // bch zeroconf

  // TODO: [prio=med] bch p2sh addresses (complaints regarding sending to)
  @override
  bool validateAddress(String address) {
    try {
      // 0 for bitcoincash: address scheme, 1 for legacy address
      final format = bitbox.Address.detectFormat(address);

      if (coin == Coin.bitcoincashTestnet) {
        return true;
      }

      if (format == bitbox.Address.formatCashAddr) {
        return _validateCashAddr(address);
      } else {
        return address.startsWith("1");
      }
    } catch (e) {
      return false;
    }
  }

  bool _validateCashAddr(String cashAddr) {
    String addr = cashAddr;
    if (cashAddr.contains(":")) {
      addr = cashAddr.split(":").last;
    }

    return addr.startsWith("q");
  }
}
