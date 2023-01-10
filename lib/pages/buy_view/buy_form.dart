import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/buy/buy_form_state_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class BuyForm extends ConsumerStatefulWidget {
  const BuyForm({
    Key? key,
    this.walletId,
    this.coin,
  }) : super(key: key);

  final String? walletId;
  final Coin? coin;

  @override
  ConsumerState<BuyForm> createState() => _BuyFormState();
}

class _BuyFormState extends ConsumerState<BuyForm> {
  late final String? walletId;
  late final Coin? coin;

  final isDesktop = Util.isDesktop;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "You will send",
          style: STextStyles.itemSubtitle(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark3,
          ),
        ),
        SizedBox(
          height: isDesktop ? 10 : 4,
        ),
        // ExchangeTextField(
        //   controller: _sendController,
        //   focusNode: _sendFocusNode,
        //   textStyle: STextStyles.smallMed14(context).copyWith(
        //     color: Theme.of(context).extension<StackColors>()!.textDark,
        //   ),
        //   buttonColor:
        //       Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
        //   borderRadius: Constants.size.circularBorderRadius,
        //   background:
        //       Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
        //   onTap: () {
        //     if (_sendController.text == "-") {
        //       _sendController.text = "";
        //     }
        //   },
        //   onChanged: sendFieldOnChanged,
        //   onButtonTap: selectSendCurrency,
        //   isWalletCoin: isWalletCoin(coin, true),
        //   image: _fetchIconUrlFromTicker(ref.watch(
        //       buyFormStateProvider.select((value) => value.fromTicker))),
        //   ticker: ref.watch(
        //       buyFormStateProvider.select((value) => value.fromTicker)),
        // ),
        SizedBox(
          height: isDesktop ? 10 : 4,
        ),
        SizedBox(
          height: isDesktop ? 10 : 4,
        ),
        // if (ref
        //         .watch(buyFormStateProvider.select((value) => value.warning))
        //         .isNotEmpty &&
        //     !ref.watch(buyFormStateProvider.select((value) => value.reversed)))
        //   Text(
        //     ref.watch(buyFormStateProvider.select((value) => value.warning)),
        //     style: STextStyles.errorSmall(context),
        //   ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "You will receive",
              style: STextStyles.itemSubtitle(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
            ),
            ConditionalParent(
              condition: isDesktop,
              builder: (child) => MouseRegion(
                cursor: SystemMouseCursors.click,
                child: child,
              ),
              child: RoundedContainer(
                padding: isDesktop
                    ? const EdgeInsets.all(6)
                    : const EdgeInsets.all(2),
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .buttonBackSecondary,
                radiusMultiplier: 0.75,
                child: GestureDetector(
                  // onTap: () async {
                  //   await _swap();
                  // },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: SvgPicture.asset(
                      Assets.svg.swap,
                      width: 20,
                      height: 20,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorDark,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: isDesktop ? 10 : 7,
        ),
        // ExchangeTextField(
        //   focusNode: _receiveFocusNode,
        //   controller: _receiveController,
        //   textStyle: STextStyles.smallMed14(context).copyWith(
        //     color: Theme.of(context).extension<StackColors>()!.textDark,
        //   ),
        //   buttonColor:
        //       Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
        //   borderRadius: Constants.size.circularBorderRadius,
        //   background:
        //       Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
        //   onTap: () {
        //     if (!(ref.read(prefsChangeNotifierProvider).exchangeRateType ==
        //             ExchangeRateType.estimated) &&
        //         _receiveController.text == "-") {
        //       _receiveController.text = "";
        //     }
        //   },
        //   onChanged: receiveFieldOnChanged,
        //   onButtonTap: selectReceiveCurrency,
        //   isWalletCoin: isWalletCoin(coin, true),
        //   image: _fetchIconUrlFromTicker(ref.watch(
        //       buyFormStateProvider.select((value) => value.toTicker))),
        //   ticker: ref.watch(
        //       buyFormStateProvider.select((value) => value.toTicker)),
        //   readOnly: ref.watch(prefsChangeNotifierProvider
        //           .select((value) => value.exchangeRateType)) ==
        //       ExchangeRateType.estimated,
        //   // ||
        //   // ref.watch(exchangeProvider).name ==
        //   //     SimpleSwapExchange.exchangeName,
        // ),
        // if (ref
        //         .watch(buyFormStateProvider.select((value) => value.warning))
        //         .isNotEmpty &&
        //     ref.watch(buyFormStateProvider.select((value) => value.reversed)))
        //   Text(
        //     ref.watch(buyFormStateProvider.select((value) => value.warning)),
        //     style: STextStyles.errorSmall(context),
        //   ),
        SizedBox(
          height: isDesktop ? 20 : 12,
        ),
        // SizedBox(
        //   height: 60,
        //   child: RateTypeToggle(
        //     onChanged: onRateTypeChanged,
        //   ),
        // ),
        // these reads should be watch
        if (ref.watch(buyFormStateProvider).fromAmount != null &&
            ref.watch(buyFormStateProvider).fromAmount != Decimal.zero)
          SizedBox(
            height: isDesktop ? 20 : 12,
          ),
        // these reads should be watch
        // if (ref.watch(buyFormStateProvider).fromAmount != null &&
        //     ref.watch(buyFormStateProvider).fromAmount != Decimal.zero)
        //   ExchangeProviderOptions(
        //     from: ref.watch(buyFormStateProvider).fromTicker,
        //     to: ref.watch(buyFormStateProvider).toTicker,
        //     fromAmount: ref.watch(buyFormStateProvider).fromAmount,
        //     toAmount: ref.watch(buyFormStateProvider).toAmount,
        //     fixedRate: ref.watch(prefsChangeNotifierProvider
        //             .select((value) => value.exchangeRateType)) ==
        //         ExchangeRateType.fixed,
        //     reversed: ref
        //         .watch(buyFormStateProvider.select((value) => value.reversed)),
        //   ),
        SizedBox(
          height: isDesktop ? 20 : 12,
        ),
        // PrimaryButton(
        //   buttonHeight: isDesktop ? ButtonHeight.l : null,
        //   enabled: ref
        //       .watch(buyFormStateProvider.select((value) => value.canExchange)),
        //   // onPressed: ref.watch(buyFormStateProvider
        //   //         .select((value) => value.canExchange))
        //   //     ? onExchangePressed
        //   //     : null,
        //   label: "Exchange",
        // )
      ],
    );
  }
}
