import 'package:flutter/material.dart';

import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/primary_button.dart';

Future<T?> showOpenCryptoPayDesktopDialog<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (_) => DesktopDialog(
      maxHeight: MediaQuery.sizeOf(context).height - 64,
      maxWidth: 580,
      child: child,
    ),
  );
}

class OpenCryptoPayScaffold extends StatelessWidget {
  const OpenCryptoPayScaffold({
    super.key,
    required this.title,
    required this.isDesktop,
    required this.child,
  });

  final String title;
  final bool isDesktop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isDesktop) return OpenCryptoPayDesktopFrame(title: title, child: child);

    final colors = Theme.of(context).extension<StackColors>()!;
    return Background(
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.backgroundAppBar,
          leading: const AppBarBackButton(),
          title: Text(title, style: STextStyles.navBarTitle(context)),
        ),
        body: SafeArea(child: child),
      ),
    );
  }
}

class OpenCryptoPayDesktopFrame extends StatelessWidget {
  const OpenCryptoPayDesktopFrame({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height - 64,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(title, style: STextStyles.desktopH3(context)),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}

class OpenCryptoPayErrorView extends StatelessWidget {
  const OpenCryptoPayErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: STextStyles.itemSubtitle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: "Retry", onPressed: onRetry),
        ],
      ),
    );
  }
}
