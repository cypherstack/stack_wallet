import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class EmojiSelectSheet extends ConsumerStatefulWidget {
  const EmojiSelectSheet({
    Key? key,
  }) : super(key: key);

  final double horizontalPadding = 24;
  final double emojiSize = 24;
  final double minimumEmojiSpacing = 25;

  @override
  ConsumerState<EmojiSelectSheet> createState() => _EmojiSelectSheetState();
}

class _EmojiSelectSheetState extends ConsumerState<EmojiSelectSheet> {
  final isDesktop = Util.isDesktop;

  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final double horizontalPadding = 24;
  late final double emojiSize = 24;
  late final double minimumEmojiSpacing = 25;

  String _searchTerm = "";

  List<Emoji> filtered(String text) {
    if (text.isEmpty) {
      return Emoji.all();
    }

    text = text.toLowerCase();

    return Emoji.all()
        .where((e) => e.keywords
            .where(
              (e) => e.contains(text),
            )
            .isNotEmpty)
        .toList(growable: false);
  }

  @override
  void initState() {
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = isDesktop ? const Size(600, 700) : MediaQuery.of(context).size;
    final maxHeight = size.height * (isDesktop ? 0.6 : 0.9);
    final availableWidth = size.width - (2 * horizontalPadding);
    final emojisPerRow =
        ((availableWidth - emojiSize) ~/ (emojiSize + minimumEmojiSpacing)) + 1;

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
            height: isDesktop ? 16 : 12,
          ),
          Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: TextField(
                autocorrect: Util.isDesktop ? false : true,
                enableSuggestions: Util.isDesktop ? false : true,
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (newString) {
                  setState(() => _searchTerm = newString);
                },
                style: STextStyles.field(context),
                decoration: standardInputDecoration(
                  "Search",
                  _searchFocusNode,
                  context,
                ).copyWith(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 16,
                    ),
                    child: SvgPicture.asset(
                      Assets.svg.search,
                      width: 16,
                      height: 16,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 0),
                          child: UnconstrainedBox(
                            child: Row(
                              children: [
                                TextFieldIconButton(
                                  child: const XIcon(),
                                  onTap: () async {
                                    setState(() {
                                      _searchController.text = "";
                                      _searchTerm = "";
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          SizedBox(
            height: isDesktop ? 28 : 16,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final emojis = filtered(_searchTerm);
                      final itemCount = emojis.length;
                      return GridView.builder(
                        itemCount: itemCount,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: emojisPerRow,
                        ),
                        itemBuilder: (context, index) {
                          final emoji = emojis[index];
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
