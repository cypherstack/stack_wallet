import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class MnemonicTableItem extends StatelessWidget {
  const MnemonicTableItem({
    Key? key,
    required this.number,
    required this.word,
    required this.isDesktop,
  }) : super(key: key);

  final int number;
  final String word;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return RoundedWhiteContainer(
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
                    color: StackTheme.instance.color.textSubtitle2,
                  )
                : STextStyles.baseXS(context).copyWith(
                    color: StackTheme.instance.color.textSubtitle2,
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
                    color: StackTheme.instance.color.textDark,
                  )
                : STextStyles.baseXS(context),
          ),
        ],
      ),
    );
  }
}
