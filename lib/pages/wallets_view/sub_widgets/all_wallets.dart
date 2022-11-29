import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/pages/add_wallet_views/add_wallet_view/add_wallet_view.dart';
import 'package:epicmobile/pages/wallets_view/sub_widgets/wallet_list_item.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/custom_buttons/blue_text_button.dart';

class AllWallets extends StatelessWidget {
  const AllWallets({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "All wallets",
              style: STextStyles.itemSubtitle(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark,
              ),
            ),
            BlueTextButton(
              text: "Add new",
              onTap: () {
                Navigator.of(context).pushNamed(AddWalletView.routeName);
              },
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Expanded(
          child: Consumer(
            builder: (_, ref, __) {
              final providersByCoin = ref.watch(walletsChangeNotifierProvider
                  .select((value) => value.getManagerProvidersByCoin()));

              return ListView.builder(
                itemCount: providersByCoin.length,
                itemBuilder: (builderContext, index) {
                  final coin =
                      providersByCoin.keys.toList(growable: false)[index];
                  final int walletCount = providersByCoin[coin]!.length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: WalletListItem(
                      coin: coin,
                      walletCount: walletCount,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
