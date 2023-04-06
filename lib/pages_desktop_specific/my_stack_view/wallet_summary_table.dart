import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/dialogs/desktop_coin_wallets_dialog.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class WalletSummaryTable extends ConsumerStatefulWidget {
  const WalletSummaryTable({Key? key}) : super(key: key);

  @override
  ConsumerState<WalletSummaryTable> createState() => _WalletTableState();
}

class _WalletTableState extends ConsumerState<WalletSummaryTable> {
  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final providersByCoin = ref.watch(
      walletsChangeNotifierProvider.select(
        (value) => value.getManagerProvidersByCoin(),
      ),
    );

    return ListView.separated(
      itemBuilder: (_, index) {
        final providers = providersByCoin[index].item2;
        final coin = providersByCoin[index].item1;

        return ConditionalParent(
          condition: index + 1 == providersByCoin.length,
          builder: (child) => const Padding(
            padding: EdgeInsets.only(
              bottom: 16,
            ),
          ),
          child: DesktopWalletSummaryRow(
            key: Key("DesktopWalletSummaryRow_key_${coin.name}"),
            coin: coin,
            walletCount: providers.length,
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(
        height: 10,
      ),
      itemCount: providersByCoin.length,
    );
  }
}

class DesktopWalletSummaryRow extends StatefulWidget {
  const DesktopWalletSummaryRow({
    Key? key,
    required this.coin,
    required this.walletCount,
  }) : super(key: key);

  final Coin coin;
  final int walletCount;

  @override
  State<DesktopWalletSummaryRow> createState() =>
      _DesktopWalletSummaryRowState();
}

class _DesktopWalletSummaryRowState extends State<DesktopWalletSummaryRow> {
  bool _hovering = false;

  void _onPressed() {
    showDialog<void>(
      context: context,
      builder: (_) => DesktopDialog(
        maxHeight: 600,
        maxWidth: 700,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "${widget.coin.prettyName} (${widget.coin.ticker}) wallets",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                  right: 32,
                  bottom: 32,
                ),
                child: DesktopCoinWalletsDialog(
                  coin: widget.coin,
                  navigatorState: Navigator.of(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(
        () => _hovering = true,
      ),
      onExit: (_) => setState(
        () => _hovering = false,
      ),
      child: AnimatedScale(
        scale: _hovering ? 1.00 : 0.98,
        duration: const Duration(
          milliseconds: 200,
        ),
        child: RoundedWhiteContainer(
          padding: const EdgeInsets.all(20),
          hoverColor: Colors.transparent,
          onPressed: _onPressed,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    SvgPicture.asset(
                      Assets.svg.iconFor(coin: widget.coin),
                      width: 28,
                      height: 28,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      widget.coin.prettyName,
                      style:
                          STextStyles.desktopTextExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark,
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  widget.walletCount == 1
                      ? "${widget.walletCount} wallet"
                      : "${widget.walletCount} wallets",
                  style: STextStyles.desktopTextExtraSmall(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textSubtitle1,
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: TablePriceInfo(
                  coin: widget.coin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TablePriceInfo extends ConsumerWidget {
  const TablePriceInfo({Key? key, required this.coin}) : super(key: key);

  final Coin coin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuple = ref.watch(
      priceAnd24hChangeNotifierProvider.select(
        (value) => value.getPrice(coin),
      ),
    );

    final currency = ref.watch(
      prefsChangeNotifierProvider.select(
        (value) => value.currency,
      ),
    );

    final priceString = Amount.fromDecimal(
      tuple.item1,
      fractionDigits: 2,
    ).localizedStringAsFixed(
      locale: ref
          .watch(
            localeServiceChangeNotifierProvider.notifier,
          )
          .locale,
      decimalPlaces: 2,
    );

    final double percentChange = tuple.item2;

    var percentChangedColor =
        Theme.of(context).extension<StackColors>()!.textDark;
    if (percentChange > 0) {
      percentChangedColor =
          Theme.of(context).extension<StackColors>()!.accentColorGreen;
    } else if (percentChange < 0) {
      percentChangedColor =
          Theme.of(context).extension<StackColors>()!.accentColorRed;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$priceString $currency/${coin.ticker}",
          style: STextStyles.desktopTextExtraSmall(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textSubtitle1,
          ),
        ),
        Text(
          "${percentChange.toStringAsFixed(2)}%",
          style: STextStyles.desktopTextExtraSmall(context).copyWith(
            color: percentChangedColor,
          ),
        ),
      ],
    );
  }
}
