import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/coin_wallets_table.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/table_view/table_view.dart';
import 'package:stackwallet/widgets/table_view/table_view_cell.dart';
import 'package:stackwallet/widgets/table_view/table_view_row.dart';

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
              color: CFColors.background,
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
                      style: STextStyles.desktopTextExtraSmall.copyWith(
                        color: CFColors.textDark,
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
                  style: STextStyles.desktopTextExtraSmall.copyWith(
                    color: CFColors.textSubtitle1,
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

    var percentChangedColor = CFColors.stackAccent;
    if (percentChange > 0) {
      percentChangedColor = CFColors.stackGreen;
    } else if (percentChange < 0) {
      percentChangedColor = CFColors.stackRed;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$priceString $currency/${coin.ticker}",
          style: STextStyles.desktopTextExtraSmall.copyWith(
            color: CFColors.textSubtitle1,
          ),
        ),
        Text(
          "${percentChange.toStringAsFixed(2)}%",
          style: STextStyles.desktopTextExtraSmall.copyWith(
            color: percentChangedColor,
          ),
        ),
      ],
    );
  }
}
