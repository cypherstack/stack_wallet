import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class ConfirmPaynymConnectDialog extends StatelessWidget {
  const ConfirmPaynymConnectDialog({
    Key? key,
    required this.nymName,
    required this.onConfirmPressed,
    required this.amount,
    required this.coin,
  }) : super(key: key);

  final String nymName;
  final VoidCallback onConfirmPressed;
  final int amount;
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return StackDialog(
      title: "Connect to $nymName",
      icon: SvgPicture.asset(
        Assets.svg.userPlus,
        color: Theme.of(context).extension<StackColors>()!.textDark,
        width: 24,
        height: 24,
      ),
      message: "A one-time connection fee of "
          "${Format.satoshisToAmount(amount, coin: coin)} ${coin.ticker} "
          "will be charged to connect to this PayNym.\n\nThis fee "
          "covers the cost of creating a one-time transaction to create a "
          "record on the blockchain. This keeps PayNyms decentralized.",
      leftButton: SecondaryButton(
        buttonHeight: ButtonHeight.xl,
        label: "Cancel",
        onPressed: Navigator.of(context).pop,
      ),
      rightButton: PrimaryButton(
        buttonHeight: ButtonHeight.xl,
        label: "Connect",
        onPressed: onConfirmPressed,
      ),
    );
  }
}
