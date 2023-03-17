import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';

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

    Decimal balance = manager.balance.getTotal();

    return Text(
      "${Format.localizedStringAsFixed(
        value: balance,
        locale: locale,
        decimalPlaces: Constants.decimalPlacesForCoin(manager.coin),
      )} ${manager.coin.ticker}",
      style: Util.isDesktop
          ? STextStyles.desktopTextExtraSmall(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textSubtitle1,
            )
          : STextStyles.itemSubtitle(context),
    );
  }
}
