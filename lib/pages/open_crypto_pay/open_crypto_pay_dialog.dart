import 'package:flutter/material.dart';

import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import 'open_crypto_pay_view.dart';

Future<void> showOpenCryptoPayDesktopDialog({
  required BuildContext context,
  required String qrUrl,
  required String walletId,
  required CryptoCurrency coin,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => DesktopDialog(
      maxHeight: MediaQuery.sizeOf(context).height - 64,
      maxWidth: 580,
      child: OpenCryptoPayView(
        qrUrl: qrUrl,
        walletId: walletId,
        coin: coin,
        isDesktop: true,
      ),
    ),
  );
}
