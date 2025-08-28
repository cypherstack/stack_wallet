import 'package:flutter/material.dart';

import '../../../../pages/settings_views/global_settings_view/security_views/auto_lock_timeout_settings_view.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../widgets/desktop/desktop_dialog.dart';
import '../../../../widgets/desktop/desktop_dialog_close_button.dart';

class DesktopAutolockTimeoutSettingsDialog extends StatelessWidget {
  const DesktopAutolockTimeoutSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxHeight: double.infinity,
      maxWidth: 480,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "Auto lock timeout",
                  style: STextStyles.desktopH3(context),
                  textAlign: TextAlign.center,
                ),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),

          const Padding(
            padding: EdgeInsets.only(left: 32, right: 32, bottom: 32, top: 20),
            child: AutoLockTimeoutSettingsView(),
          ),
        ],
      ),
    );
  }
}
