import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/coin_select_item.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/next_button.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';

class AddWalletView extends StatelessWidget {
  const AddWalletView({Key? key}) : super(key: key);

  static const routeName = "/addWallet";

  @override
  Widget build(BuildContext context) {
    List<Coin> coins = [...Coin.values];
    coins.remove(Coin.firoTestNet);
    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        color: CFColors.almostWhite,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Add wallet",
                textAlign: TextAlign.center,
                style: STextStyles.pageTitleH1,
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                "Select wallet currency",
                textAlign: TextAlign.center,
                style: STextStyles.subtitle,
              ),
              const SizedBox(
                height: 16,
              ),
              Expanded(
                child: Consumer(
                  builder: (_, ref, __) {
                    bool showTestNet = ref.watch(
                      prefsChangeNotifierProvider
                          .select((value) => value.showTestNetCoins),
                    );

                    return ListView.builder(
                      itemCount: showTestNet
                          ? coins.length
                          : coins.length - (kTestNetCoinCount),
                      itemBuilder: (ctx, index) {
                        return Padding(
                          padding: const EdgeInsets.all(4),
                          child: CoinSelectItem(
                            coin: coins[index],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              const AddWalletNextButton(),
            ],
          ),
        ),
      ),
    );
  }
}
