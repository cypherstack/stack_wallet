import 'package:flutter/material.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';

class DesktopDialog extends StatelessWidget {
  const DesktopDialog({
    Key? key,
    this.child,
    this.maxWidth = 641,
    this.maxHeight = 474,
  }) : super(key: key);

  final Widget? child;
  final double maxWidth;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight ?? MediaQuery.of(context).size.height - 64,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(
              20,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).extension<StackColors>()!.popupBG,
                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
