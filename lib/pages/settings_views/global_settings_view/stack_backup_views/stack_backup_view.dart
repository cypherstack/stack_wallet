import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/auto_backup_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/create_backup_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/restore_from_file_view.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class StackBackupView extends StatelessWidget {
  const StackBackupView({
    Key? key,
  }) : super(key: key);

  static const String routeName = "/stackBackup";

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Scaffold(
      backgroundColor: Theme.of(context).extension<StackColors>()!.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Stack backup",
          style: STextStyles.navBarTitle(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RoundedWhiteContainer(
              padding: const EdgeInsets.all(0),
              child: RawMaterialButton(
                // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(AutoBackupView.routeName);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        Assets.svg.backupAuto,
                        height: 28,
                        width: 28,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Text(
                        "Auto Backup",
                        style: STextStyles.titleBold12(context),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            RoundedWhiteContainer(
              padding: const EdgeInsets.all(0),
              child: RawMaterialButton(
                // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(CreateBackupView.routeName);
                  // .pushNamed(CreateBackupInfoView.routeName);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        Assets.svg.backupAdd,
                        height: 28,
                        width: 28,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Text(
                        "Create manual backup",
                        style: STextStyles.titleBold12(context),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            RoundedWhiteContainer(
              padding: const EdgeInsets.all(0),
              child: RawMaterialButton(
                // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(RestoreFromFileView.routeName);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        Assets.svg.backupRestore,
                        height: 28,
                        width: 28,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Text(
                        "Restore backup",
                        style: STextStyles.titleBold12(context),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
