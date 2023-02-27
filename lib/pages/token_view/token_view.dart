import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/token_view/sub_widgets/token_summary.dart';
import 'package:stackwallet/pages/token_view/sub_widgets/token_transaction_list_widget.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/all_transactions_view.dart';
import 'package:stackwallet/services/ethereum/ethereum_token_service.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';

final tokenServiceStateProvider =
    StateProvider<EthereumTokenService?>((ref) => null);
final tokenServiceProvider = ChangeNotifierProvider<EthereumTokenService?>(
    (ref) => ref.watch(tokenServiceStateProvider));

/// [eventBus] should only be set during testing
class TokenView extends ConsumerStatefulWidget {
  const TokenView({
    Key? key,
    required this.walletId,
    this.eventBus,
  }) : super(key: key);

  static const String routeName = "/token";
  static const double navBarHeight = 65.0;

  final String walletId;
  final EventBus? eventBus;

  @override
  ConsumerState<TokenView> createState() => _TokenViewState();
}

class _TokenViewState extends ConsumerState<TokenView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              SvgPicture.asset(
                Assets.svg.iconFor(coin: Coin.ethereum),
                width: 24,
                height: 24,
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: Text(
                  ref.watch(tokenServiceProvider
                      .select((value) => value!.token.name)),
                  style: STextStyles.navBarTitle(context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  ref.watch(tokenServiceProvider
                      .select((value) => value!.token.symbol)),
                  style: STextStyles.navBarTitle(context),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
        ),
        body: Container(
          color: Theme.of(context).extension<StackColors>()!.background,
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TokenSummary(
                  walletId: widget.walletId,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Transactions",
                      style: STextStyles.itemSubtitle(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark3,
                      ),
                    ),
                    CustomTextButton(
                      text: "See all",
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AllTransactionsView.routeName,
                          arguments: widget.walletId,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                      bottom: Radius.circular(
                        // TokenView.navBarHeight / 2.0,
                        Constants.size.circularBorderRadius,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          Constants.size.circularBorderRadius,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: TokenTransactionsList(
                              tokenService: ref.watch(tokenServiceProvider
                                  .select((value) => value!)),
                              walletId: widget.walletId,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
