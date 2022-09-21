import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';

class WordTableItem extends ConsumerWidget {
  const WordTableItem({
    Key? key,
    required this.number,
    required this.word,
    required this.isDesktop,
  }) : super(key: key);

  final int number;
  final String word;
  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("BUILD: $runtimeType");
    final selectedWord =
        ref.watch(verifyMnemonicSelectedWordStateProvider.state).state;
    return Container(
      decoration: BoxDecoration(
        color: selectedWord == word
            ? StackTheme.instance.color.snackBarBackInfo
            : StackTheme.instance.color.popupBG,
        borderRadius: BorderRadius.circular(
          Constants.size.circularBorderRadius,
        ),
      ),
      child: MaterialButton(
        splashColor: StackTheme.instance.color.highlight,
        key: Key("coinSelectItemButtonKey_$word"),
        padding: isDesktop
            ? const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 12,
              )
            : const EdgeInsets.all(12),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(Constants.size.circularBorderRadius),
        ),
        onPressed: () {
          ref.read(verifyMnemonicSelectedWordStateProvider.state).state = word;
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word,
              textAlign: TextAlign.center,
              style: isDesktop
                  ? STextStyles.desktopTextExtraSmall.copyWith(
                      color: StackTheme.instance.color.textDark,
                    )
                  : STextStyles.baseXS,
            ),
          ],
        ),
      ),
    );
  }
}
