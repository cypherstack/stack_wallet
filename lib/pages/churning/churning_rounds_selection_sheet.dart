import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../themes/stack_colors.dart';
import '../../utilities/constants.dart';
import '../../utilities/extensions/extensions.dart';
import '../../utilities/text_styles.dart';

enum ChurnOption {
  continuous,
  custom;
}

class ChurnRoundCountSelectSheet extends HookWidget {
  const ChurnRoundCountSelectSheet({
    super.key,
    required this.currentOption,
  });

  final ChurnOption currentOption;

  @override
  Widget build(BuildContext context) {
    final option = useState(currentOption);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(option.value);
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).extension<StackColors>()!.popupBG,
          borderRadius: const BorderRadius.vertical(
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
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldDefaultBG,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Rounds of churn",
                    style: STextStyles.pageTitleH2(context),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  for (int i = 0; i < ChurnOption.values.length; i++)
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            option.value = ChurnOption.values[i];
                            Navigator.of(context).pop(option.value);
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Column(
                                //   mainAxisAlignment: MainAxisAlignment.start,
                                //   children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Radio(
                                    activeColor: Theme.of(context)
                                        .extension<StackColors>()!
                                        .radioButtonIconEnabled,
                                    value: ChurnOption.values[i],
                                    groupValue: option.value,
                                    onChanged: (_) {
                                      option.value = ChurnOption.values[i];
                                      Navigator.of(context).pop(option.value);
                                    },
                                  ),
                                ),
                                //   ],
                                // ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ChurnOption.values[i].name.capitalize(),
                                      style: STextStyles.titleBold12(context),
                                      textAlign: TextAlign.left,
                                    ),
                                    const SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      ChurnOption.values[i] ==
                                              ChurnOption.continuous
                                          ? "Keep churning until manually stopped"
                                          : "Stop after a set number of churns",
                                      style: STextStyles.itemSubtitle12(context)
                                          .copyWith(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .textDark3,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                      ],
                    ),
                  const SizedBox(
                    height: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
