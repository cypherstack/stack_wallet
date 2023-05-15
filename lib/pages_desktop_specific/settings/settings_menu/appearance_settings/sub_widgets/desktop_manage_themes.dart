import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/appearance_settings/sub_widgets/desktop_install_theme.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/appearance_settings/sub_widgets/desktop_themes_gallery.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/toggle.dart';

class DesktopManageThemesDialog extends ConsumerStatefulWidget {
  const DesktopManageThemesDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<DesktopManageThemesDialog> createState() =>
      _DesktopManageThemesDialogState();
}

class _DesktopManageThemesDialogState
    extends ConsumerState<DesktopManageThemesDialog> {
  static const width = 580.0;
  bool _isInstallFromFile = false;

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxWidth: width,
      maxHeight: 708,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  "Add more themes",
                  style: STextStyles.desktopH3(context),
                ),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              height: 56,
              child: Toggle(
                isOn: _isInstallFromFile,
                onValueChanged: (value) {
                  if (value != _isInstallFromFile) {
                    setState(() {
                      _isInstallFromFile = value;
                    });
                  }
                },
                onColor: Theme.of(context)
                    .extension<StackColors>()!
                    .rateTypeToggleDesktopColorOn,
                offColor: Theme.of(context)
                    .extension<StackColors>()!
                    .rateTypeToggleDesktopColorOff,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                onText: "Theme gallery",
                offText: "Install file",
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedCrossFade(
                  crossFadeState: _isInstallFromFile
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(
                    milliseconds: 300,
                  ),
                  firstChild: SizedBox(
                    height: constraints.maxHeight,
                    child: const DesktopThemeGallery(
                      dialogWidth: width,
                    ),
                  ),
                  secondChild: SizedBox(
                    height: constraints.maxHeight,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: DesktopInstallTheme(),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(
            height: 32,
          ),
        ],
      ),
    );
  }
}
