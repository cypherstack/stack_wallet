import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/wallet_refresh_button.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_balance_toggle_button.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/wallet/wallet_balance_toggle_state_provider.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/wallet_balance_toggle_state.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class DesktopWalletSummary extends ConsumerStatefulWidget {
  const DesktopWalletSummary({
    Key? key,
    required this.walletId,
    required this.initialSyncStatus,
  }) : super(key: key);

  final String walletId;
  final WalletSyncStatus initialSyncStatus;

  @override
  ConsumerState<DesktopWalletSummary> createState() =>
      _WDesktopWalletSummaryState();
}

class _WDesktopWalletSummaryState extends ConsumerState<DesktopWalletSummary> {
  late final String walletId;

  @override
  void initState() {
    walletId = widget.walletId;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final externalCalls = ref.watch(
      prefsChangeNotifierProvider.select(
        (value) => value.externalCalls,
      ),
    );
    final coin = ref.watch(
      walletsChangeNotifierProvider.select(
        (value) => value.getManager(widget.walletId).coin,
      ),
    );
    final locale = ref.watch(
        localeServiceChangeNotifierProvider.select((value) => value.locale));

    final baseCurrency = ref
        .watch(prefsChangeNotifierProvider.select((value) => value.currency));

    final priceTuple = ref.watch(priceAnd24hChangeNotifierProvider
        .select((value) => value.getPrice(coin)));

    final _showAvailable =
        ref.watch(walletBalanceToggleStateProvider.state).state ==
            WalletBalanceToggleState.available;

    Balance balance = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(walletId).balance));

    Decimal balanceToShow;
    if (_showAvailable) {
      balanceToShow = balance.getSpendable();
    } else {
      balanceToShow = balance.getTotal();
    }

    return Consumer(
      builder: (context, ref, __) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
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
                    style: STextStyles.desktopTextExtraSmall(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textSubtitle1,
                    ),
                  ),
              ],
            ),
            const SizedBox(
              width: 8,
            ),
            WalletRefreshButton(
              walletId: walletId,
              initialSyncStatus: widget.initialSyncStatus,
            ),
            const SizedBox(
              width: 8,
            ),
            const DesktopBalanceToggleButton(),
          ],
        );
      },
    );
  }
}
