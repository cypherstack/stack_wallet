import '../../wallets/crypto_currency/crypto_currency.dart';
import 'models.dart';

/// Centralizes which Open CryptoPay methods Stack can complete safely with the
/// existing send flow.
class OpenCryptoPayMethodSupport {
  const OpenCryptoPayMethodSupport._();

  static const _methodsByCoinType = <Type, String>{
    Bitcoin: 'Bitcoin',
    Solana: 'Solana',
    Cardano: 'Cardano',
    Firo: 'Firo',
  };

  static OpenCryptoPaySubmissionFlow? submissionFlowFor(String method) {
    switch (method) {
      case 'Solana':
      case 'Cardano':
        return OpenCryptoPaySubmissionFlow.txIdAfterLocalBroadcast;
      case 'Monero':
        // Monero can be revisited on the txid flow in a follow-up; this PR
        // keeps support scoped to methods already validated here.
        return null;
      case 'Ethereum':
      case 'Bitcoin':
      case 'Firo':
        // Firo starts here for transparent/provider-broadcast payments; Spark
        // or oversized raw transactions fall back to txid at confirmation.
        return OpenCryptoPaySubmissionFlow.rawHexToProvider;
      default:
        // Known unsupported methods include Lightning, BinancePay, and ICP.
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
    final methodName = _methodForCoin(coin);

    if (methodName == null || method.method != methodName) return false;

    if (coin is Ethereum) {
      if (assetTicker == ticker) return true;
      return enabledErc20Symbols
          .map((e) => e.toUpperCase())
          .contains(assetTicker);
    }

    return assetTicker == ticker;
  }

  static String? _methodForCoin(CryptoCurrency coin) =>
      coin is Ethereum ? 'Ethereum' : _methodsByCoinType[coin.runtimeType];
}
