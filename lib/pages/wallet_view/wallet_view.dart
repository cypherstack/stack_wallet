import 'package:epicmobile/pages/wallet_view/sub_widgets/transactions_list.dart';
import 'package:epicmobile/pages/wallet_view/sub_widgets/wallet_summary_info.dart';
import 'package:epicmobile/pages/wallet_view/transaction_views/transaction_search_filter_view.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// [eventBus] should only be set during testing
class WalletView extends ConsumerStatefulWidget {
  const WalletView({
    Key? key,
    required this.walletId,
    this.eventBus,
  }) : super(key: key);

  static const String routeName = "/wallet";
  static const double navBarHeight = 65.0;

  final String walletId;
  final EventBus? eventBus;

  @override
  ConsumerState<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends ConsumerState<WalletView> {
  @override
  void initState() {
    ref.read(walletProvider)!.isActiveWallet = true;
    ref.read(walletProvider)!.shouldAutoSync = true;

    if (!ref.read(walletProvider)!.isRefreshing) {
      ref.read(walletProvider)!.refresh();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Container(
      color: Theme.of(context).extension<StackColors>()!.background,
      child: Column(
        children: [
          const SizedBox(
            height: 40,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: WalletSummaryInfo(
                walletId: widget.walletId,
              ),
            ),
          ),
          const SizedBox(
            height: 35,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "TRANSACTIONS",
                  style: STextStyles.overLineBold(context),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      TransactionSearchFilterView.routeName,
                      arguments: Coin.epicCash,
                    );
                  },
                  child: Container(
                    color: Colors.transparent,
                    width: 36,
                    height: 36,
                    child: Center(
                      child: SvgPicture.asset(
                        Assets.svg.filter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TransactionsList(
                walletId: widget.walletId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
