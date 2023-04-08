import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class AddTokenText extends StatelessWidget {
  const AddTokenText({
    Key? key,
    required this.isDesktop,
    this.walletName,
  }) : super(key: key);

  final String? walletName;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (walletName != null)
          Text(
            walletName!,
            textAlign: TextAlign.center,
            style: isDesktop
                ? STextStyles.sectionLabelMedium12(context) // todo: fixme
                : STextStyles.sectionLabelMedium12(context),
          ),
        if (walletName != null)
          const SizedBox(
            height: 4,
          ),
        Text(
          "Edit Tokens",
          textAlign: TextAlign.center,
          style: isDesktop
              ? STextStyles.desktopH2(context)
              : STextStyles.pageTitleH1(context),
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          "You can also do it later in your wallet",
          textAlign: TextAlign.center,
          style: isDesktop
              ? STextStyles.desktopSubtitleH2(context)
              : STextStyles.subtitle(context),
        ),
      ],
    );
  }
}
