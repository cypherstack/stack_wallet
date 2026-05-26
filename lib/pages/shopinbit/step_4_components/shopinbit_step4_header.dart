import "package:flutter/material.dart";

import "../../../utilities/text_styles.dart";
import "../../../utilities/util.dart";
import "../../exchange_view/sub_widgets/step_row.dart";

class ShopInBitStep4Header extends StatelessWidget {
  const ShopInBitStep4Header({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!Util.isDesktop) ...[
          StepRow(
            count: 4,
            current: 3,
            width: MediaQuery.of(context).size.width - 32,
          ),
          const SizedBox(height: 14),
        ],
        Text(
          title,
          style: Util.isDesktop
              ? STextStyles.desktopH2(context)
              : STextStyles.pageTitleH1(context),
        ),
        SizedBox(height: Util.isDesktop ? 16 : 8),
        Text(
          subtitle,
          style: Util.isDesktop
              ? STextStyles.desktopTextSmall(context)
              : STextStyles.itemSubtitle(context),
        ),
      ],
    );
  }
}
