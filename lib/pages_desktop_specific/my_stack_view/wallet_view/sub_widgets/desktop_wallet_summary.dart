import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/wallet_refresh_button.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_balance_toggle_button.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/wallet/wallet_balance_toggle_state_provider.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/wallet_balance_toggle_state.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/animated_text.dart';

class DesktopWalletSummary extends StatefulWidget {
  const DesktopWalletSummary({
    Key? key,
    required this.walletId,
    required this.managerProvider,
    required this.initialSyncStatus,
  }) : super(key: key);

  final String walletId;
  final ChangeNotifierProvider<Manager> managerProvider;
  final WalletSyncStatus initialSyncStatus;

  @override
  State<DesktopWalletSummary> createState() => _WDesktopWalletSummaryState();
}

class _WDesktopWalletSummaryState extends State<DesktopWalletSummary> {
  late final String walletId;
  late final ChangeNotifierProvider<Manager> managerProvider;

  Decimal? _balanceTotalCached;
  Decimal? _balanceCached;

  @override
  void initState() {
    walletId = widget.walletId;
    managerProvider = widget.managerProvider;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Consumer(
      builder: (context, ref, __) {
        final Coin coin =
            ref.watch(managerProvider.select((value) => value.coin));
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Consumer(
                  builder: (_, ref, __) {
                    final externalCalls = ref.watch(prefsChangeNotifierProvider
                        .select((value) => value.externalCalls));

                    Future<Decimal>? totalBalanceFuture;
                    Future<Decimal>? availableBalanceFuture;
                    if (coin == Coin.firo || coin == Coin.firoTestNet) {
                      final firoWallet = ref.watch(
                              managerProvider.select((value) => value.wallet))
                          as FiroWallet;
                      totalBalanceFuture = firoWallet.availablePublicBalance();
                      availableBalanceFuture =
                          firoWallet.availablePrivateBalance();
                    } else {
                      totalBalanceFuture = ref.watch(managerProvider
                          .select((value) => value.totalBalance));

                      availableBalanceFuture = ref.watch(managerProvider
                          .select((value) => value.availableBalance));
                    }

                    final locale = ref.watch(localeServiceChangeNotifierProvider
                        .select((value) => value.locale));

                    final baseCurrency = ref.watch(prefsChangeNotifierProvider
                        .select((value) => value.currency));

                    final priceTuple = ref.watch(
                        priceAnd24hChangeNotifierProvider
                            .select((value) => value.getPrice(coin)));

                    final _showAvailable = ref
                            .watch(walletBalanceToggleStateProvider.state)
                            .state ==
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
                        Decimal? balanceToShow = _showAvailable
                            ? _balanceCached
                            : _balanceTotalCached;

                        if (balanceToShow != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "${Format.localizedStringAsFixed(
                                    value: balanceToShow,
                                    locale: locale,
                                    decimalPlaces: 8,
                                  )} ${coin.ticker}",
                                  style: STextStyles.desktopH3(context),
                                ),
                              ),
                              if (externalCalls)
                                Text(
                                  "${Format.localizedStringAsFixed(
                                    value: priceTuple.item1 * balanceToShow,
                                    locale: locale,
                                    decimalPlaces: 2,
                                  )} $baseCurrency",
                                  style:
                                      STextStyles.desktopTextExtraSmall(context)
                                          .copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textSubtitle1,
                                  ),
                                ),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedText(
                                stringsToLoopThrough: const [
                                  "Loading balance   ",
                                  "Loading balance.  ",
                                  "Loading balance.. ",
                                  "Loading balance..."
                                ],
                                style: STextStyles.desktopH3(context).copyWith(
                                  fontSize: 24,
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textDark,
                                ),
                              ),
                              if (externalCalls)
                                AnimatedText(
                                  stringsToLoopThrough: const [
                                    "Loading balance   ",
                                    "Loading balance.  ",
                                    "Loading balance.. ",
                                    "Loading balance..."
                                  ],
                                  style:
                                      STextStyles.desktopTextExtraSmall(context)
                                          .copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textSubtitle1,
                                  ),
                                ),
                            ],
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
            if (coin == Coin.firo || coin == Coin.firoTestNet)
              const SizedBox(
                width: 8,
              ),
            if (coin == Coin.firo || coin == Coin.firoTestNet)
              const DesktopBalanceToggleButton(),
            const SizedBox(
              width: 8,
            ),
            WalletRefreshButton(
              walletId: walletId,
              initialSyncStatus: widget.initialSyncStatus,
            )
          ],
        );
      },
    );
  }
}
