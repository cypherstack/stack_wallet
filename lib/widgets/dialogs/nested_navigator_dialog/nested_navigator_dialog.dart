import 'package:flutter/material.dart';

import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../desktop/primary_button.dart';
import '../../desktop/secondary_button.dart';
import '../s_dialog.dart';
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

  Future<void> close({
    NestedNavigatorDialogCloseArgs args = const .genericWarning(),
  }) async {
    if (!mounted) return;

    final bool proceed = switch (args) {
      _NoWarning() => true,
      _GenericWarning() => await _showGenericWarning(),
      _CustomWarning(:final shouldClose) => await shouldClose(),
    };

    if (proceed && mounted) _parentNavigator?.pop();
  }

  Future<bool> _showGenericWarning() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) {
        assert(Util.isDesktop, "");

        return SDialog(
          padding: const .all(32),
          child: SizedBox(
            width: 500,
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                Text("Discard changes?", style: STextStyles.desktopH3(context)),
                const SizedBox(height: 16),
                Text(
                  "Are you sure you want to close?",
                  style: STextStyles.desktopTextSmall(context),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: "Cancel",
                        buttonHeight: ButtonHeight.l,
                        onPressed: () => Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pop(false),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: PrimaryButton(
                        label: "Discard",
                        buttonHeight: ButtonHeight.l,
                        onPressed: () => Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return confirmed ?? false;
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

sealed class NestedNavigatorDialogCloseArgs {
  const NestedNavigatorDialogCloseArgs();

  const factory NestedNavigatorDialogCloseArgs.noWarning() = _NoWarning;
  const factory NestedNavigatorDialogCloseArgs.genericWarning() =
      _GenericWarning;
  const factory NestedNavigatorDialogCloseArgs.customWarning(
    Future<bool> Function() shouldClose,
  ) = _CustomWarning;
}

class _NoWarning extends NestedNavigatorDialogCloseArgs {
  const _NoWarning();
}

class _GenericWarning extends NestedNavigatorDialogCloseArgs {
  const _GenericWarning();
}

class _CustomWarning extends NestedNavigatorDialogCloseArgs {
  const _CustomWarning(this.shouldClose);
  final Future<bool> Function() shouldClose;
}
