import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class DesktopDialog extends StatelessWidget {
  const DesktopDialog({Key? key, this.child}) : super(key: key);

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 641,
            maxHeight: 474,
          ),
          child: Material(
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
