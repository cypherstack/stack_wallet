import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/rounded_container.dart';
import 'package:flutter/material.dart';

class MnemonicTableItem extends StatelessWidget {
  const MnemonicTableItem({
    Key? key,
    required this.number,
    required this.word,
    required this.isDesktop,
    this.borderColor,
  }) : super(key: key);

  final int number;
  final String word;
  final bool isDesktop;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                number.toString(),
                style: isDesktop
                    ? STextStyles.desktopTextExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textSubtitle2,
                      )
                    : STextStyles.bodySmallBold(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textMedium,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: 6,
        ),
        Expanded(
          flex: 5,
          child: RoundedContainer(
            padding: const EdgeInsets.all(6),
            color: Theme.of(context).extension<StackColors>()!.coal,
            child: Center(
              child: Text(
                word,
                style: isDesktop
                    ? STextStyles.desktopTextExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textLight,
                      )
                    : STextStyles.bodySmallBold(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
