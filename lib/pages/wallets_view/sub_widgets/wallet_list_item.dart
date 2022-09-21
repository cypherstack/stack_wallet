import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/wallets_sheet/wallets_sheet.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class WalletListItem extends ConsumerWidget {
  const WalletListItem({
    Key? key,
    required this.coin,
    required this.walletCount,
  }) : super(key: key);

  final Coin coin;
  final int walletCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("BUILD: $runtimeType");
    final walletCountString =
        walletCount == 1 ? "$walletCount wallet" : "$walletCount wallets";
    final currency = ref
        .watch(prefsChangeNotifierProvider.select((value) => value.currency));

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: MaterialButton(
        // splashColor: StackTheme.instance.color.highlight,
        key: Key("walletListItemButtonKey_${coin.name}"),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(Constants.size.circularBorderRadius),
        ),
        onPressed: () {
          showModalBottomSheet<dynamic>(
            backgroundColor: Colors.transparent,
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            builder: (_) => WalletsSheet(coin: coin),
          );
        },
        child: Row(
          children: [
            SvgPicture.asset(
              Assets.svg.iconFor(coin: coin),
              width: 28,
              height: 28,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Consumer(
                builder: (_, ref, __) {
                  final tuple = ref.watch(priceAnd24hChangeNotifierProvider
                      .select((value) => value.getPrice(coin)));

                  final priceString = Format.localizedStringAsFixed(
                    value: tuple.item1,
                    locale: ref
                        .watch(localeServiceChangeNotifierProvider.notifier)
                        .locale,
                    decimalPlaces: 2,
                  );

                  final double percentChange = tuple.item2;

                  var percentChangedColor = StackTheme.instance.color.textDark;
                  if (percentChange > 0) {
                    percentChangedColor =
                        StackTheme.instance.color.accentColorGreen;
                  } else if (percentChange < 0) {
                    percentChangedColor =
                        StackTheme.instance.color.accentColorRed;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(coin.prettyName),
                          const Spacer(),
                          Text(
                            "$priceString $currency/${coin.ticker}",
                            style: STextStyles.itemSubtitle,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 1,
                      ),
                      Row(
                        children: [
                          Text(
                            walletCountString,
                            style: STextStyles.itemSubtitle,
                          ),
                          const Spacer(),
                          Text(
                            "${percentChange.toStringAsFixed(2)}%",
                            style: STextStyles.itemSubtitle.copyWith(
                              color: percentChangedColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
