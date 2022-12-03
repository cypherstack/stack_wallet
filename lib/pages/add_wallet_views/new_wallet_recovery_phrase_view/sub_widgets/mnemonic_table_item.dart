import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
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
    return RoundedWhiteContainer(
      borderColor: borderColor,
      padding: isDesktop
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 9)
          : const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            number.toString(),
            style: isDesktop
                ? STextStyles.desktopTextExtraSmall(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textSubtitle2,
                  )
                : STextStyles.baseXS(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textSubtitle2,
                    fontSize: 10,
                  ),
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            word,
            style: isDesktop
                ? STextStyles.desktopTextExtraSmall(context).copyWith(
                    color:
                        Theme.of(context).extension<StackColors>()!.textLight,
                  )
                : STextStyles.baseXS(context),
          ),
        ],
      ),
    );
  }
}
