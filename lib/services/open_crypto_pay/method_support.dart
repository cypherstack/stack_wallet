import '../../wallets/crypto_currency/crypto_currency.dart';
import 'models.dart';

/// Centralizes which Open CryptoPay methods Stack can complete safely with the
/// existing send flow.
class OpenCryptoPayMethodSupport {
  const OpenCryptoPayMethodSupport._();

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
      case 'Polygon':
      case 'Arbitrum':
      case 'Optimism':
      case 'Base':
      case 'BinanceSmartChain':
      case 'Bitcoin':
      case 'Firo':
        return OpenCryptoPaySubmissionFlow.rawHexToProvider;
      case 'Lightning':
      case 'BinancePay':
      case 'InternetComputer':
        return OpenCryptoPaySubmissionFlow.external;
      default:
        return null;
    }
  }

  static bool isSupportedWalletOption({
    required CryptoCurrency coin,
    required OpenCryptoPayTransferMethod method,
    required OpenCryptoPayAsset asset,
  }) {
    final ticker = coin.ticker.toUpperCase();
    final assetTicker = asset.asset.toUpperCase();

    if (coin is Bitcoin) {
      return method.method == 'Bitcoin' && assetTicker == ticker;
    }
    if (coin is Ethereum) {
      return method.method == 'Ethereum' && assetTicker == ticker;
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
