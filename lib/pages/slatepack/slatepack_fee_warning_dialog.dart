import 'package:flutter/material.dart';

import '../../utilities/util.dart';
import '../../widgets/stack_dialog.dart';

/// Requires acknowledgement when the native wallet creates a slate with a
/// fee different from the estimate the user confirmed.
Future<void> showSlatepackFeeChangedDialog({
  required BuildContext context,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: StackOkDialog(
        title: "Fee changed",
        message: message,
        desktopPopRootNavigator: Util.isDesktop,
        maxWidth: Util.isDesktop ? 400 : null,
      ),
    ),
  );
}
