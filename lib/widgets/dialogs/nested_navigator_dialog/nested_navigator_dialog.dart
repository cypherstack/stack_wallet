import 'package:flutter/material.dart';

import '../../../utilities/text_styles.dart';
import '../../desktop/desktop_dialog.dart';
import '../../desktop/primary_button.dart';
import '../../desktop/secondary_button.dart';
import 'nested_navigator_dialog_route_generator.dart';

class NestedNavigatorDialog extends StatefulWidget {
  const NestedNavigatorDialog({
    super.key,
    required this.initialRoute,
    this.initialRouteArgs,
    this.navigatorKey,
  });

  final String initialRoute;
  final Object? initialRouteArgs;
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Grabs the nearest [NestedNavigatorDialogState]. Use [maybeOf] if you're
  /// not sure one exists.
  static NestedNavigatorDialogState of(BuildContext context) {
    final NestedNavigatorDialogState? state = maybeOf(context);
    assert(state != null, "No NestedNavigatorDialog found above this context.");
    return state!;
  }

  static NestedNavigatorDialogState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_NestedNavigatorDialogScope>()
        ?.state;
  }

  @override
  State<NestedNavigatorDialog> createState() => NestedNavigatorDialogState();
}

class NestedNavigatorDialogState extends State<NestedNavigatorDialog> {
  late final _CloseOnEmptyObserver _observer;
  late final GlobalKey<NavigatorState> _navigatorKey;

  NavigatorState? _parentNavigator;

  /// Closes the whole dialog (not just the current step).
  void close() {
    if (mounted) _parentNavigator?.pop();
  }

  @override
  void initState() {
    super.initState();
    _observer = _CloseOnEmptyObserver(close);
    _navigatorKey = widget.navigatorKey ?? GlobalKey<NavigatorState>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parentNavigator = Navigator.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: _NestedNavigatorDialogScope(
        state: this,
        child: Navigator(
          key: _navigatorKey,
          observers: <NavigatorObserver>[_observer],
          onGenerateRoute: NestedNavigatorDialogRouteGenerator.generateRoute,
          onGenerateInitialRoutes: (_, _) => [
            NestedNavigatorDialogRouteGenerator.generateRoute(
              RouteSettings(
                name: widget.initialRoute,
                arguments: widget.initialRouteArgs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NestedNavigatorDialogScope extends InheritedWidget {
  const _NestedNavigatorDialogScope({
    required this.state,
    required super.child,
  });

  final NestedNavigatorDialogState state;

  @override
  bool updateShouldNotify(_NestedNavigatorDialogScope oldWidget) {
    return state != oldWidget.state;
  }
}

class _CloseOnEmptyObserver extends NavigatorObserver {
  _CloseOnEmptyObserver(this.onEmpty);

  final VoidCallback onEmpty;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == null) onEmpty();
  }
}

/// Warns before closing the whole dialog. Wire this to the X on subsequent
/// (non-root) steps so close does not silently act like back.
Future<void> confirmCloseNestedNavigatorDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => DesktopDialog(
      maxWidth: 450,
      maxHeight: 210,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Close?", style: STextStyles.desktopH3(ctx)),
            const SizedBox(height: 12),
            Text(
              "Are you sure you want to close?",
              style: STextStyles.desktopTextMedium(ctx),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: "Cancel",
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    label: "Close",
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted) return;
  if (confirmed == true) {
    NestedNavigatorDialog.of(context).close();
  }
}
