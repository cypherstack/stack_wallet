import 'package:flutter/material.dart';

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

  @override
  State<NestedNavigatorDialog> createState() => _NestedNavigatorDialogState();
}

class _NestedNavigatorDialogState extends State<NestedNavigatorDialog> {
  late final _CloseOnEmptyObserver _observer;
  late final GlobalKey<NavigatorState> _navigatorKey;

  NavigatorState? _parentNavigator;

  void _close() {
    if (mounted) _parentNavigator?.pop();
  }

  @override
  void initState() {
    super.initState();
    _observer = _CloseOnEmptyObserver(_close);
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
    );
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
