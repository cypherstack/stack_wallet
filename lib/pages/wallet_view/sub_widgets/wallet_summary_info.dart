import 'package:decimal/decimal.dart';
import 'package:epicmobile/pages/wallet_view/sub_widgets/wallet_balance_toggle_sheet.dart';
import 'package:epicmobile/pages/wallet_view/sub_widgets/wallet_refresh_button.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/providers/wallet/wallet_balance_toggle_state_provider.dart';
import 'package:epicmobile/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/enums/wallet_balance_toggle_state.dart';
import 'package:epicmobile/utilities/format.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/animated_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletSummaryInfo extends StatefulWidget {
  const WalletSummaryInfo({
    Key? key,
    required this.walletId,
    required this.initialSyncStatus,
  }) : super(key: key);

  final String walletId;
  final WalletSyncStatus initialSyncStatus;

  @override
  State<WalletSummaryInfo> createState() => _WalletSummaryInfoState();
}

class _WalletSummaryInfoState extends State<WalletSummaryInfo> {
  late final String walletId;

  void showSheet() {
    showModalBottomSheet<dynamic>(
      backgroundColor: Colors.transparent,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) => WalletBalanceToggleSheet(walletId: walletId),
    );
  }

  Decimal? _balanceTotalCached;
  Decimal? _balanceCached;

  @override
  void initState() {
    walletId = widget.walletId;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Row(
      children: [
        Expanded(
          child: Consumer(
            builder: (_, ref, __) {
              final Coin coin =
                  ref.watch(walletProvider.select((value) => value!.coin));

              Future<Decimal>? totalBalanceFuture;
              Future<Decimal>? availableBalanceFuture;
              totalBalanceFuture = ref
                  .watch(walletProvider.select((value) => value!.totalBalance));

              availableBalanceFuture = ref.watch(
                  walletProvider.select((value) => value!.availableBalance));

              final locale = ref.watch(localeServiceChangeNotifierProvider
                  .select((value) => value.locale));

              final baseCurrency = ref.watch(prefsChangeNotifierProvider
                  .select((value) => value.currency));

              final priceTuple = ref.watch(priceAnd24hChangeNotifierProvider
                  .select((value) => value.getPrice(coin)));

              final _showAvailable =
                  ref.watch(walletBalanceToggleStateProvider.state).state ==
                      WalletBalanceToggleState.available;

              return FutureBuilder(
                future: _showAvailable
                    ? availableBalanceFuture
                    : totalBalanceFuture,
                builder: (fbContext, AsyncSnapshot<Decimal> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData &&
                      snapshot.data != null) {
                    if (_showAvailable) {
                      _balanceCached = snapshot.data!;
                    } else {
                      _balanceTotalCached = snapshot.data!;
                    }
                  }
                  Decimal? balanceToShow =
                      _showAvailable ? _balanceCached : _balanceTotalCached;

                  if (balanceToShow != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: showSheet,
                          child: Row(
                            children: [
                              Text(
                                "${_showAvailable ? "Available" : "Full"} Balance",
                                style:
                                    STextStyles.subtitle500(context).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textFavoriteCard,
                                ),
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              SvgPicture.asset(
                                Assets.svg.chevronDown,
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textFavoriteCard,
                                width: 8,
                                height: 4,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "${Format.localizedStringAsFixed(
                              value: balanceToShow,
                              locale: locale,
                              decimalPlaces: 8,
                            )} ${coin.ticker}",
                            style: STextStyles.pageTitleH1(context).copyWith(
                              fontSize: 24,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textFavoriteCard,
                            ),
                          ),
                        ),
                        Text(
                          "${Format.localizedStringAsFixed(
                            value: priceTuple.item1 * balanceToShow,
                            locale: locale,
                            decimalPlaces: 2,
                          )} $baseCurrency",
                          style: STextStyles.subtitle500(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textFavoriteCard,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: showSheet,
                          child: Row(
                            children: [
                              Text(
                                "${_showAvailable ? "Available" : "Full"} Balance",
                                style:
                                    STextStyles.subtitle500(context).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textFavoriteCard,
                                ),
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              SvgPicture.asset(
                                Assets.svg.chevronDown,
                                width: 8,
                                height: 4,
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textFavoriteCard,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        AnimatedText(
                          stringsToLoopThrough: const [
                            "Loading balance",
                            "Loading balance.",
                            "Loading balance..",
                            "Loading balance..."
                          ],
                          style: STextStyles.pageTitleH1(context).copyWith(
                            fontSize: 24,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textFavoriteCard,
                          ),
                        ),
                        AnimatedText(
                          stringsToLoopThrough: const [
                            "Loading balance",
                            "Loading balance.",
                            "Loading balance..",
                            "Loading balance..."
                          ],
                          style: STextStyles.subtitle500(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textFavoriteCard,
                          ),
                        ),
                      ],
                    );
                  }
                },
              );
            },
          ),
        ),
        Column(
          children: [
            Consumer(
              builder: (_, ref, __) {
                return SvgPicture.asset(
                  Assets.svg.iconFor(
                    coin: ref.watch(
                      walletProvider.select((value) => value!.coin),
                    ),
                  ),
                  width: 24,
                  height: 24,
                );
              },
            ),
            const Spacer(),
            WalletRefreshButton(
              walletId: walletId,
              initialSyncStatus: widget.initialSyncStatus,
            ),
          ],
        )
      ],
    );
  }
}
