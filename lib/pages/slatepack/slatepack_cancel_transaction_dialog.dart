import 'package:flutter/material.dart';

import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/stack_dialog.dart';

bool canCancelSlateTransaction({
  required String? slateId,
  required bool isCancelled,
  required int confirmations,
}) => slateId?.isNotEmpty == true && !isCancelled && confirmations < 1;

class SlatepackCancelTransactionDialog extends StatelessWidget {
  const SlatepackCancelTransactionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return StackDialogBase(
      width: Util.isDesktop ? 400 : null,
      padding: EdgeInsets.all(Util.isDesktop ? 24 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Cancel this transaction?",
            style: Util.isDesktop
                ? STextStyles.desktopH3(context)
                : STextStyles.pageTitleH2(context),
          ),
          const SizedBox(height: 12),
          Text(
            "This cancels the transaction in this wallet. It may not prevent "
            "another party from completing or broadcasting it.",
            style: STextStyles.smallMed14(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textDark3,
            ),
          ),
          const SizedBox(height: 20),
          SecondaryButton(
            label: "Go back",
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: "Cancel it",
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}
