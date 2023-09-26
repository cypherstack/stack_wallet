import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/bip39_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/example/libepiccash.dart';

class Epiccash extends Bip39Currency {
  Epiccash(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.epicCash;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  // change this to change the number of confirms a tx needs in order to show as confirmed
  int get minConfirms => 3;

  @override
  bool validateAddress(String address) {
    // Invalid address that contains HTTP and epicbox domain
    if ((address.startsWith("http://") || address.startsWith("https://")) &&
        address.contains("@")) {
      return false;
    }
    if (address.startsWith("http://") || address.startsWith("https://")) {
      if (Uri.tryParse(address) != null) {
        return true;
      }
    }

    return LibEpiccash.validateSendAddress(address: address);
  }

  String getMnemonic() {
    return LibEpiccash.getMnemonic();
  }

  Future<void> createNewWallet(
      ({
        String config,
        String mnemonic,
        String password,
        String name,
      })? data) async {
    await LibEpiccash.initializeNewWallet(
        config: data!.config,
        mnemonic: data.mnemonic,
        password: data.password,
        name: data.name);
  }

  Future<void> scanOutputs(
      ({String wallet, int startHeight, int numberOfBlocks})? data) async {
    await LibEpiccash.scanOutputs(
      wallet: data!.wallet,
      startHeight: data.startHeight,
      numberOfBlocks: data.numberOfBlocks,
    );
  }

  Future<void> createTransaction(
      ({
        String wallet,
        int amount,
        String address,
        int secretKey,
        String epicboxConfig,
        int minimumConfirmations,
        String note,
      })? data) async {
    await LibEpiccash.createTransaction(
        wallet: data!.wallet,
        amount: data.amount,
        address: data.address,
        secretKey: data.secretKey,
        epicboxConfig: data.epicboxConfig,
        minimumConfirmations: data.minimumConfirmations,
        note: data.note);
  }

  Future<void> getTransaction(
      ({
        String wallet,
        int refreshFromNode,
      })? data) async {
    await LibEpiccash.getTransaction(
      wallet: data!.wallet,
      refreshFromNode: data.refreshFromNode,
    );
  }

  Future<void> cancelTransaction(
      ({
        String wallet,
        String transactionId,
      })? data) async {
    await LibEpiccash.cancelTransaction(
      wallet: data!.wallet,
      transactionId: data.transactionId,
    );
  }

  Future<void> getAddressInfo(
      ({
        String wallet,
        int index,
        String epicboxConfig,
      })? data) async {
    await LibEpiccash.getAddressInfo(
      wallet: data!.wallet,
      index: data.index,
      epicboxConfig: data.epicboxConfig,
    );
  }
}
