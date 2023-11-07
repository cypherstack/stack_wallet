import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_hd_currency.dart';

class Dogecoin extends Bip39HDCurrency {
  Dogecoin(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.dogecoin;
      case CryptoCurrencyNetwork.test:
        coin = Coin.dogecoinTestNet;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  List<DerivePathType> get supportedDerivationPathTypes => [
        DerivePathType.bip44,
      ];

  @override
  String constructDerivePath({
    required DerivePathType derivePathType,
    int account = 0,
    required int chain,
    required int index,
  }) {
    String coinType;

    switch (networkParams.wifPrefix) {
      case 0x9e: // doge mainnet wif
        coinType = "3"; // doge mainnet
        break;
      case 0xf1: // doge testnet wif
        coinType = "1"; // doge testnet
        break;
      default:
        throw Exception("Invalid Dogecoin network wif used!");
    }

    int purpose;
    switch (derivePathType) {
      case DerivePathType.bip44:
        purpose = 44;
        break;

      default:
        throw Exception("DerivePathType $derivePathType not supported");
    }

    return "m/$purpose'/$coinType'/$account'/$chain/$index";
  }

  @override
  Amount get dustLimit => Amount(
        rawValue: BigInt.from(1000000),
        fractionDigits: Coin.particl.decimals,
      );

  @override
  String get genesisHash {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return "1a91e3dace36e2be3bf030a65679fe821aa1d6ef92e7c9902eb318182c355691";
      case CryptoCurrencyNetwork.test:
        return "bb0a78264637406b6360aad926284d544d7049f45189db5664f3c4d07350559e";
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  ({
    coinlib.Address address,
    AddressType addressType,
  }) getAddressForPublicKey({
    required coinlib.ECPublicKey publicKey,
    required DerivePathType derivePathType,
  }) {
    switch (derivePathType) {
      case DerivePathType.bip44:
        final addr = coinlib.P2PKHAddress.fromPublicKey(
          publicKey,
          version: networkParams.p2pkhPrefix,
        );

        return (address: addr, addressType: AddressType.p2pkh);

      default:
        throw Exception("DerivePathType $derivePathType not supported");
    }
  }

  @override
  int get minConfirms => 1;

  @override
  coinlib.NetworkParams get networkParams {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return const coinlib.NetworkParams(
          wifPrefix: 0x9e,
          p2pkhPrefix: 0x1e,
          p2shPrefix: 0x16,
          privHDPrefix: 0x02fac398,
          pubHDPrefix: 0x02facafd,
          bech32Hrp: "doge",
          messagePrefix: '\x18Dogecoin Signed Message:\n',
        );
      case CryptoCurrencyNetwork.test:
        return const coinlib.NetworkParams(
          wifPrefix: 0xf1,
          p2pkhPrefix: 0x71,
          p2shPrefix: 0xc4,
          privHDPrefix: 0x04358394,
          pubHDPrefix: 0x043587cf,
          bech32Hrp: "tdge",
          messagePrefix: "\x18Dogecoin Signed Message:\n",
        );
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  bool validateAddress(String address) {
    try {
      coinlib.Address.fromString(address, networkParams);
      return true;
    } catch (_) {
      return false;
    }
  }
}
