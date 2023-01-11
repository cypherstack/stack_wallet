import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/textfields/buy_textfield.dart';

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

  late final TextEditingController _fiatController;
  late final TextEditingController _cryptoController;
  final isDesktop = Util.isDesktop;
  final FocusNode _fiatFocusNode = FocusNode();
  final FocusNode _cryptoFocusNode = FocusNode();

  void fiatFieldOnChanged(String value) async {
    if (_fiatFocusNode.hasFocus) {
      final newFromAmount = Decimal.tryParse(value);

      await ref.read(buyFormStateProvider).setFromAmountAndCalculateToAmount(
          newFromAmount ?? Decimal.zero, true);

      if (newFromAmount == null) {
        // _cryptoController.text =
        //     ref.read(prefsChangeNotifierProvider).exchangeRateType ==
        //             ExchangeRateType.estimated
        //         ? "-"
        //         : "";
      }
    }
  }

  void selectFiatCurrency() async {
    // await Future<void>.delayed(const Duration(milliseconds: 300));
    //
    // Navigator.of(context, rootNavigator: true).pop();
  }
  @override
  void initState() {
    _fiatController = TextEditingController();
    _cryptoController = TextEditingController();

    walletId = widget.walletId;
    coin = widget.coin;
    // walletInitiated = walletId != null && coin != null;
    //
    // if (walletInitiated) {
    //   WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //     ref.read(buyFormStateProvider).clearAmounts(true);
    //     // ref.read(fixedRateExchangeFormProvider);
    //   });
    // } else {
    // final isEstimated =
    //     ref.read(prefsChangeNotifierProvider).exchangeRateType ==
    //         ExchangeRateType.estimated;
    _fiatController.text = ref.read(buyFormStateProvider).fromAmountString;
    _cryptoController
            .text = /*isEstimated
          ? "-" //ref.read(estimatedRateExchangeFormProvider).toAmountString
          :*/
        ref.read(buyFormStateProvider).toAmountString;
    // }

    super.initState();
  }

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
          "I want to buy",
          style: STextStyles.itemSubtitle(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark3,
          ),
        ),
        SizedBox(
          height: isDesktop ? 10 : 4,
        ),
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
              "I want to pay with",
              style: STextStyles.itemSubtitle(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
            ),
          ],
        ),
        // SizedBox(
        //   height: isDesktop ? 10 : 7,
        // ),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Enter amount",
              style: STextStyles.itemSubtitle(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
            ),
          ],
        ),
        // // these reads should be watch
        // if (ref.watch(buyFormStateProvider).fromAmount != null &&
        //     ref.watch(buyFormStateProvider).fromAmount != Decimal.zero)
        SizedBox(
          height: isDesktop ? 20 : 12,
        ),
        BuyTextField(
          controller: _fiatController,
          focusNode: _fiatFocusNode,
          textStyle: STextStyles.smallMed14(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark,
          ),
          buttonColor:
              Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
          borderRadius: Constants.size.circularBorderRadius,
          background:
              Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
          onTap: () {
            if (_fiatController.text == "-") {
              _fiatController.text = "";
            }
          },
          onChanged: fiatFieldOnChanged,
          onButtonTap: selectFiatCurrency,
          // isWalletCoin: isWalletCoin(coin, true),
          isWalletCoin: false,
          // image: _fetchIconUrlFromTicker(ref
          //     .watch(buyFormStateProvider.select((value) => value.fromTicker))),
          // ticker: ref
          //     .watch(buyFormStateProvider.select((value) => value.fromTicker)),
        ),
        SizedBox(
          height: isDesktop ? 20 : 12,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Enter receiving address",
              style: STextStyles.itemSubtitle(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
