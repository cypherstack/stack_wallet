import 'package:flutter/material.dart';

import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/dialogs/s_dialog.dart';

Future<bool> showDeleteTradeConfirmationDialog({
  required BuildContext context,
  required bool isTerminalStatus,
}) async {
  return await showDialog<bool>(
        context: context,
        useSafeArea: true,
        builder: (_) =>
            DeleteTradeConfirmationDialog(isTerminalStatus: isTerminalStatus),
      ) ??
      false;
}

class DeleteTradeConfirmationDialog extends StatelessWidget {
  const DeleteTradeConfirmationDialog({
    super.key,
    required this.isTerminalStatus,
  });

  final bool isTerminalStatus;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return SDialog(
      padding: EdgeInsets.all(isDesktop ? 32 : 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 386),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isTerminalStatus
                  ? "Delete this trade?"
                  : "Delete an active trade?",
              style: isDesktop
                  ? STextStyles.desktopH3(context)
                  : STextStyles.pageTitleH2(context),
            ),
            const SizedBox(height: 16),
            Text(
              isTerminalStatus
                  ? "This trade will be permanently deleted."
                  : "This trade is still active. Deleting it will remove it "
                        "from this device, so you will no longer be able to "
                        "track its status here.",
              style: isDesktop
                  ? STextStyles.desktopTextSmall(context)
                  : STextStyles.itemSubtitle(context),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    key: const Key("cancelDeleteTradeButton"),
                    label: "Cancel",
                    buttonHeight: ButtonHeight.l,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    key: const Key("confirmDeleteTradeButton"),
                    label: "Delete",
                    buttonHeight: ButtonHeight.l,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
