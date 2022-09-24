import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class CreateRestoreWalletSubTitle extends StatelessWidget {
  const CreateRestoreWalletSubTitle({
    Key? key,
    required this.isDesktop,
  }) : super(key: key);

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Text(
      "Create a new wallet or restore an existing wallet from seed.",
      textAlign: TextAlign.center,
      style: isDesktop
          ? STextStyles.desktopSubtitleH2(context)
          : STextStyles.subtitle(context),
    );
  }
}
