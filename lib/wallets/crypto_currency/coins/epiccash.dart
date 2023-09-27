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

  Future<String?> createNewWallet(
      ({
        String config,
        String mnemonic,
        String password,
        String name,
      })? data) async {
    String result = await LibEpiccash.initializeNewWallet(
        config: data!.config,
        mnemonic: data.mnemonic,
        password: data.password,
        name: data.name);

    if (result.isNotEmpty) {
      return result;
    }
    return null;
  }

  Future<({double awaitingFinalization, double pending, double spendable, double total})>
      getWalletInfo(
          ({
            String wallet,
            int refreshFromNode,
          })? data) async {
    var result = await LibEpiccash.getWalletBalances(
        wallet: data!.wallet,
        refreshFromNode: data.refreshFromNode,
        minimumConfirmations: minConfirms);
    return result;
  }

  Future<String?> scanOutputs(
      ({String wallet, int startHeight, int numberOfBlocks})? data) async {
    var result = await LibEpiccash.scanOutputs(
      wallet: data!.wallet,
      startHeight: data.startHeight,
      numberOfBlocks: data.numberOfBlocks,
    );

    if (result.isNotEmpty) {
      return result;
    }
    return null;
  }

  Future<String?> createTransaction(
      ({
        String wallet,
        int amount,
        String address,
        int secretKey,
        String epicboxConfig,
        String note,
      })? data) async {
    var result = await LibEpiccash.createTransaction(
      wallet: data!.wallet,
      amount: data.amount,
      address: data.address,
      secretKey: data.secretKey,
      epicboxConfig: data.epicboxConfig,
      minimumConfirmations: minConfirms,
      note: data.note,
    );

    if (result.isNotEmpty) {
      return result;
    }
    return null;
  }

  Future<String?> getTransaction(
      ({
        String wallet,
        int refreshFromNode,
      })? data) async {
    var result = await LibEpiccash.getTransaction(
      wallet: data!.wallet,
      refreshFromNode: data.refreshFromNode,
    );

    if (result.isNotEmpty) {
      return result;
    }
    return null;
  }

  Future<String?> cancelTransaction(
      ({
        String wallet,
        String transactionId,
      })? data) async {
    var result = await LibEpiccash.cancelTransaction(
      wallet: data!.wallet,
      transactionId: data.transactionId,
    );

    if (result.isNotEmpty) {
      return result;
    }
    return null;
  }

  Future<String?> getAddressInfo(
      ({
        String wallet,
        int index,
        String epicboxConfig,
      })? data) async {
    var result = await LibEpiccash.getAddressInfo(
      wallet: data!.wallet,
      index: data.index,
      epicboxConfig: data.epicboxConfig,
    );

    if (result.isNotEmpty) {
      return result;
    }
    return null;
  }

  static Future<String?> transactionFees(
    ({
      String wallet,
      int amount,
      int minimumConfirmations,
    })? data,
  ) async {
    var result = await LibEpiccash.getTransactionFees(
      wallet: data!.wallet,
      amount: data.amount,
      minimumConfirmations: data.minimumConfirmations,
    );
    if (result.isNotEmpty) {
      return result;
    }
    return null;
  }

  static Future<String?> deleteWallet(
    ({
      String wallet,
      String config,
    })? data,
  ) async {
    var result = await LibEpiccash.deleteWallet(
      wallet: data!.wallet,
      config: data.config,
    );
    if (result.isNotEmpty) {
      return result;
    }
    return null;
  }

  static Future<String?> openWallet(
    ({
      String config,
      String password,
    })? data,
  ) async {
    var result = await LibEpiccash.openWallet(
      config: data!.config,
      password: data.password,
    );
    if (result.isNotEmpty) {
      return result;
    }
    return null;
  }

  static Future<String?> txHttpSend(
    ({
      String wallet,
      int selectionStrategyIsAll,
      int minimumConfirmations,
      String message,
      int amount,
      String address,
    })? data,
  ) async {
    var result = await LibEpiccash.txHttpSend(
      wallet: data!.wallet,
      selectionStrategyIsAll: data.selectionStrategyIsAll,
      minimumConfirmations: data.minimumConfirmations,
      message: data.message,
      amount: data.amount,
      address: data.address,
    );
    if (result.isNotEmpty) {
      return result;
    }
    return null;
  }
}
