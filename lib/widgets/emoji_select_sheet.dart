import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

class EmojiSelectSheet extends ConsumerWidget {
  const EmojiSelectSheet({
    Key? key,
  }) : super(key: key);

  final double horizontalPadding = 24;
  final double emojiSize = 24;
  final double minimumEmojiSpacing = 25;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Util.isDesktop;

    final size = isDesktop ? const Size(600, 700) : MediaQuery.of(context).size;
    final double maxHeight = size.height * 0.60;
    final double availableWidth = size.width - (2 * horizontalPadding);
    final int emojisPerRow =
        ((availableWidth - emojiSize) ~/ (emojiSize + minimumEmojiSpacing)) + 1;

    final itemCount = Emoji.all().length;

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).extension<StackColors>()!.popupBG,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: LimitedBox(
          maxHeight: maxHeight,
          child: Padding(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              top: 10,
              bottom: 0,
            ),
            child: child,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isDesktop)
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
          if (!isDesktop)
            const SizedBox(
              height: 36,
            ),
          Text(
            "Select emoji",
            style: isDesktop
                ? STextStyles.desktopH3(context)
                : STextStyles.pageTitleH2(context),
            textAlign: TextAlign.left,
          ),
          SizedBox(
            height: isDesktop ? 28 : 16,
          ),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: GridView.builder(
                    itemCount: itemCount,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: emojisPerRow,
                    ),
                    itemBuilder: (context, index) {
                      final emoji = Emoji.all()[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(emoji);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: Colors.transparent,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              emoji.char,
                              style: isDesktop
                                  ? STextStyles.desktopTextSmall(context)
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            height: isDesktop ? 20 : 24,
          ),
          if (isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SecondaryButton(
                  label: "Cancel",
                  width: 248,
                  buttonHeight: ButtonHeight.l,
                  onPressed: Navigator.of(context).pop,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
