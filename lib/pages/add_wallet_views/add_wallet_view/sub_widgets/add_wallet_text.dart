import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class AddWalletText extends StatelessWidget {
  const AddWalletText({Key? key, required this.isDesktop}) : super(key: key);

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Add wallet",
          textAlign: TextAlign.center,
          style: isDesktop ? STextStyles.desktopH2 : STextStyles.pageTitleH1,
        ),
        const SizedBox(
          height: 16,
        ),
        Text(
          "Select wallet currency",
          textAlign: TextAlign.center,
          style:
              isDesktop ? STextStyles.desktopSubtitleH2 : STextStyles.subtitle,
        ),
      ],
    );
  }
}
