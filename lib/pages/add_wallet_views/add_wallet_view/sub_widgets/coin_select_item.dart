import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class CoinSelectItem extends ConsumerWidget {
  const CoinSelectItem({
    Key? key,
    required this.coin,
  }) : super(key: key);

  final Coin coin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("BUILD: CoinSelectItem for ${coin.name}");
    final selectedCoin = ref.watch(addWalletSelectedCoinStateProvider);
    return Container(
      decoration: BoxDecoration(
        // color: selectedCoin == coin ? CFColors.selection : CFColors.white,
        color: selectedCoin == coin ? CFColors.selected2 : CFColors.white,
        borderRadius:
            BorderRadius.circular(Constants.size.circularBorderRadius),
      ),
      child: MaterialButton(
        // splashColor: CFColors.splashLight,
        key: Key("coinSelectItemButtonKey_${coin.name}"),
        padding: const EdgeInsets.all(12),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(Constants.size.circularBorderRadius),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              Assets.svg.iconFor(coin: coin),
              width: 26,
              height: 26,
            ),
            const SizedBox(
              width: 10,
            ),
            Text(
              coin.prettyName,
              style: STextStyles.subtitle.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        onPressed: () =>
            ref.read(addWalletSelectedCoinStateProvider.state).state = coin,
      ),
    );
  }
}
