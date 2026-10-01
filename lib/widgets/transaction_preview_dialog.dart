import 'dart:async';

import 'package:flutter/material.dart';

import '../services/openalias/open_alias.dart';
import '../themes/stack_colors.dart';
import '../utilities/text_styles.dart';
import 'desktop/desktop_dialog.dart';
import 'desktop/desktop_dialog_close_button.dart';
import 'desktop/secondary_button.dart';
import 'stack_dialog.dart';

// Removes only the route created by this attempt, even after cancellation or
// when another route becomes current. Never blindly pops the send view.
class TransactionPreviewDialog {
  DialogRoute<void>? _route;

  void show(
    BuildContext context,
    WidgetBuilder builder,
    VoidCallback onCancel,
  ) {
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (context) => PopScope(canPop: false, child: builder(context)),
    );
    _route = route;
    unawaited(
      navigator.push(route).then((_) {
        if (identical(_route, route)) {
          _route = null;
          onCancel();
        }
      }),
    );
  }

  void close() {
    final route = _route;
    _route = null;
    if (route != null && route.isActive) {
      route.navigator?.removeRoute(route);
    }
  }
}

void showTransactionFailedDialog(
  BuildContext context,
  Object error, {
  required bool isDesktop,
}) {
  // No transaction was built when the recipient could not be resolved.
  final title = error is OpenAliasException
      ? 'OpenAlias lookup failed'
      : 'Transaction failed';
  unawaited(
    showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (context) {
        if (!isDesktop) {
          return StackDialog(
            title: title,
            message: error.toString(),
            rightButton: TextButton(
              style: Theme.of(context)
                  .extension<StackColors>()!
                  .getSecondaryEnabledButtonStyle(context),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Ok',
                style: STextStyles.button(context).copyWith(
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .accentColorDark,
                ),
              ),
            ),
          );
        }
        return DesktopDialog(
          maxWidth: 450,
          maxHeight: double.infinity,
          child: Padding(
            padding: const EdgeInsets.only(left: 32, bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: STextStyles.desktopH3(context)),
                    const DesktopDialogCloseButton(),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 32),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.left,
                    style: STextStyles.desktopTextExtraExtraSmall(context)
                        .copyWith(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        buttonHeight: ButtonHeight.l,
                        label: 'Ok',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 32),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
