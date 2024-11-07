import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/churning/churning_service_provider.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/stack_dialog.dart';

class ChurnErrorDialog extends ConsumerWidget {
  const ChurnErrorDialog({
    super.key,
    required this.error,
    required this.walletId,
  });

  final String error;
  final String walletId;

  static const errorTitle = "An error occurred";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) => DesktopDialog(
        maxHeight: double.infinity,
        child: child,
      ),
      child: ConditionalParent(
        condition: !Util.isDesktop,
        builder: (child) => StackDialogBase(
          child: child,
        ),
        child: Column(
          children: [
            Util.isDesktop
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 32),
                        child: Text(
                          errorTitle,
                          style: STextStyles.desktopH2(context),
                        ),
                      ),
                    ],
                  )
                : Text(
                    errorTitle,
                    style: STextStyles.pageTitleH2(context),
                  ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: Util.isDesktop
                  ? const EdgeInsets.all(32)
                  : const EdgeInsets.all(20),
              child: Row(
                children: [
                  Flexible(
                    child: SelectableText(
                      error.startsWith("Exception:")
                          ? error.substring(10).trim()
                          : error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: Util.isDesktop
                  ? const EdgeInsets.all(32)
                  : const EdgeInsets.all(20),
              child: Text(
                "Stop churning or try and continue?",
                style: Util.isDesktop
                    ? STextStyles.w600_14(context)
                    : STextStyles.w600_14(context),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: Util.isDesktop ? 32 : 20,
                bottom: Util.isDesktop ? 32 : 20,
                right: Util.isDesktop ? 32 : 20,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: "Stop",
                      onPressed: () {
                        ref.read(pChurningService(walletId)).stopChurning();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  SizedBox(
                    width: Util.isDesktop ? 20 : 16,
                  ),
                  Expanded(
                    child: PrimaryButton(
                      label: "Continue",
                      onPressed: () {
                        ref.read(pChurningService(walletId)).unpause();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
