import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/add_wallet_view.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/desktop_favorite_wallets.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/wallet_summary_table.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';

class MyWallets extends ConsumerStatefulWidget {
  const MyWallets({Key? key}) : super(key: key);

  @override
  ConsumerState<MyWallets> createState() => _MyWalletsState();
}

class _MyWalletsState extends ConsumerState<MyWallets> {
  @override
  Widget build(BuildContext context) {
    final showFavorites = ref.watch(prefsChangeNotifierProvider
        .select((value) => value.showFavoriteWallets));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showFavorites) const DesktopFavoriteWallets(),
          Row(
            children: [
              Text(
                "All wallets",
                style: STextStyles.desktopTextExtraSmall(context).copyWith(
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldActiveSearchIconRight,
                ),
              ),
              const Spacer(),
              BlueTextButton(
                text: "Add new wallet",
                onTap: () {
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamed(AddWalletView.routeName);
                },
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          const Expanded(
            child: WalletSummaryTable(),
          ),
        ],
      ),
    );
  }
}
