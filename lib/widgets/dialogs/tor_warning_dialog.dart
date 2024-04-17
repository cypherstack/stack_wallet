import 'package:flutter/cupertino.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/dialogs/basic_dialog.dart';

class TorWarningDialog extends StatelessWidget {
  final Coin coin;
  final VoidCallback? onContinue;
  final VoidCallback? onCancel;

  TorWarningDialog({
    Key? key,
    required this.coin,
    this.onContinue,
    this.onCancel,
  }) : super(key: key);

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
