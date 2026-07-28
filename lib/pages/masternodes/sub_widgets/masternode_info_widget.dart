import 'package:flutter/material.dart';

import '../../../themes/stack_colors.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/wallet/impl/firo_wallet.dart';
import '../../../widgets/conditional_parent.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/detail_item.dart';
import '../../../widgets/rounded_white_container.dart';

class MasternodeInfoWidget extends StatelessWidget {
  const MasternodeInfoWidget({super.key, required this.info});

  final MasternodeInfo info;

  @override
  Widget build(BuildContext context) {
    final map = info.pretty();
    final keys = map.keys.toList(growable: false);

    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) => Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .min,
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  "Masternode details",
                  style: STextStyles.desktopH3(context),
                ),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 32, right: 32),
              child: RoundedWhiteContainer(
                padding: .zero,
                borderColor: Theme.of(
                  context,
                ).extension<StackColors>()!.backgroundAppBar,
                child: child,
              ),
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          for (int i = 0; i < keys.length; i++)
            Builder(
              builder: (context) {
                final title = keys[i];
                final detail = map[title]!;

                return Column(
                  mainAxisSize: .min,
                  children: [
                    if (i > 0) const DetailDivider(),
                    DetailItem(
                      title: title,
                      detail: detail,
                      horizontal: detail.length < 22,
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
