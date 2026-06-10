import '../../wallets/crypto_currency/crypto_currency.dart';
import 'models.dart';

/// Centralizes which Open CryptoPay methods Stack can complete safely with the
/// existing send flow.
class OpenCryptoPayMethodSupport {
  const OpenCryptoPayMethodSupport._();

  static bool hasSupportedWalletCoin(CryptoCurrency coin) {
    return coin is Bitcoin ||
        coin is Ethereum ||
        coin is Solana ||
        coin is Cardano ||
        coin is Firo;
  }

  static OpenCryptoPaySubmissionFlow? submissionFlowFor(String method) {
    switch (method) {
      case 'Solana':
      case 'Cardano':
        return OpenCryptoPaySubmissionFlow.txIdAfterLocalBroadcast;
      // The OCP spec requires Monero callbacks to include both txid and raw
      // transaction hex. Stack does not currently expose the raw hex here.
      case 'Monero':
        return null;
      case 'Ethereum':
      case 'Bitcoin':
      case 'Firo':
        return OpenCryptoPaySubmissionFlow.rawHexToProvider;
      case 'Lightning':
      case 'BinancePay':
      case 'InternetComputer':
        return null;
      default:
        return null;
    }
  }

  static bool isSupportedWalletOption({
    required CryptoCurrency coin,
    required OpenCryptoPayTransferMethod method,
    required OpenCryptoPayAsset asset,
    Iterable<String> enabledErc20Symbols = const [],
  }) {
    final ticker = coin.ticker.toUpperCase();
    final assetTicker = asset.asset.toUpperCase();

    if (coin is Bitcoin) {
      return method.method == 'Bitcoin' && assetTicker == ticker;
    }
    if (coin is Ethereum) {
      if (method.method != 'Ethereum') return false;
      if (assetTicker == ticker) return true;
      return enabledErc20Symbols
          .map((e) => e.toUpperCase())
          .contains(assetTicker);
    }
    if (coin is Solana) {
      return method.method == 'Solana' && assetTicker == ticker;
    }
    if (coin is Cardano) {
      return method.method == 'Cardano' && assetTicker == ticker;
    }
    if (coin is Firo) {
      return method.method == 'Firo' && assetTicker == ticker;
    }

    return false;
  }
}
