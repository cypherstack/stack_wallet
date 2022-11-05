import 'package:flutter/material.dart';
import 'package:stackwallet/pages_desktop_specific/home/desktop_home_view.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';

class DesktopLoginView extends StatefulWidget {
  const DesktopLoginView({
    Key? key,
    this.startupWalletId,
  }) : super(key: key);

  static const String routeName = "/desktopLogin";

  final String? startupWalletId;

  @override
  State<DesktopLoginView> createState() => _DesktopLoginViewState();
}

class _DesktopLoginViewState extends State<DesktopLoginView> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Login",
            style: STextStyles.desktopH3(context),
          ),
          PrimaryButton(
            label: "Login",
            onPressed: () {
              // todo auth

              Navigator.of(context).pushNamedAndRemoveUntil(
                DesktopHomeView.routeName,
                (route) => false,
              );
            },
          )
        ],
      ),
    );
  }
}
