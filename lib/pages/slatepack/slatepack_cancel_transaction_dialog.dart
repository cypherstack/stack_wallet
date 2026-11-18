import 'package:flutter/material.dart';

import '../../utilities/util.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/stack_dialog.dart';

class SlatepackCancelTransactionDialog extends StatelessWidget {
  const SlatepackCancelTransactionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return StackDialog(
      title: "Cancel this transaction?",
      width: Util.isDesktop ? 400 : null,
      padding: EdgeInsets.all(Util.isDesktop ? 24 : 16),
      stackButtons: !Util.isDesktop,
      message:
          "The other party can no longer complete it, and any funds it locked "
          "become spendable again.",
      leftButton: SecondaryButton(
        label: "Go back",
        onPressed: () => Navigator.of(context).pop(false),
      ),
      rightButton: PrimaryButton(
        label: "Cancel it",
        onPressed: () => Navigator.of(context).pop(true),
      ),
    );
  }
}
