import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';

class FiatCryptoToggle extends ConsumerWidget {
  const FiatCryptoToggle({
    Key? key,
    // this.onChanged,
  }) : super(key: key);

  // final void Function(ExchangeRateType)? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("BUILD: $runtimeType");
    final isDesktop = Util.isDesktop;

    // final estimated = ref.watch(prefsChangeNotifierProvider
    //         .select((value) => value.exchangeRateType)) ==
    //     ExchangeRateType.estimated;

    // return Toggle(
    //   onValueChanged: (value) {
    //     //   if (!estimated) {
    //     //     ref.read(prefsChangeNotifierProvider).exchangeRateType =
    //     //         ExchangeRateType.estimated;
    //     //     onChanged?.call(ExchangeRateType.estimated);
    //     //   } else {
    //     //     onChanged?.call(ExchangeRateType.fixed);
    //     //   }
    //   },
    //   isOn: true,
    //   onColor: Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
    //   offColor: isDesktop
    //       ? Theme.of(context).extension<StackColors>()!.buttonBackSecondary
    //       : Theme.of(context).extension<StackColors>()!.popupBG,
    //   decoration: BoxDecoration(
    //     borderRadius: BorderRadius.circular(
    //       Constants.size.circularBorderRadius,
    //     ),
    //   ),
    //   onIcon: Assets.svg.lockOpen,
    //   onText: "Estimate rate",
    //   offIcon: Assets.svg.lock,
    //   offText: "Fixed rate",
    // );
    return BlueTextButton(
      text: "Use crypto amount",
      textSize: 14,
      onTap: () {
        // Navigator.of(context).pushNamed(
        //   ForgotPasswordDesktopView.routeName,
        // );
      },
    );
  }
}
