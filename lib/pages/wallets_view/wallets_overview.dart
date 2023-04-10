import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/master_wallet_card.dart';
import 'package:stackwallet/widgets/wallet_card.dart';

class WalletsOverview extends ConsumerStatefulWidget {
  const WalletsOverview({
    Key? key,
    required this.coin,
  }) : super(key: key);

  final Coin coin;

  static const routeName = "/ethWalletsOverview";

  @override
  ConsumerState<WalletsOverview> createState() => _EthWalletsOverviewState();
}

class _EthWalletsOverviewState extends ConsumerState<WalletsOverview> {
  final isDesktop = Util.isDesktop;

  final List<String> walletIds = [];

  @override
  void initState() {
    final walletsData =
        ref.read(walletsServiceChangeNotifierProvider).fetchWalletsData();
    walletsData.removeWhere((key, value) => value.coin != widget.coin);
    walletIds.clear();

    walletIds.addAll(walletsData.values.map((e) => e.walletId));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: const AppBarBackButton(),
            title: Text(
              "${widget.coin.prettyName} (${widget.coin.ticker}) wallets",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
        child: ListView.separated(
          itemCount: walletIds.length,
          separatorBuilder: (_, __) => const SizedBox(
            height: 8,
          ),
          itemBuilder: (_, index) => widget.coin == Coin.ethereum
              ? MasterWalletCard(
                  walletId: walletIds[index],
                )
              : WalletSheetCard(
                  walletId: walletIds[index],
                ),
        ),
      ),
    );
  }
}
