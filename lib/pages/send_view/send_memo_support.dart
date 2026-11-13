import '../../utilities/address_utils.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';

bool supportsOptionalSendMemo(CryptoCurrency coin) =>
    coin is Stellar || coin is Solana || coin is Zcash;

String? optionalSendMemo(CryptoCurrency coin, String memo) =>
    supportsOptionalSendMemo(coin) ? memo : null;

/// Returns a ZIP-321 memo only when the existing text memo field can represent
/// it without loss. Binary memos remain available on [PaymentUriRecipient].
String? paymentUriMemoText(CryptoCurrency coin, PaymentUriData paymentData) {
  if (coin is! Zcash || paymentData.recipients.length != 1) {
    return null;
  }
  return paymentData.recipients.single.memoText;
}
