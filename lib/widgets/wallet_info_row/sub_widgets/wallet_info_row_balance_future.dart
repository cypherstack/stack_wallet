import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/animated_text.dart';

class WalletInfoRowBalanceFuture extends ConsumerWidget {
  const WalletInfoRowBalanceFuture({Key? key, required this.walletId})
      : super(key: key);

  final String walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(ref
        .watch(walletsChangeNotifierProvider.notifier)
        .getManagerProvider(walletId));

    final locale = ref.watch(
      localeServiceChangeNotifierProvider.select(
        (value) => value.locale,
      ),
    );

    return FutureBuilder(
      future: manager.totalBalance,
      builder: (builderContext, AsyncSnapshot<Decimal> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return Text(
            "${Format.localizedStringAsFixed(
              value: snapshot.data!,
              locale: locale,
              decimalPlaces: 8,
            )} ${manager.coin.ticker}",
            style: Util.isDesktop
                ? STextStyles.desktopTextExtraSmall.copyWith(
                    color: CFColors.textSubtitle1,
                  )
                : STextStyles.itemSubtitle,
          );
        } else {
          return AnimatedText(
            stringsToLoopThrough: const [
              "Loading balance",
              "Loading balance.",
              "Loading balance..",
              "Loading balance..."
            ],
            style: Util.isDesktop
                ? STextStyles.desktopTextExtraSmall.copyWith(
                    color: CFColors.textSubtitle1,
                  )
                : STextStyles.itemSubtitle,
          );
        }
      },
    );
  }
}
