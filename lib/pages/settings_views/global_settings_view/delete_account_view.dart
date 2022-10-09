import 'package:flutter/material.dart';
import 'package:stackwallet/pages/intro_view.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class DeleteAccountView extends StatefulWidget {
  const DeleteAccountView({Key? key}) : super(key: key);

  static const String routeName = "/deleteAccountView";

  @override
  State<DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<DeleteAccountView> {
  final isDesktop = Util.isDesktop;

  Future<void> onConfirmDeleteAccount() async {
    // TODO delete everything then pop to intro view
    await Navigator.of(context).pushNamedAndRemoveUntil(
      IntroView.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterScaffold(
      isDesktop: isDesktop,
      appBar: isDesktop
          ? DesktopAppBar(isCompactHeight: true)
          : AppBar(
              leading: AppBarBackButton(
                onPressed: () async {
                  if (FocusScope.of(context).hasFocus) {
                    FocusScope.of(context).unfocus();
                    await Future<void>.delayed(
                        const Duration(milliseconds: 75));
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              title: Text(
                "Delete account",
                style: STextStyles.navBarTitle(context),
              ),
            ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            RoundedWhiteContainer(
              child: Text(
                "There is no account to delete, but Apple requires that we have a way to 'delete accounts' in the app and will reject our app updates if we don't, so here it is. Clicking this will delete all app data (not from our servers, because we never had it in the first place).\n\nWhen you click confirm, all app data will be deleted, including wallets and preferences, and you will be taken back to the very first onboarding screen. BE SURE TO BACKUP ALL SEEDS!!\n\nAre you sure you want to delete your \"account\"?",
                style: STextStyles.smallMed12(context),
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: "Confirm",
              onPressed: onConfirmDeleteAccount,
            )
          ],
        ),
      ),
    );
  }
}
