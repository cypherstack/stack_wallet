import 'package:flutter/material.dart';

import '../../notifications/show_flush_bar.dart';
import '../../pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_auth_send.dart';
import '../../route_generator.dart';
import '../../utilities/util.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../pinpad_views/lock_screen_view.dart';

/// The same unlock step the confirm screen uses before a send: passphrase
/// on desktop, PIN or biometrics on mobile. Returns true when unlocked.
Future<bool> authenticateSlatepackSpend(
  BuildContext context, {
  required CryptoCurrency coin,
  String reason = "Authenticate to send transaction",
}) async {
  final bool? unlocked;
  if (Util.isDesktop) {
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<bool?>(
      context: context,
      builder: (context) => DesktopDialog(
        maxWidth: 580,
        maxHeight: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [DesktopDialogCloseButton()],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32),
              child: DesktopAuthSend(coin: coin),
            ),
          ],
        ),
      ),
    );
    unlocked = await navigator.push<bool?>(route);
    // Navigator.push completes when pop starts. Native Mimblewimble calls can
    // block the UI isolate, so do not start one while the authentication
    // dialog is still animating away.
    await route.completed;
  } else {
    final navigator = Navigator.of(context);
    final route = RouteGenerator.getRoute<bool>(
      shouldUseMaterialRoute: RouteGenerator.useMaterialPageRoute,
      builder: (_) => LockscreenView(
        showBackButton: true,
        popOnSuccess: true,
        routeOnSuccessArguments: true,
        routeOnSuccess: "",
        biometricsCancelButtonString: "CANCEL",
        biometricsLocalizedReason: reason,
        biometricsAuthenticationTitle: "Confirm Transaction",
      ),
      settings: const RouteSettings(name: "/confirmsendlockscreen"),
    );
    unlocked = await navigator.push<bool>(route);
    if (route case final TransitionRoute<bool> transitionRoute) {
      await transitionRoute.completed;
    }
  }

  if (unlocked == true) return true;
  // A closed dialog is not a failed attempt.
  if (unlocked == false && context.mounted) {
    await showFloatingFlushBar(
      type: FlushBarType.warning,
      message: Util.isDesktop ? "Invalid passphrase" : "Invalid PIN",
      context: context,
    );
  }
  return false;
}
