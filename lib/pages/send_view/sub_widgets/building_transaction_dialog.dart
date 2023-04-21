import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/color_theme.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

import '../../../widgets/animated_widgets/rotate_animation.dart';

class BuildingTransactionDialog extends StatefulWidget {
  const BuildingTransactionDialog({
    Key? key,
    required this.onCancel,
    required this.coin,
  }) : super(key: key);

  final VoidCallback onCancel;
  final Coin coin;

  @override
  State<BuildingTransactionDialog> createState() => _RestoringDialogState();
}

class _RestoringDialogState extends State<BuildingTransactionDialog>
    with TickerProviderStateMixin {
  late AnimationController? _spinController;
  late Animation<double> _spinAnimation;

  late RotateAnimationController? _rotateAnimationController;

  late final VoidCallback onCancel;

  @override
  void initState() {
    onCancel = widget.onCancel;

    _spinController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _spinAnimation = CurvedAnimation(
      parent: _spinController!,
      curve: Curves.linear,
    );

    _rotateAnimationController = RotateAnimationController();

    super.initState();
  }

  @override
  void dispose() {
    _spinController?.dispose();
    _spinController = null;

    _rotateAnimationController?.forward = null;
    _rotateAnimationController?.reset = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isChans = Theme.of(context).extension<StackColors>()!.themeType ==
            ThemeType.chan ||
        Theme.of(context).extension<StackColors>()!.themeType ==
            ThemeType.darkChans;

    if (Util.isDesktop) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Generating transaction",
            style: STextStyles.desktopH3(context),
          ),
          const SizedBox(
            height: 40,
          ),
          if (isChans)
            Image(
              image: AssetImage(
                Assets.gif.kiss(widget.coin),
              ),
            ),
          if (!isChans)
            RotateAnimation(
              lottie: Lottie.asset(
                Assets.lottie.arrowRotate,
                // delegates: LottieDelegates(values: []),
              ),
              curve: Curves.easeInOutCubic,
              controller: _rotateAnimationController,
            ),
          const SizedBox(
            height: 40,
          ),
          SecondaryButton(
            buttonHeight: ButtonHeight.l,
            label: "Cancel",
            onPressed: () {
              onCancel.call();
            },
          )
        ],
      );
    } else {
      return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: isChans
            ? StackDialogBase(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image(
                      image: AssetImage(
                        Assets.gif.kiss(widget.coin),
                      ),
                    ),
                    Text(
                      "Generating transaction",
                      textAlign: TextAlign.center,
                      style: STextStyles.pageTitleH2(context),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    Row(
                      children: [
                        const Spacer(),
                        Expanded(
                          child: TextButton(
                            style: Theme.of(context)
                                .extension<StackColors>()!
                                .getSecondaryEnabledButtonStyle(context),
                            child: Text(
                              "Cancel",
                              style: STextStyles.itemSubtitle12(context),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              onCancel.call();
                            },
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              )
            : StackDialog(
                title: "Generating transaction",
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
                rightButton: TextButton(
                  style: Theme.of(context)
                      .extension<StackColors>()!
                      .getSecondaryEnabledButtonStyle(context),
                  child: Text(
                    "Cancel",
                    style: STextStyles.itemSubtitle12(context),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCancel.call();
                  },
                ),
              ),
      );
    }
  }
}
