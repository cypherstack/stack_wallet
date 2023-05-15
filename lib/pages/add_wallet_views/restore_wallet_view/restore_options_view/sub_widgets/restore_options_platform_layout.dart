import 'package:flutter/material.dart';
import 'package:stackwallet/themes/stack_colors.dart';

class RestoreOptionsPlatformLayout extends StatelessWidget {
  const RestoreOptionsPlatformLayout({
    Key? key,
    required this.isDesktop,
    required this.child,
  }) : super(key: key);

  final bool isDesktop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return child;
    } else {
      return Container(
        color: Theme.of(context).extension<StackColors>()!.background,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: child,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }
}
