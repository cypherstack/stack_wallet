import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/animated_text.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:tuple/tuple.dart';

class WalletSheetCard extends ConsumerWidget {
  const WalletSheetCard({
    Key? key,
    required this.walletId,
    this.popPrevious = false,
  }) : super(key: key);

  final String walletId;
  final bool popPrevious;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(ref
        .watch(walletsChangeNotifierProvider.notifier)
        .getManagerProvider(walletId));

    final locale = ref.watch(
        localeServiceChangeNotifierProvider.select((value) => value.locale));

    final coin = manager.coin;

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: MaterialButton(
        // splashColor: CFColors.splashLight,
        key: Key("walletsSheetItemButtonKey_$walletId"),
        padding: const EdgeInsets.all(5),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        onPressed: () {
          if (popPrevious) Navigator.of(context).pop();
          Navigator.of(context).pushNamed(
            WalletView.routeName,
            arguments: Tuple2(
                walletId,
                ref
                    .read(walletsChangeNotifierProvider)
                    .getManagerProvider(walletId)),
          );
        },
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: CFColors.coin.forCoin(manager.coin).withOpacity(0.5),
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset(
                  Assets.svg.iconFor(coin: coin),
                  width: 20,
                  height: 20,
                ),
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manager.walletName,
                    style: STextStyles.titleBold12,
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  FutureBuilder(
                    future: manager.totalBalance,
                    builder: (builderContext, AsyncSnapshot<Decimal> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        return Text(
                          "${Format.localizedStringAsFixed(
                            value: snapshot.data!,
                            locale: locale,
                            decimalPlaces: 8,
                          )} ${coin.ticker}",
                          style: STextStyles.itemSubtitle,
                        );
                      } else {
                        return AnimatedText(
                          stringsToLoopThrough: const [
                            "Loading balance",
                            "Loading balance.",
                            "Loading balance..",
                            "Loading balance..."
                          ],
                          style: STextStyles.itemSubtitle,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
