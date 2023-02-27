import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/coin_select_item.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/mobile_coin_list.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class SearchableCoinList extends ConsumerWidget {
  const SearchableCoinList({
    Key? key,
    required this.entities,
    required this.isDesktop,
    required this.searchTerm,
  }) : super(key: key);

  final List<AddWalletListEntity> entities;
  final bool isDesktop;
  final String searchTerm;

  List<AddWalletListEntity> filterCoins(String text, bool showTestNetCoins) {
    final _entities = [...entities];
    if (text.isNotEmpty) {
      final lowercaseTerm = text.toLowerCase();
      _entities.retainWhere(
        (e) =>
            e.ticker.toLowerCase().contains(lowercaseTerm) ||
            e.name.toLowerCase().contains(lowercaseTerm) ||
            e.coin.name.toLowerCase().contains(lowercaseTerm) ||
            (e is EthTokenEntity &&
                e.token.contractAddress.toLowerCase().contains(lowercaseTerm)),
      );
    }
    if (!showTestNetCoins) {
      _entities.removeWhere(
          (e) => e.name.endsWith("TestNet") || e == Coin.bitcoincashTestnet);
    }

    return _entities;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool showTestNet = ref.watch(
      prefsChangeNotifierProvider.select((value) => value.showTestNetCoins),
    );

    final _entities = filterCoins(searchTerm, showTestNet);

    return ListView.builder(
      itemCount: _entities.length,
      itemBuilder: (ctx, index) {
        return Padding(
          padding: const EdgeInsets.all(4),
          child: CoinSelectItem(
            entity: _entities[index],
          ),
        );
      },
    );
  }
}
