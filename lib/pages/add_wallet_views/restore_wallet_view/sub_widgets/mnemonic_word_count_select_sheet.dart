import 'package:epicmobile/providers/ui/verify_recovery_phrase/mnemonic_word_count_state_provider.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MnemonicWordCountSelectSheet extends ConsumerWidget {
  const MnemonicWordCountSelectSheet({
    Key? key,
    required this.lengthOptions,
  }) : super(key: key);

  final List<int> lengthOptions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WillPopScope(
      onWillPop: () async {
        final length = ref.read(mnemonicWordCountStateProvider.state).state;
        Navigator.of(context).pop(length);
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
              // Expanded(
              //   child: SingleChildScrollView(
              //     child:
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Phrase length",
                    style: STextStyles.pageTitleH2(context),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  for (int i = 0; i < lengthOptions.length; i++)
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            final state = ref
                                .read(mnemonicWordCountStateProvider.state)
                                .state;
                            if (state != lengthOptions[i]) {
                              ref
                                  .read(mnemonicWordCountStateProvider.state)
                                  .state = lengthOptions[i];
                            }

                            Navigator.of(context).pop();
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                    value: lengthOptions[i],
                                    groupValue: ref
                                        .watch(mnemonicWordCountStateProvider
                                            .state)
                                        .state,
                                    onChanged: (x) {
                                      ref
                                          .read(mnemonicWordCountStateProvider
                                              .state)
                                          .state = lengthOptions[i];
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                                //   ],
                                // ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Text(
                                  "${lengthOptions[i]} words",
                                  style: STextStyles.bodyBold(context),
                                  textAlign: TextAlign.left,
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
                    height: 8,
                  ),
                ],
              ),
              // ),
              // )
            ],
          ),
        ),
      ),
    );
  }
}
