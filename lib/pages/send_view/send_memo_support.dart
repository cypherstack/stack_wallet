import '../../wallets/crypto_currency/crypto_currency.dart';

bool supportsOptionalSendMemo(CryptoCurrency coin) =>
    coin is Stellar || coin is Solana || coin is Zcash;

String? optionalSendMemo(CryptoCurrency coin, String memo) =>
    supportsOptionalSendMemo(coin) ? memo : null;
