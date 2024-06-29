import 'package:flutter/material.dart';
import '../../themes/stack_colors.dart';
import '../desktop/secondary_button.dart';

class SimpleMobileDialog extends StatelessWidget {
  const SimpleMobileDialog({
    super.key,
    required this.child,
    this.showCloseButton = true,
    this.padding,
  });

  final Widget child;
  final bool showCloseButton;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                  child: Padding(
                    padding: padding ?? const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            child: child,
                          ),
                        ),
                        if (showCloseButton)
                          const SizedBox(
                            height: 16,
                          ),
                        if (showCloseButton)
                          Row(
                            children: [
                              const Spacer(),
                              const SizedBox(
                                width: 16,
                              ),
                              Expanded(
                                child: SecondaryButton(
                                  label: "Close",
                                  onPressed: Navigator.of(context).pop,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
