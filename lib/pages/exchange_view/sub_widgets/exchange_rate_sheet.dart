import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';

enum ExchangeRateType { estimated, fixed }

class ExchangeRateSheet extends ConsumerWidget {
  const ExchangeRateSheet({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: CFColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 10,
          bottom: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: CFColors.fieldGray,
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                width: 60,
                height: 4,
              ),
            ),
            const SizedBox(
              height: 36,
            ),
            Text(
              "Exchange rate",
              style: STextStyles.pageTitleH2,
              textAlign: TextAlign.left,
            ),
            const SizedBox(
              height: 16,
            ),
            GestureDetector(
              onTap: () {
                final state =
                    ref.read(prefsChangeNotifierProvider).exchangeRateType;
                if (state != ExchangeRateType.estimated) {
                  ref.read(prefsChangeNotifierProvider).exchangeRateType =
                      ExchangeRateType.estimated;
                }
                Navigator.of(context).pop(ExchangeRateType.estimated);
              },
              child: Container(
                color: Colors.transparent,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Radio(
                            activeColor: CFColors.link2,
                            value: ExchangeRateType.estimated,
                            groupValue: ref.watch(prefsChangeNotifierProvider
                                .select((value) => value.exchangeRateType)),
                            onChanged: (x) {
                              debugPrint(x.toString());
                              ref
                                      .read(prefsChangeNotifierProvider)
                                      .exchangeRateType =
                                  ExchangeRateType.estimated;
                              Navigator.of(context)
                                  .pop(ExchangeRateType.estimated);
                            },
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Estimated rate",
                            style: STextStyles.titleBold12.copyWith(
                              color: const Color(0xFF44464E),
                            ),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            "ChangeNOW will pick the best rate for you during the moment of the exchange.",
                            style: STextStyles.itemSubtitle,
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            GestureDetector(
              onTap: () {
                final state =
                    ref.read(prefsChangeNotifierProvider).exchangeRateType;
                if (state != ExchangeRateType.fixed) {
                  ref.read(prefsChangeNotifierProvider).exchangeRateType =
                      ExchangeRateType.fixed;
                }
                Navigator.of(context).pop(ExchangeRateType.fixed);
              },
              child: Container(
                color: Colors.transparent,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Radio(
                            activeColor: CFColors.link2,
                            value: ExchangeRateType.fixed,
                            groupValue: ref.watch(prefsChangeNotifierProvider
                                .select((value) => value.exchangeRateType)),
                            onChanged: (x) {
                              ref
                                  .read(prefsChangeNotifierProvider)
                                  .exchangeRateType = ExchangeRateType.fixed;
                              Navigator.of(context).pop(ExchangeRateType.fixed);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Fixed rate",
                            style: STextStyles.titleBold12.copyWith(
                              color: const Color(0xFF44464E),
                            ),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            "You will get the exact exchange amount displayed - ChangeNOW takes all the rate risks.",
                            style: STextStyles.itemSubtitle,
                            textAlign: TextAlign.left,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}
