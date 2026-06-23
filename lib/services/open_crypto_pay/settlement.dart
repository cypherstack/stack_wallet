import 'package:decimal/decimal.dart';

import '../../db/isar/main_db.dart';
import '../../models/input.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/logger.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../wallets/isar/models/spark_coin.dart';
import '../../wallets/models/tx_data.dart';
import '../../wallets/wallet/impl/ethereum_wallet.dart';
import '../../wallets/wallet/impl/sub_wallets/eth_token_wallet.dart';
import '../../wallets/wallet/wallet.dart';
import 'models.dart';
import 'open_crypto_pay_api.dart';

class OpenCryptoPaySettlement {
  OpenCryptoPaySettlement({
    required this.wallet,
    required this.txData,
    required this.commit,
    required this.mainDB,
    required this.isTokenTx,
    this.tokenWallet,
  });

  // OCP raw-hex commits are GET query params; keep Firo near common header caps.
  static const int maxRawHexQueryLength = 8000;

  final Wallet wallet;
  final TxData txData;
  final OpenCryptoPayCommit commit;
  final MainDB mainDB;
  final bool isTokenTx;
  final EthTokenWallet? tokenWallet;

  bool get shouldCommitTxId => shouldCommitTxIdFor(
    method: commit.method,
    submissionFlow: commit.submissionFlow,
    cryptoCurrency: wallet.cryptoCurrency,
    hasSparkInputs: txData.usedSparkCoins?.isNotEmpty == true,
    rawHexLength: txData.raw?.length ?? 0,
  );

  static bool shouldCommitTxIdFor({
    required String method,
    required OpenCryptoPaySubmissionFlow submissionFlow,
    required CryptoCurrency cryptoCurrency,
    required bool hasSparkInputs,
    required int rawHexLength,
  }) {
    if (submissionFlow == OpenCryptoPaySubmissionFlow.txIdAfterLocalBroadcast) {
      return true;
    }
    return method == 'Firo' &&
        cryptoCurrency is Firo &&
        (hasSparkInputs || rawHexLength > maxRawHexQueryLength);
  }

  bool get shouldSubmitRawHex => !shouldCommitTxId && commit.canCommitRawHex;

  String? validate() {
    final minFeeError = _validateMinFee();
    if (minFeeError != null) return minFeeError;

    final transactionError = _validateTransaction();
    if (transactionError != null) return transactionError;

    final tokenError = _validateToken();
    if (tokenError != null) return tokenError;

    switch (commit.submissionFlow) {
      case OpenCryptoPaySubmissionFlow.txIdAfterLocalBroadcast:
        return null;
      case OpenCryptoPaySubmissionFlow.rawHexToProvider:
        if (shouldCommitTxId) return null;
        if (wallet.cryptoCurrency is! Firo &&
            wallet.cryptoCurrency is! Ethereum &&
            wallet.cryptoCurrency is! Bitcoin) {
          return "This Open CryptoPay method is not supported yet";
        }
        if (wallet.cryptoCurrency is Ethereum) {
          if (txData.web3dartTransaction == null || txData.chainId == null) {
            return "Could not build signed Ethereum transaction";
          }
        } else if (txData.raw == null || txData.raw!.isEmpty) {
          return "Could not build signed transaction";
        }
        return null;
    }
  }

  Future<TxData> submitRawHex(Wallet submitWallet) async {
    _ensureQuoteNotExpired();

    final signedTx = await _prepareRawHexTx(submitWallet, txData);
    final raw = signedTx.raw;
    if (raw == null || raw.isEmpty) {
      throw Exception("Could not build signed transaction");
    }

    final txid = signedTx.tempTx?.txid ?? signedTx.txid ?? signedTx.txHash;
    if (txid == null || txid.isEmpty) {
      throw Exception("Could not determine signed transaction ID");
    }

    _ensureQuoteNotExpired();
    await OpenCryptoPayApi.instance.commitRawHex(commit: commit, hex: raw);

    final updatedInputs = signedTx.usedUTXOs?.map((e) {
      if (e is StandardInput) {
        return StandardInput(
          e.utxo.copyWith(used: true),
          derivePathType: e.derivePathType,
        );
      }
      return e;
    }).toList();

    final updatedTxData = signedTx.copyWith(
      usedUTXOs: updatedInputs,
      txHash: txid,
      txid: txid,
    );

    final updatedUtxos = updatedInputs
        ?.whereType<StandardInput>()
        .map((e) => e.utxo)
        .toList();
    if (updatedUtxos != null && updatedUtxos.isNotEmpty) {
      await mainDB.putUTXOs(updatedUtxos);
    }

    if (updatedTxData.usedSparkCoins != null &&
        updatedTxData.usedSparkCoins!.isNotEmpty) {
      await mainDB.isar.writeTxn(() async {
        await mainDB.isar.sparkCoins.putAll(updatedTxData.usedSparkCoins!);
      });
    }

    return await submitWallet.updateSentCachedTxData(txData: updatedTxData);
  }

  Future<void> commitTxId(TxData txData) async {
    _ensureQuoteNotExpired();

    try {
      await OpenCryptoPayApi.instance.commitTxId(
        commit: commit,
        txId: txData.txid!,
      );
    } catch (e, s) {
      Logging.instance.e(
        "OpenCryptoPay commit failed after local broadcast",
        error: e,
        stackTrace: s,
      );
      throw Exception(
        "Open CryptoPay commit failed after broadcasting "
        "${txData.txid}: $e",
      );
    }
  }

  String? _validateTransaction() {
    return validateTransaction(
      cryptoCurrency: wallet.cryptoCurrency,
      recipients: _recipients(txData),
      recipientAddress: commit.recipientAddress,
      amount: commit.amount,
    );
  }

  static String? validateTransaction({
    required CryptoCurrency cryptoCurrency,
    required List<({String address, Amount amount})> recipients,
    required String recipientAddress,
    required Decimal amount,
  }) {
    if (recipients.length != 1) {
      return "Open CryptoPay requires exactly one recipient";
    }

    final actual = recipients.single;
    if (_normalizeAddress(cryptoCurrency, actual.address) !=
        _normalizeAddress(cryptoCurrency, recipientAddress)) {
      return "Open CryptoPay recipient changed. Please scan again.";
    }

    if (actual.amount.decimal != amount) {
      return "Open CryptoPay amount changed. Please scan again.";
    }

    return null;
  }

  String? _validateToken() => validateToken(
    commit: commit,
    isTokenTx: isTokenTx,
    tokenContractAddress: tokenWallet?.tokenContract.address,
    tokenSymbol: tokenWallet?.tokenContract.symbol,
    tokenDecimals: tokenWallet?.tokenContract.decimals,
  );

  static String? validateToken({
    required OpenCryptoPayCommit commit,
    required bool isTokenTx,
    String? tokenContractAddress,
    String? tokenSymbol,
    int? tokenDecimals,
  }) {
    final commitTokenAddress = commit.tokenContractAddress;
    if (commitTokenAddress == null) return null;

    if (!isTokenTx || commit.method != 'Ethereum') {
      return "Open CryptoPay token payment is not supported here";
    }

    if (tokenContractAddress == null || tokenSymbol == null) {
      return "Could not verify Open CryptoPay token wallet";
    }

    if (tokenContractAddress.toLowerCase() !=
        commitTokenAddress.toLowerCase()) {
      return "Open CryptoPay token contract changed. Please scan again.";
    }

    if (tokenSymbol.toUpperCase() != commit.asset.toUpperCase()) {
      return "Open CryptoPay token asset changed. Please scan again.";
    }

    final expectedDecimals = commit.tokenDecimals;
    if (expectedDecimals != null && tokenDecimals != expectedDecimals) {
      return "Open CryptoPay token decimals changed. Please scan again.";
    }

    return null;
  }

  void _ensureQuoteNotExpired() {
    if (commit.isExpired) {
      throw Exception("Open CryptoPay quote expired. Please scan again.");
    }
  }

  String? _validateMinFee() => validateMinFee(
    cryptoCurrency: wallet.cryptoCurrency,
    minFee: commit.minFee,
    gasPrice: txData.web3dartTransaction?.maxFeePerGas?.getInWei,
    fee: txData.fee,
    vSize: txData.vSize,
  );

  static String? validateMinFee({
    required CryptoCurrency cryptoCurrency,
    required Decimal minFee,
    BigInt? gasPrice,
    Amount? fee,
    int? vSize,
  }) {
    if (minFee <= Decimal.zero) return null;

    if (cryptoCurrency is Ethereum) {
      if (gasPrice == null) {
        return "Could not verify Open CryptoPay minimum gas price";
      }
      if (gasPrice < _ceilDecimalToBigInt(minFee)) {
        return "Open CryptoPay requires at least "
            "$minFee wei gas price";
      }
      return null;
    }

    if (cryptoCurrency is Bitcoin || cryptoCurrency is Firo) {
      if (fee == null || vSize == null || vSize <= 0) {
        return "Could not verify Open CryptoPay minimum fee";
      }
      final minTotalFee = _ceilDecimalToBigInt(minFee * Decimal.fromInt(vSize));
      if (fee.raw < minTotalFee) {
        return "Open CryptoPay requires at least "
            "$minFee sat/vB fee";
      }
    }

    return null;
  }

  static BigInt _ceilDecimalToBigInt(Decimal value) {
    return value.ceil().toBigInt();
  }

  List<({String address, Amount amount})> _recipients(TxData txData) {
    final recipients = <({String address, Amount amount})>[];
    final standardRecipients = txData.recipients;
    if (standardRecipients != null) {
      for (final recipient in standardRecipients) {
        if (!recipient.isChange) {
          recipients.add((
            address: recipient.address,
            amount: recipient.amount,
          ));
        }
      }
    }
    final sparkRecipients = txData.sparkRecipients;
    if (sparkRecipients != null) {
      for (final recipient in sparkRecipients) {
        if (!recipient.isChange) {
          recipients.add((
            address: recipient.address,
            amount: recipient.amount,
          ));
        }
      }
    }
    return recipients;
  }

  static String _normalizeAddress(
    CryptoCurrency cryptoCurrency,
    String address,
  ) {
    if (cryptoCurrency is Ethereum) return address.toLowerCase();
    return address;
  }

  Future<TxData> _prepareRawHexTx(Wallet wallet, TxData txData) async {
    if (wallet is EthTokenWallet) {
      return await wallet.signSendWithoutBroadcast(txData: txData);
    }
    if (wallet is EthereumWallet) {
      return await wallet.signSendWithoutBroadcast(txData: txData);
    }

    return txData;
  }
}
