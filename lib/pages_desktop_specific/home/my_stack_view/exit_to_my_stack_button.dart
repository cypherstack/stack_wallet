import 'package:flutter/material.dart';
import 'package:stackwallet/pages_desktop_specific/home/desktop_home_view.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class ExitToMyStackButton extends StatelessWidget {
  const ExitToMyStackButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        right: 24,
      ),
      child: SizedBox(
        height: 56,
        child: TextButton(
          style: CFColors.getSmallSecondaryEnabledButtonColor(context),
          onPressed: () {
            Navigator.of(context).popUntil(
              ModalRoute.withName(DesktopHomeView.routeName),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
            ),
            child: Text(
              "Exit to My Stack",
              style: STextStyles.desktopButtonSmallSecondaryEnabled,
            ),
          ),
        ),
      ),
    );
  }
}
