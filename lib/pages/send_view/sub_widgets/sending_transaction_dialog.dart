import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class SendingTransactionDialog extends StatefulWidget {
  const SendingTransactionDialog({
    Key? key,
    required this.coin,
  }) : super(key: key);

  final Coin coin;

  @override
  State<SendingTransactionDialog> createState() => _RestoringDialogState();
}

class _RestoringDialogState extends State<SendingTransactionDialog>
    with TickerProviderStateMixin {
  late AnimationController? _spinController;
  late Animation<double> _spinAnimation;

  @override
  void initState() {
    _spinController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _spinAnimation = CurvedAnimation(
      parent: _spinController!,
      curve: Curves.linear,
    );

    super.initState();
  }

  @override
  void dispose() {
    _spinController?.dispose();
    _spinController = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      return DesktopDialog(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Sending transaction",
                style: STextStyles.desktopH3(context),
              ),
              const SizedBox(
                height: 40,
              ),
              Theme.of(context).extension<StackColors>()!.themeType ==
                      ThemeType.chan
                  ? Lottie.asset(
                      Assets.lottie.kiss(widget.coin),
                    )
                  : RotationTransition(
                      turns: _spinAnimation,
                      child: SvgPicture.asset(
                        Assets.svg.arrowRotate,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark,
                        width: 24,
                        height: 24,
                      ),
                    ),
            ],
          ),
        ),
      );
    } else {
      return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: Theme.of(context).extension<StackColors>()!.themeType ==
                ThemeType.chan
            ? StackDialogBase(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      Assets.lottie.kiss(widget.coin),
                    ),
                    Text(
                      "Sending transaction",
                      textAlign: TextAlign.center,
                      style: STextStyles.pageTitleH2(context),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                  ],
                ),
              )
            : StackDialog(
                title: "Sending transaction",
                icon: RotationTransition(
                  turns: _spinAnimation,
                  child: SvgPicture.asset(
                    Assets.svg.arrowRotate,
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorDark,
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
      );
    }
  }
}
