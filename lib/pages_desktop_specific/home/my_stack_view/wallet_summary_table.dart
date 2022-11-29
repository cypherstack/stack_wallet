import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:epicmobile/pages_desktop_specific/home/my_stack_view/coin_wallets_table.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/format.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/table_view/table_view.dart';
import 'package:epicmobile/widgets/table_view/table_view_cell.dart';
import 'package:epicmobile/widgets/table_view/table_view_row.dart';

class WalletSummaryTable extends ConsumerStatefulWidget {
  const WalletSummaryTable({Key? key}) : super(key: key);

  @override
  ConsumerState<WalletSummaryTable> createState() => _WalletTableState();
}

class _WalletTableState extends ConsumerState<WalletSummaryTable> {
  @override
  Widget build(BuildContext context) {
    final providersByCoin = ref
        .watch(
          walletsChangeNotifierProvider.select(
            (value) => value.getManagerProvidersByCoin(),
          ),
        )
        .entries
        .toList(growable: false);

    return TableView(
      rows: [
        for (int i = 0; i < providersByCoin.length; i++)
          TableViewRow(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).extension<StackColors>()!.popupBG,
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
            ),
            cells: [
              TableViewCell(
                flex: 4,
                child: Row(
                  children: [
                    SvgPicture.asset(
                      Assets.svg.iconFor(coin: providersByCoin[i].key),
                      width: 28,
                      height: 28,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      providersByCoin[i].key.prettyName,
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
              TableViewCell(
                flex: 4,
                child: Text(
                  providersByCoin[i].value.length == 1
                      ? "${providersByCoin[i].value.length} wallet"
                      : "${providersByCoin[i].value.length} wallets",
                  style: STextStyles.desktopTextExtraSmall(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textSubtitle1,
                  ),
                ),
              ),
              TableViewCell(
                flex: 6,
                child: TablePriceInfo(
                  coin: providersByCoin[i].key,
                ),
              ),
            ],
            expandingChild: CoinWalletsTable(
              walletIds: ref.watch(
                walletsChangeNotifierProvider.select(
                  (value) => value.getWalletIdsFor(
                    coin: providersByCoin[i].key,
                  ),
                ),
              ),
            ),
          )
      ],
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

    final priceString = Format.localizedStringAsFixed(
      value: tuple.item1,
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
