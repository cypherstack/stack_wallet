import 'package:flutter/material.dart';

import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/stack_dialog.dart';

/// Shows a slatepack screen as a dialog: a [DesktopDialog] on desktop, a
/// bottom sheet style [StackDialogBase] on mobile.
Future<T?> showSlatepackPopup<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    // StackDialogBase and DesktopDialog already apply their own safe-area
    // layout.
    useSafeArea: false,
    builder: (context) {
      final mediaInset = MediaQuery.viewInsetsOf(context).bottom;
      // Dialog routes can expose a MediaQuery with consumed insets. Read the
      // owning view as well so the mobile popup still follows the IME.
      final viewInset = MediaQueryData.fromView(View.of(context))
          .viewInsets
          .bottom;
      final keyboardInset = mediaInset > viewInset ? mediaInset : viewInset;
      final popup = Util.isDesktop
          ? DesktopDialog(maxWidth: 700, maxHeight: null, child: child)
          : StackDialogBase(keyboardPaddingAmount: keyboardInset, child: child);
      return barrierDismissible ? popup : PopScope(canPop: false, child: popup);
    },
  );
}

/// Title and body for a slatepack popup. On desktop the title row carries a
/// close button and the body scrolls.
class SlatepackPopupLayout extends StatelessWidget {
  const SlatepackPopupLayout({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(title, style: STextStyles.desktopH3(context)),
                ),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32),
                child: child,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: STextStyles.pageTitleH2(context)),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
