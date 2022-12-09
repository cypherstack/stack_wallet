import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/utilities/util.dart';
import 'package:epicpay/widgets/desktop/desktop_dialog.dart';
import 'package:epicpay/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:epicpay/widgets/desktop/secondary_button.dart';
import 'package:epicpay/widgets/stack_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class RestoringDialog extends StatefulWidget {
  const RestoringDialog({
    Key? key,
    required this.onCancel,
  }) : super(key: key);

  final Future<void> Function() onCancel;

  @override
  State<RestoringDialog> createState() => _RestoringDialogState();
}

class _RestoringDialogState extends State<RestoringDialog>
    with TickerProviderStateMixin {
  late AnimationController? _spinController;
  late Animation<double> _spinAnimation;

  late final Future<void> Function() onCancel;
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
        child: Column(
          children: [
            DesktopDialogCloseButton(
              onPressedOverride: () async {
                await onCancel.call();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            const Spacer(
              flex: 1,
            ),
            RotationTransition(
              turns: _spinAnimation,
              child: SvgPicture.asset(Assets.svg.arrowRotate3,
                  width: 40,
                  height: 40,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .accentColorDark),
            ),
            const Spacer(
              flex: 2,
            ),
            Text(
              "Restoring wallet...",
              style: STextStyles.desktopH2(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              "Restoring your wallet may take a while.\nPlease do not exit this screen.",
              style: STextStyles.desktopTextMedium(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(
              flex: 2,
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 32,
                right: 32,
                bottom: 32,
              ),
              child: SecondaryButton(
                label: "Cancel",
                width: 272.5,
                onPressed: () async {
                  await onCancel.call();
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        ),
      );
    } else {
      return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: StackDialog(
          title: "Restoring wallet",
          message: "This may take a while. Please do not exit this screen.",
          icon: RotationTransition(
            turns: _spinAnimation,
            child: SvgPicture.asset(Assets.svg.arrowRotate3,
                width: 24,
                height: 24,
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .accentColorDark),
          ),
          rightButton: TextButton(
            style: Theme.of(context)
                .extension<StackColors>()!
                .getSecondaryEnabledButtonColor(context),
            child: Text(
              "Cancel",
              style: STextStyles.itemSubtitle12(context),
            ),
            onPressed: () async {
              await onCancel.call();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      );
    }
  }
}
