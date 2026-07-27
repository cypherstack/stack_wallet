import 'package:flutter/material.dart';

import '../../wallets/crypto_currency/crypto_currency.dart';
import 'open_crypto_pay_view.dart';
import 'open_crypto_pay_widgets.dart';

Future<void> showOpenCryptoPayPaymentDesktopDialog({
  required BuildContext context,
  required String qrUrl,
  required String walletId,
  required CryptoCurrency coin,
}) {
  return showOpenCryptoPayDesktopDialog<void>(
    context: context,
    child: OpenCryptoPayView(
      qrUrl: qrUrl,
      walletId: walletId,
      coin: coin,
      isDesktop: true,
    ),
  );
}
