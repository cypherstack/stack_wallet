import 'package:flutter/material.dart';

import '../themes/stack_colors.dart';
import '../utilities/util.dart';
import 'animated_widgets/rotating_arrows.dart';
import 'custom_buttons/app_bar_icon_button.dart';

/// Wraps a scrollable [child] with a [RefreshIndicator] on mobile. On
/// desktop, returns [child] unchanged — desktop screens place a
/// [RefreshButton] in their dialog header instead.
class RefreshControl extends StatelessWidget {
  const RefreshControl({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) return child;
    return RefreshIndicator(onRefresh: onRefresh, child: child);
  }
}

/// Circular icon button for desktop screens. Shows a spinner while
/// [isRefreshing] is true; otherwise a refresh icon. Disabled while
/// refreshing so taps don't stack overlapping requests.
class RefreshButton extends StatelessWidget {
  const RefreshButton({
    super.key,
    required this.onPressed,
    required this.isRefreshing,
    // this.tooltip = "Refresh",
  });

  final VoidCallback onPressed;
  final bool isRefreshing;
  // final String tooltip;

  @override
  Widget build(BuildContext context) {
    return AppBarIconButton(
      // Don't use tooltip to be consistent with rest of UI
      // tooltip: tooltip,TODO revisit this if adding tooltips to other controls
      // semanticsLabel: tooltip,
      color: Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
      size: 40,
      onPressed: isRefreshing ? null : onPressed,
      icon: RotatingArrows(
        spinByDefault: isRefreshing,
        width: Util.isDesktop ? 21 : 24,
        height: Util.isDesktop ? 21 : 24,
      ),
    );
  }
}
