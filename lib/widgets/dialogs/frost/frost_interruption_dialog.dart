import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

enum FrostInterruptionDialogType {
  walletCreation,
  resharing,
  transactionCreation;
}

class FrostInterruptionDialog extends StatelessWidget {
  const FrostInterruptionDialog({
    super.key,
    required this.type,
    required this.popUntilOnYesRouteName,
    this.onNoPressedOverride,
    this.onYesPressedOverride,
  });

  final FrostInterruptionDialogType type;
  final String popUntilOnYesRouteName;
  final VoidCallback? onNoPressedOverride;
  final VoidCallback? onYesPressedOverride;

  String get message {
    switch (type) {
      case FrostInterruptionDialogType.walletCreation:
        return "wallet creation";
      case FrostInterruptionDialogType.resharing:
        return "resharing";
      case FrostInterruptionDialogType.transactionCreation:
        return "transaction signing";
    }
  }

  @override
  Widget build(BuildContext context) {
    return StackDialog(
      title: "Cancel $message process",
      message: "Are you sure you want to cancel the $message process?",
      leftButton: SecondaryButton(
        label: "No",
        onPressed: onNoPressedOverride ??
            Navigator.of(
              context,
              rootNavigator: Util.isDesktop,
            ).pop,
      ),
      rightButton: PrimaryButton(
        label: "Yes",
        onPressed: onYesPressedOverride ??
            () {
              // pop dialog
              Navigator.of(
                context,
                rootNavigator: Util.isDesktop,
              ).pop();

              Navigator.of(context).popUntil(
                ModalRoute.withName(
                  popUntilOnYesRouteName,
                ),
              );
            },
      ),
    );
  }
}
