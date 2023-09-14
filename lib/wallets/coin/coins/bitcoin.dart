import 'package:coinlib/coinlib.dart' as coinlib;
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/coin/bip39_hd_currency.dart';
import 'package:stackwallet/wallets/coin/coin_params.dart';
import 'package:stackwallet/wallets/coin/crypto_currency.dart';

class Bitcoin extends Bip39HDCurrency {
  Bitcoin(super.network) {
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
  coinlib.NetworkParams get networkParams {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return CoinParams.bitcoin.mainNet;
      case CryptoCurrencyNetwork.test:
        return CoinParams.bitcoin.testNet;
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

    if (networkParams.wifPrefix == CoinParams.bitcoin.mainNet.wifPrefix) {
      coinType = "0"; // btc mainnet
    } else if (networkParams.wifPrefix ==
        CoinParams.bitcoin.testNet.wifPrefix) {
      coinType = "1"; // btc testnet
    } else {
      throw Exception("Invalid Bitcoin network wif used!");
    }

    int purpose;
    switch (derivePathType) {
      case DerivePathType.bip44:
        purpose = 44;
        break;
      case DerivePathType.bip49:
        purpose = 49;
        break;
      case DerivePathType.bip84:
        purpose = 84;
        break;
      default:
        throw Exception("DerivePathType $derivePathType not supported");
    }

    return "m/$purpose'/$coinType'/$account'/$chain/$index";
  }

  ({coinlib.Address address, AddressType addressType}) getAddressForPublicKey({
    required coinlib.ECPublicKey publicKey,
    required DerivePathType derivePathType,
  }) {
    switch (derivePathType) {
      case DerivePathType.bip44:
        final addr = coinlib.P2PKHAddress.fromPublicKey(
          publicKey,
          version: networkParams.p2pkhPrefix,
        );

        return (address: addr, addressType: AddressType.p2sh);
        break;
      case DerivePathType.bip49:
        // addressString = P2SH(
        //         data: PaymentData(
        //             redeem: P2WPKH(data: data, network: _network).data),
        //         network: _network)
        //     .data
        //     .address!;

        // todo ?????????????????? Does not match with current BTC
        final adr = coinlib.P2WPKHAddress.fromPublicKey(
          publicKey,
          hrp: networkParams.bech32Hrp,
        );
        final addr = coinlib.P2SHAddress.fromHash(
          adr.program.pkHash,
          version: networkParams.p2shPrefix,
        );

        // TODO ??????????????
        return (address: addr, addressType: AddressType.p2sh);

      case DerivePathType.bip84:
        final addr = coinlib.P2WPKHAddress.fromPublicKey(
          publicKey,
          hrp: networkParams.bech32Hrp,
        );

        return (address: addr, addressType: AddressType.p2wpkh);
        break;
      default:
        throw Exception("DerivePathType $derivePathType not supported");
    }
  }
}
