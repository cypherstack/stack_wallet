import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackduo/providers/providers.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/utilities/util.dart';

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

    final isDesktop = Util.isDesktop;

    return Container(
      decoration: BoxDecoration(
        // color: selectedCoin == coin ? CFColors.selection : CFColors.white,
        color: selectedCoin == coin
            ? Theme.of(context).extension<StackColors>()!.textFieldActiveBG
            : Theme.of(context).extension<StackColors>()!.popupBG,
        borderRadius:
            BorderRadius.circular(Constants.size.circularBorderRadius),
      ),
      child: MaterialButton(
        // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
        key: Key("coinSelectItemButtonKey_${coin.name}"),
        padding: isDesktop
            ? const EdgeInsets.only(left: 24)
            : const EdgeInsets.all(12),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(Constants.size.circularBorderRadius),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: isDesktop ? 70 : 0,
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                Assets.svg.iconFor(coin: coin),
                width: 26,
                height: 26,
              ),
              SizedBox(
                width: isDesktop ? 12 : 10,
              ),
              Text(
                coin.prettyName,
                style: isDesktop
                    ? STextStyles.desktopTextMedium(context)
                    : STextStyles.subtitle600(context).copyWith(
                        fontSize: 14,
                      ),
              ),
              if (isDesktop && selectedCoin == coin) const Spacer(),
              if (isDesktop && selectedCoin == coin)
                Padding(
                  padding: const EdgeInsets.only(
                    right: 18,
                  ),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: SvgPicture.asset(
                      Assets.svg.check,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorDark,
                    ),
                  ),
                ),
            ],
          ),
        ),
        onPressed: () =>
            ref.read(addWalletSelectedCoinStateProvider.state).state = coin,
      ),
    );
  }
}
