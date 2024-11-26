import 'package:flutter/material.dart';

import '../services/node_service.dart';
import '../wallets/crypto_currency/crypto_currency.dart';
import '../widgets/conditional_parent.dart';
import '../widgets/desktop/desktop_dialog.dart';
import '../widgets/desktop/primary_button.dart';
import '../widgets/desktop/secondary_button.dart';
import '../widgets/stack_dialog.dart';
import 'prefs.dart';
import 'text_styles.dart';
import 'util.dart';

Future<bool> checkShowNodeTorSettingsMismatch({
  required BuildContext context,
  required CryptoCurrency currency,
  required Prefs prefs,
  required NodeService nodeService,
  required bool allowCancel,
  bool rootNavigator = false,
}) async {
  final node =
      nodeService.getPrimaryNodeFor(currency: currency) ?? currency.defaultNode;
  if (prefs.useTor) {
    if (node.torEnabled) {
      return true;
    }
  } else {
    if (node.clearnetEnabled) {
      return true;
    }
  }

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) => DesktopDialog(
        maxHeight: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: child,
        ),
      ),
      child: ConditionalParent(
        condition: !Util.isDesktop,
        builder: (child) => StackDialogBase(
          child: child,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Attention! Node connection issue detected. "
              "The current node will not sync due to its connectivity settings. "
              "Please adjust the node settings or enable/disable TOR.",
              style: STextStyles.w600_16(context),
            ),
            SizedBox(
              height: Util.isDesktop ? 32 : 24,
            ),
            Row(
              children: [
                allowCancel
                    ? Expanded(
                        child: SecondaryButton(
                          buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
                          label: "Cancel",
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        ),
                      )
                    : const Spacer(),
                SizedBox(
                  width: Util.isDesktop ? 24 : 16,
                ),
                Expanded(
                  child: PrimaryButton(
                    buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
                    label: "Continue",
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  return result ?? true;
}
