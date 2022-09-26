import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class DesktopScaffold extends StatelessWidget {
  const DesktopScaffold({
    Key? key,
    this.background,
    this.appBar,
    this.body,
  }) : super(key: key);

  final Color? background;
  final Widget? appBar;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          background ?? Theme.of(context).extension<StackColors>()!.background,
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (appBar != null) appBar!,
          if (body != null)
            Expanded(
              child: body!,
            ),
        ],
      ),
    );
  }
}

class MasterScaffold extends StatelessWidget {
  const MasterScaffold({
    Key? key,
    required this.isDesktop,
    required this.appBar,
    required this.body,
    this.background,
  }) : super(key: key);

  final bool isDesktop;
  final Widget appBar;
  final Widget body;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return DesktopScaffold(
        background: background ??
            Theme.of(context).extension<StackColors>()!.background,
        appBar: appBar,
        body: body,
      );
    } else {
      return Scaffold(
        backgroundColor: background ??
            Theme.of(context).extension<StackColors>()!.background,
        appBar: appBar as PreferredSizeWidget?,
        body: body,
      );
    }
  }
}
