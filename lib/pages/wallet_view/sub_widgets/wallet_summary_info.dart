import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackduo/pages/wallet_view/sub_widgets/wallet_balance_toggle_sheet.dart';
import 'package:stackduo/pages/wallet_view/sub_widgets/wallet_refresh_button.dart';
import 'package:stackduo/providers/providers.dart';
import 'package:stackduo/providers/wallet/wallet_balance_toggle_state_provider.dart';
import 'package:stackduo/services/event_bus/events/global/balance_refreshed_event.dart';
import 'package:stackduo/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackduo/services/event_bus/global_event_bus.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';
import 'package:stackduo/utilities/enums/wallet_balance_toggle_state.dart';
import 'package:stackduo/utilities/format.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';

class WalletSummaryInfo extends ConsumerStatefulWidget {
  const WalletSummaryInfo({
    Key? key,
    required this.walletId,
    required this.initialSyncStatus,
  }) : super(key: key);

  final String walletId;
  final WalletSyncStatus initialSyncStatus;

  @override
  ConsumerState<WalletSummaryInfo> createState() => _WalletSummaryInfoState();
}

class _WalletSummaryInfoState extends ConsumerState<WalletSummaryInfo> {
  late StreamSubscription<BalanceRefreshedEvent> _balanceUpdated;

  void showSheet() {
    showModalBottomSheet<dynamic>(
      backgroundColor: Colors.transparent,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) => WalletBalanceToggleSheet(walletId: widget.walletId),
    );
  }

  @override
  void initState() {
    _balanceUpdated =
        GlobalEventBus.instance.on<BalanceRefreshedEvent>().listen(
      (event) async {
        if (event.walletId == widget.walletId) {
          setState(() {});
        }
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _balanceUpdated.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final externalCalls = ref.watch(
        prefsChangeNotifierProvider.select((value) => value.externalCalls));
    final coin = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId).coin));
    final balance = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId).balance));

    final locale = ref.watch(
        localeServiceChangeNotifierProvider.select((value) => value.locale));

    final baseCurrency = ref
        .watch(prefsChangeNotifierProvider.select((value) => value.currency));

    final priceTuple = ref.watch(priceAnd24hChangeNotifierProvider
        .select((value) => value.getPrice(coin)));

    final _showAvailable =
        ref.watch(walletBalanceToggleStateProvider.state).state ==
            WalletBalanceToggleState.available;

    final balanceToShow =
        _showAvailable ? balance.getSpendable() : balance.getTotal();
    final title = _showAvailable ? "Available balance" : "Full balance";

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: showSheet,
                child: Row(
                  children: [
                    Text(
                      title,
                      style: STextStyles.subtitle500(context).copyWith(
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
                child: SelectableText(
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
              if (externalCalls)
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
          ),
        ),
        Column(
          children: [
            SvgPicture.asset(
              Assets.svg.iconFor(
                coin: coin,
              ),
              width: 24,
              height: 24,
            ),
            const Spacer(),
            WalletRefreshButton(
              walletId: widget.walletId,
              initialSyncStatus: widget.initialSyncStatus,
            ),
          ],
        )
      ],
    );
  }
}
