import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/token_view/token_view.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class TokenSummary extends ConsumerWidget {
  const TokenSummary({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token =
        ref.watch(tokenServiceProvider.select((value) => value!.token));
    final balance =
        ref.watch(tokenServiceProvider.select((value) => value!.balance));

    return RoundedContainer(
      color: const Color(0xFFE9EAFF), // todo: fix color
      // color: Theme.of(context).extension<StackColors>()!.,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                Assets.svg.walletDesktop,
                color: const Color(0xFF8488AB), // todo: fix color
                width: 12,
                height: 12,
              ),
              const SizedBox(
                width: 6,
              ),
              Text(
                ref.watch(
                  walletsChangeNotifierProvider.select(
                    (value) => value.getManager(walletId).walletName,
                  ),
                ),
                style: STextStyles.w500_12(context).copyWith(
                  color: const Color(0xFF8488AB), // todo: fix color
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            "${balance.getTotal()}"
            " ${token.symbol}",
            style: STextStyles.pageTitleH1(context),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            "FIXME: price",
            style: STextStyles.subtitle500(context),
          ),
          const SizedBox(
            height: 20,
          ),
          const TokenWalletOptions(),
        ],
      ),
    );
  }
}

class TokenWalletOptions extends StatelessWidget {
  const TokenWalletOptions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TokenOptionsButton(
          onPressed: () {},
          subLabel: "Receive",
          iconAssetSVG: Assets.svg.receive(context),
        ),
        const SizedBox(
          width: 16,
        ),
        TokenOptionsButton(
          onPressed: () {},
          subLabel: "Receive",
          iconAssetSVG: Assets.svg.send(context),
        ),
        const SizedBox(
          width: 16,
        ),
        TokenOptionsButton(
          onPressed: () {},
          subLabel: "Exchange",
          iconAssetSVG: Assets.svg.exchange(context),
        ),
        const SizedBox(
          width: 16,
        ),
        TokenOptionsButton(
          onPressed: () {},
          subLabel: "Buy",
          iconAssetSVG: Assets.svg.creditCard,
        ),
      ],
    );
  }
}

class TokenOptionsButton extends StatelessWidget {
  const TokenOptionsButton({
    Key? key,
    required this.onPressed,
    required this.subLabel,
    required this.iconAssetSVG,
  }) : super(key: key);

  final VoidCallback onPressed;
  final String subLabel;
  final String iconAssetSVG;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RawMaterialButton(
          fillColor: Theme.of(context).extension<StackColors>()!.popupBG,
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          constraints: const BoxConstraints(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
          ),
          onPressed: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: SvgPicture.asset(
              iconAssetSVG,
              color: const Color(0xFF424A97), // todo: fix color
              width: 24,
              height: 24,
            ),
          ),
        ),
        const SizedBox(
          height: 6,
        ),
        Text(
          subLabel,
          style: STextStyles.w500_12(context),
        )
      ],
    );
  }
}
