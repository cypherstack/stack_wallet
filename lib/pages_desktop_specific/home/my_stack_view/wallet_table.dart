import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class WalletTable extends ConsumerStatefulWidget {
  const WalletTable({Key? key}) : super(key: key);

  @override
  ConsumerState<WalletTable> createState() => _WalletTableState();
}

class _WalletTableState extends ConsumerState<WalletTable> {
  void tapRow(int index) {
    print("row $index clicked");
  }

  TableRow getRowForCoin(
    int index,
    Map<Coin, List<ChangeNotifierProvider<Manager>>> providersByCoin,
  ) {
    final coin = providersByCoin.keys.toList(growable: false)[index];
    final walletCount = providersByCoin[coin]!.length;

    final walletCountString =
        walletCount == 1 ? "$walletCount wallet" : "$walletCount wallets";

    return TableRow(
      children: [
        GestureDetector(
          onTap: () {
            tapRow(index);
          },
          child: Container(
            decoration: BoxDecoration(
              color: CFColors.background,
            ),
            child: Row(
              children: [
                // logo/icon
                const SizedBox(
                  width: 10,
                ),
                Text(
                  coin.prettyName,
                  style: STextStyles.desktopTextExtraSmall.copyWith(
                    color: CFColors.textDark,
                  ),
                )
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            tapRow(index);
          },
          child: Container(
            decoration: BoxDecoration(
              color: CFColors.background,
            ),
            child: Text(
              walletCountString,
              style: STextStyles.desktopTextExtraSmall.copyWith(
                color: CFColors.textSubtitle1,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            tapRow(index);
          },
          child: Container(
            decoration: BoxDecoration(
              color: CFColors.background,
            ),
            child: PriceInfoRow(coin: coin),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final providersByCoin = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManagerProvidersByCoin()));

    return Table(
        border: TableBorder.all(),
        columnWidths: const <int, TableColumnWidth>{
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1.25),
          2: FlexColumnWidth(1.75),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          for (int i = 0; i < providersByCoin.length; i++)
            getRowForCoin(i, providersByCoin)
        ]);
  }
}

class PriceInfoRow extends ConsumerWidget {
  const PriceInfoRow({Key? key, required this.coin}) : super(key: key);

  final Coin coin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuple = ref.watch(priceAnd24hChangeNotifierProvider
        .select((value) => value.getPrice(coin)));

    final currency = ref
        .watch(prefsChangeNotifierProvider.select((value) => value.currency));

    final priceString = Format.localizedStringAsFixed(
      value: tuple.item1,
      locale: ref.watch(localeServiceChangeNotifierProvider.notifier).locale,
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
