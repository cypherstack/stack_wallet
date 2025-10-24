import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import '../../../../providers/db/main_db_provider.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/assets.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../wallets/isar/models/frost_wallet_info.dart';
import '../../../../widgets/background.dart';
import '../../../../widgets/conditional_parent.dart';
import '../../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../../widgets/desktop/desktop_app_bar.dart';
import '../../../../widgets/desktop/desktop_scaffold.dart';
import '../../../../widgets/rounded_white_container.dart';
import '../../../wallet_view/transaction_views/tx_v2/transaction_v2_details_view.dart'
    as tdv;

class FrostParticipantsView extends ConsumerWidget {
  const FrostParticipantsView({super.key, required this.walletId});

  static const String routeName = "/frostParticipantsView";

  final String walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: optimize this by creating watcher providers (similar to normal WalletInfo)
    final frostInfo =
        ref
            .read(mainDBProvider)
            .isar
            .frostWalletInfo
            .getByWalletIdSync(walletId)!;

    return ConditionalParent(
      condition: Util.isDesktop,
      builder:
          (child) => DesktopScaffold(
            background: Theme.of(context).extension<StackColors>()!.background,
            appBar: const DesktopAppBar(
              isCompactHeight: false,
              leading: AppBarBackButton(),
              trailing: ExitToMyStackButton(),
            ),
            body: SizedBox(width: 480, child: child),
          ),
      child: ConditionalParent(
        condition: !Util.isDesktop,
        builder:
            (child) => Background(
              child: Scaffold(
                backgroundColor:
                    Theme.of(context).extension<StackColors>()!.background,
                appBar: AppBar(
                  leading: AppBarBackButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  title: Text(
                    "Participants",
                    style: STextStyles.navBarTitle(context),
                  ),
                ),
                body: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: child,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        child: Column(
          crossAxisAlignment:
              Util.isDesktop
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < frostInfo.participants.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: RoundedWhiteContainer(
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).extension<StackColors>()!.textFieldActiveBG,
                          borderRadius: BorderRadius.circular(200),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            Assets.svg.user,
                            width: 16,
                            height: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          frostInfo.participants[i] == frostInfo.myName
                              ? "${frostInfo.participants[i]} (me)"
                              : frostInfo.participants[i],
                          style: STextStyles.w500_14(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      tdv.IconCopyButton(data: frostInfo.participants[i]),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
