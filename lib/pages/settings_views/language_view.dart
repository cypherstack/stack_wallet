import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/enums/languages_enum.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LanguageSettingsView extends ConsumerStatefulWidget {
  const LanguageSettingsView({Key? key}) : super(key: key);

  static const String routeName = "/languageSettings";

  @override
  ConsumerState<LanguageSettingsView> createState() => _LanguageViewState();
}

class _LanguageViewState extends ConsumerState<LanguageSettingsView> {
  // TODO: list of translations/localisations
  final languages = Language.values.map((e) => e.description).toList();

  late String current;
  late List<String> listWithoutSelected;

  late TextEditingController _searchController;

  final _searchFocusNode = FocusNode();

  void onTap(int index) {
    if (current.isEmpty || listWithoutSelected[index] == current) {
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
    _searchController = TextEditingController();
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
    current = ref
        .watch(prefsChangeNotifierProvider.select((value) => value.language));

    listWithoutSelected = languages;
    // if (current.isNotEmpty) {
    //   listWithoutSelected.remove(current);
    //   listWithoutSelected.insert(0, current);
    // }
    listWithoutSelected = _filtered();
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () async {
              // if (FocusScope.of(context).hasFocus) {
              //   FocusScope.of(context).unfocus();
              //   await Future<void>.delayed(const Duration(milliseconds: 75));
              // }
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          centerTitle: true,
          title: Text(
            "Language",
            style: STextStyles.titleH4(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView.separated(
              itemCount: listWithoutSelected.length,
              separatorBuilder: (_, __) => Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.popupBG,
              ),
              itemBuilder: (context, index) {
                final isCurrent = current == listWithoutSelected[index];

                return GestureDetector(
                  key: Key("languageSelect_${listWithoutSelected[index]}"),
                  onTap: () {
                    onTap(index);
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            listWithoutSelected[index],
                            style: isCurrent
                                ? STextStyles.bodyBold(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textGold,
                                  )
                                : STextStyles.bodyBold(context),
                          ),
                          if (isCurrent)
                            SvgPicture.asset(
                              Assets.svg.check,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textGold,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
