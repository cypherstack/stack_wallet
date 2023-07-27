import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class SendOrdinalUnfreezeDialog extends StatelessWidget {
  const SendOrdinalUnfreezeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return StackDialog(
      title: "This ordinal is frozen",
      icon: SvgPicture.asset(
        Assets.svg.coinControl.blocked,
        width: 24,
        height: 24,
        color: Theme.of(context).extension<StackColors>()!.textDark,
      ),
      message: "To send this ordinal, you must unfreeze it first.",
      leftButton: SecondaryButton(
        label: "Cancel",
        onPressed: Navigator.of(context).pop,
      ),
      rightButton: PrimaryButton(
        label: "Unfreeze",
        onPressed: () {
          Navigator.of(context).pop("unfreeze");
        },
      ),
    );
  }
}

class UnfreezeOrdinalDialog extends StatelessWidget {
  const UnfreezeOrdinalDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return StackDialog(
      title: "Are you sure you want to unfreeze this ordinal?",
      icon: SvgPicture.asset(
        Assets.svg.coinControl.blocked,
        width: 24,
        height: 24,
        color: Theme.of(context).extension<StackColors>()!.textDark,
      ),
      leftButton: SecondaryButton(
        label: "Cancel",
        onPressed: Navigator.of(context).pop,
      ),
      rightButton: PrimaryButton(
        label: "Unfreeze",
        onPressed: () {
          Navigator.of(context).pop("unfreeze");
        },
      ),
    );
  }
}
