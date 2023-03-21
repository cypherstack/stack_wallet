import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackduo/providers/global/prefs_provider.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/enums/languages_enum.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog.dart';
import 'package:stackduo/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackduo/widgets/desktop/primary_button.dart';
import 'package:stackduo/widgets/desktop/secondary_button.dart';
import 'package:stackduo/widgets/stack_text_field.dart';

import '../../../../utilities/assets.dart';
import '../../../../utilities/theme/stack_colors.dart';
import '../../../../widgets/icon_widgets/x_icon.dart';
import '../../../../widgets/rounded_container.dart';
import '../../../../widgets/textfield_icon_button.dart';

class LanguageDialog extends ConsumerStatefulWidget {
  const LanguageDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<LanguageDialog> createState() => _LanguageDialog();
}

class _LanguageDialog extends ConsumerState<LanguageDialog> {
  late final TextEditingController searchLanguageController;

  late final FocusNode searchLanguageFocusNode;

  final languages = Language.values.map((e) => e.description).toList();

  late String current;
  late List<String> listWithoutSelected;

  void onTap(int index) {
    if (index == 0 || current.isEmpty) {
      // ignore if already selected language
      return;
    }
    current = listWithoutSelected[index];
    listWithoutSelected.remove(current);
    listWithoutSelected.insert(0, current);
    ref.read(prefsChangeNotifierProvider).language = current;
  }

  BorderRadius? _borderRadius(int index) {
    if (index == 0 && listWithoutSelected.length == 1) {
      return BorderRadius.circular(
        Constants.size.circularBorderRadius,
      );
    } else if (index == 0) {
      return BorderRadius.vertical(
        top: Radius.circular(
          Constants.size.circularBorderRadius,
        ),
      );
    } else if (index == listWithoutSelected.length - 1) {
      return BorderRadius.vertical(
        bottom: Radius.circular(
          Constants.size.circularBorderRadius,
        ),
      );
    }
    return null;
  }

  String filter = "";

  List<String> _filtered() {
    return listWithoutSelected
        .where(
            (element) => element.toLowerCase().contains(filter.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    searchLanguageController = TextEditingController();

    searchLanguageFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    searchLanguageController.dispose();

    searchLanguageFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    current = ref
        .watch(prefsChangeNotifierProvider.select((value) => value.language));

    listWithoutSelected = languages;
    if (current.isNotEmpty) {
      listWithoutSelected.remove(current);
      listWithoutSelected.insert(0, current);
    }
    listWithoutSelected = _filtered();

    return DesktopDialog(
      maxHeight: 700,
      maxWidth: 600,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "Select language",
                  style: STextStyles.desktopH3(context),
                  textAlign: TextAlign.center,
                ),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
          Expanded(
            flex: 24,
            child: NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context),
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  Constants.size.circularBorderRadius,
                                ),
                                child: TextField(
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  controller: searchLanguageController,
                                  focusNode: searchLanguageFocusNode,
                                  style: STextStyles.desktopTextMedium(context)
                                      .copyWith(
                                    height: 2,
                                  ),
                                  textAlign: TextAlign.left,
                                  decoration: standardInputDecoration("Search",
                                          searchLanguageFocusNode, context)
                                      .copyWith(
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
                                    suffixIcon: searchLanguageController
                                            .text.isNotEmpty
                                        ? Padding(
                                            padding:
                                                const EdgeInsets.only(right: 0),
                                            child: UnconstrainedBox(
                                              child: Row(
                                                children: [
                                                  TextFieldIconButton(
                                                    child: const XIcon(),
                                                    onTap: () async {
                                                      setState(() {
                                                        searchLanguageController
                                                            .text = "";
                                                        filter = "";
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: Builder(
                builder: (context) {
                  return CustomScrollView(
                    slivers: [
                      SliverOverlapInjector(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context,
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .popupBG,
                                borderRadius: _borderRadius(index),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                key: Key(
                                    "desktopSelectLanguage_${listWithoutSelected[index]}"),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32),
                                  child: RoundedContainer(
                                    padding: const EdgeInsets.all(0),
                                    color: index == 0
                                        ? Theme.of(context)
                                            .extension<StackColors>()!
                                            .currencyListItemBG
                                        : Theme.of(context)
                                            .extension<StackColors>()!
                                            .popupBG,
                                    child: RawMaterialButton(
                                      onPressed: () async {
                                        onTap(index);
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          Constants.size.circularBorderRadius,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: Radio(
                                                activeColor: Theme.of(context)
                                                    .extension<StackColors>()!
                                                    .radioButtonIconEnabled,
                                                value: true,
                                                groupValue: index == 0,
                                                onChanged: (_) {
                                                  onTap(index);
                                                },
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 12,
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  listWithoutSelected[index],
                                                  key: (index == 0)
                                                      ? const Key(
                                                          "desktopSettingsSelectedLanguageText")
                                                      : null,
                                                  style:
                                                      STextStyles.largeMedium14(
                                                          context),
                                                ),
                                                const SizedBox(
                                                  height: 2,
                                                ),
                                                Text(
                                                  listWithoutSelected[index],
                                                  key: (index == 0)
                                                      ? const Key(
                                                          "desktopSettingsSelectedLanguageTextDescription")
                                                      : null,
                                                  style:
                                                      STextStyles.itemSubtitle(
                                                          context),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: listWithoutSelected.length,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: "Cancel",
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: PrimaryButton(
                    label: "Save Changes",
                    onPressed: () {},
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
