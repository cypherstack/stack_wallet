import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/coin_select_item.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class MobileCoinList extends StatelessWidget {
  const MobileCoinList({
    Key? key,
    required this.coins,
  }) : super(key: key);

  final List<Coin> coins;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, __) {
        bool showTestNet = ref.watch(
          prefsChangeNotifierProvider.select((value) => value.showTestNetCoins),
        );

        return ListView.builder(
          itemCount:
              showTestNet ? coins.length : coins.length - (kTestNetCoinCount),
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
    );
  }
}
