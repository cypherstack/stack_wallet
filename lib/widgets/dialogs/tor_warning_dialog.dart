import 'package:flutter/cupertino.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/dialogs/basic_dialog.dart';

class TorWarningDialog extends StatelessWidget {
  final CryptoCurrency coin;
  final VoidCallback? onContinue;
  final VoidCallback? onCancel;

  const TorWarningDialog({
    super.key,
    required this.coin,
    this.onContinue,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return BasicDialog(
      title: "Warning!  Tor not supported.",
      message: "${coin.prettyName} is not compatible with Tor.  "
          "Continuing will leak your IP address."
          "\n\nAre you sure you want to continue?",
      // A PrimaryButton widget:
      leftButton: PrimaryButton(
        label: "Cancel",
        onPressed: () {
          onCancel?.call();
          Navigator.of(context).pop(false);
        },
      ),
      rightButton: SecondaryButton(
        label: "Continue",
        onPressed: () {
          onContinue?.call();
          Navigator.of(context).pop(true);
        },
      ),
      flex: true,
    );
  }
}
