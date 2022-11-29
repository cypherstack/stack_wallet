import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:epicmobile/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/rounded_container.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';

class RateTypeToggle extends ConsumerWidget {
  const RateTypeToggle({
    Key? key,
    this.onChanged,
  }) : super(key: key);

  final void Function(ExchangeRateType)? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("BUILD: $runtimeType");
    final estimated = ref.watch(prefsChangeNotifierProvider
            .select((value) => value.exchangeRateType)) ==
        ExchangeRateType.estimated;

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!estimated) {
                  ref.read(prefsChangeNotifierProvider).exchangeRateType =
                      ExchangeRateType.estimated;
                  onChanged?.call(ExchangeRateType.estimated);
                }
              },
              child: RoundedContainer(
                color: estimated
                    ? Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldDefaultBG
                    : Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      Assets.svg.lock,
                      width: 12,
                      height: 14,
                      color: estimated
                          ? Theme.of(context).extension<StackColors>()!.textDark
                          : Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle1,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      "Estimate rate",
                      style: STextStyles.smallMed12(context).copyWith(
                        color: estimated
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .textDark
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .textSubtitle1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (estimated) {
                  ref.read(prefsChangeNotifierProvider).exchangeRateType =
                      ExchangeRateType.fixed;
                  onChanged?.call(ExchangeRateType.fixed);
                }
              },
              child: RoundedContainer(
                color: !estimated
                    ? Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldDefaultBG
                    : Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      Assets.svg.lock,
                      width: 12,
                      height: 14,
                      color: !estimated
                          ? Theme.of(context).extension<StackColors>()!.textDark
                          : Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle1,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      "Fixed rate",
                      style: STextStyles.smallMed12(context).copyWith(
                        color: !estimated
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .textDark
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .textSubtitle1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
