import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/cfcolors.dart';

class DesktopScaffold extends StatelessWidget {
  const DesktopScaffold({
    Key? key,
    this.background = CFColors.background,
    this.appBar,
    this.body,
  }) : super(key: key);

  final Color background;
  final Widget? appBar;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
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
