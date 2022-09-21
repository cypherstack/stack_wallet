import 'package:flutter/material.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/create_backup_view.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class CreateBackupInfoView extends StatelessWidget {
  const CreateBackupInfoView({Key? key}) : super(key: key);

  static const String routeName = "/createBackupInfo";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StackTheme.instance.color.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            if (FocusScope.of(context).hasFocus) {
              FocusScope.of(context).unfocus();
              await Future<void>.delayed(const Duration(milliseconds: 75));
            }
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Create backup",
          style: STextStyles.navBarTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          "Info",
                          style: STextStyles.pageTitleH2,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      RoundedWhiteContainer(
                        child: Text(
                          // TODO: need info
                          "{lorem ipsum}",
                          style: STextStyles.baseXS,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const Spacer(),
                      TextButton(
                        style: Theme.of(context)
                            .textButtonTheme
                            .style
                            ?.copyWith(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  StackTheme.instance.color.accentColorDark),
                            ),
                        onPressed: () {
                          Navigator.of(context)
                              .pushNamed(CreateBackupView.routeName);
                        },
                        child: Text(
                          "Next",
                          style: STextStyles.button,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
