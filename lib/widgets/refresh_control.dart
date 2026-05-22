import 'package:flutter/material.dart';

import '../themes/stack_colors.dart';
import '../utilities/util.dart';
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
    this.tooltip = "Refresh",
  });

  final VoidCallback onPressed;
  final bool isRefreshing;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).extension<StackColors>()!.textDark;
    return AppBarIconButton(
      tooltip: tooltip,
      semanticsLabel: tooltip,
      onPressed: isRefreshing ? null : onPressed,
      icon: isRefreshing
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(Icons.refresh, color: color, size: 20),
    );
  }
}
