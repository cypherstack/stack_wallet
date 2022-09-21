import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class BuildingTransactionDialog extends StatefulWidget {
  const BuildingTransactionDialog({
    Key? key,
    required this.onCancel,
  }) : super(key: key);

  final VoidCallback onCancel;

  @override
  State<BuildingTransactionDialog> createState() => _RestoringDialogState();
}

class _RestoringDialogState extends State<BuildingTransactionDialog>
    with TickerProviderStateMixin {
  late AnimationController? _spinController;
  late Animation<double> _spinAnimation;

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
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: StackDialog(
        title: "Generating transaction",
        // // TODO get message from design team
        // message: "<PLACEHOLDER>",
        icon: RotationTransition(
          turns: _spinAnimation,
          child: SvgPicture.asset(
            Assets.svg.arrowRotate,
            color: CFColors.stackAccent,
            width: 24,
            height: 24,
          ),
        ),
        rightButton: TextButton(
          style: StackTheme.instance.getSecondaryEnabledButtonColor(context),
          child: Text(
            "Cancel",
            style: STextStyles.itemSubtitle12,
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
