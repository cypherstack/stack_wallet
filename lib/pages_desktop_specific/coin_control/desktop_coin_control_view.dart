import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

class DesktopCoinControlView extends StatefulWidget {
  const DesktopCoinControlView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  static const String routeName = "/desktopCoinControl";

  final String walletId;

  @override
  State<DesktopCoinControlView> createState() => _DesktopCoinControlViewState();
}

class _DesktopCoinControlViewState extends State<DesktopCoinControlView> {
  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      appBar: DesktopAppBar(
        background: Theme.of(context).extension<StackColors>()!.popupBG,
        leading: Expanded(
          child: Row(
            children: [
              const SizedBox(
                width: 32,
              ),
              AppBarIconButton(
                size: 32,
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
                shadows: const [],
                icon: SvgPicture.asset(
                  Assets.svg.arrowLeft,
                  width: 18,
                  height: 18,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .topNavIconPrimary,
                ),
                onPressed: Navigator.of(context).pop,
              ),
              const SizedBox(
                width: 15,
              ),
              SvgPicture.asset(
                Assets.svg.coinControl.gamePad,
                width: 32,
                height: 32,
                color:
                    Theme.of(context).extension<StackColors>()!.textSubtitle1,
              ),
              const SizedBox(
                width: 12,
              ),
              Text(
                "Coin control",
                style: STextStyles.desktopH3(context),
              ),
            ],
          ),
        ),
        useSpacers: false,
        isCompactHeight: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 490,
                  ),
                  child: const TextField(),
                ),
                SecondaryButton(
                  label: "Show all outputs",
                  onPressed: () {
                    //
                  },
                ),
                SecondaryButton(
                  label: "Sort by",
                  onPressed: () {
                    //
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
