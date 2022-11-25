import 'package:epicmobile/providers/global/base_currencies_provider.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/conditional_parent.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/desktop/primary_button.dart';
import 'package:epicmobile/widgets/desktop/secondary_button.dart';
import 'package:epicmobile/widgets/icon_widgets/x_icon.dart';
import 'package:epicmobile/widgets/rounded_container.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
import 'package:epicmobile/widgets/stack_text_field.dart';
import 'package:epicmobile/widgets/textfield_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class BaseCurrencySettingsView extends ConsumerStatefulWidget {
  const BaseCurrencySettingsView({Key? key}) : super(key: key);

  static const String routeName = "/baseCurrencySettings";

  @override
  ConsumerState<BaseCurrencySettingsView> createState() => _CurrencyViewState();
}

class _CurrencyViewState extends ConsumerState<BaseCurrencySettingsView> {
  late String current;
  late List<String> currenciesWithoutSelected;

  late TextEditingController _searchController;

  final _searchFocusNode = FocusNode();

  void onTap(int index) {
    if (currenciesWithoutSelected[index] == current || current.isEmpty) {
      // ignore if already selected currency
      return;
    }
    current = currenciesWithoutSelected[index];
    currenciesWithoutSelected.remove(current);
    currenciesWithoutSelected.insert(0, current);
    ref.read(prefsChangeNotifierProvider).currency = current;
  }

  BorderRadius? _borderRadius(int index) {
    if (index == 0 && currenciesWithoutSelected.length == 1) {
      return BorderRadius.circular(
        Constants.size.circularBorderRadius,
      );
    } else if (index == 0) {
      return BorderRadius.vertical(
        top: Radius.circular(
          Constants.size.circularBorderRadius,
        ),
      );
    } else if (index == currenciesWithoutSelected.length - 1) {
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
    final currencyMap = ref.read(baseCurrenciesProvider).map;
    return currenciesWithoutSelected.where((element) {
      return element.toLowerCase().contains(filter.toLowerCase()) ||
          (currencyMap[element]?.toLowerCase().contains(filter.toLowerCase()) ??
              false);
    }).toList();
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
        .watch(prefsChangeNotifierProvider.select((value) => value.currency));

    currenciesWithoutSelected = ref
        .watch(baseCurrenciesProvider.select((value) => value.map))
        .keys
        .toList();
    if (current.isNotEmpty) {
      currenciesWithoutSelected.remove(current);
      currenciesWithoutSelected.insert(0, current);
    }
    currenciesWithoutSelected = _filtered();
    final isDesktop = Util.isDesktop;

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) {
        return Background(
          child: Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () async {
                  if (FocusScope.of(context).hasFocus) {
                    FocusScope.of(context).unfocus();
                    await Future<void>.delayed(
                        const Duration(milliseconds: 75));
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              title: Text(
                "Currency",
                style: STextStyles.navBarTitle(context),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.only(
                top: 12,
                left: 16,
                right: 16,
              ),
              child: child,
            ),
          ),
        );
      },
      child: ConditionalParent(
        condition: isDesktop,
        builder: (child) {
          return Padding(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 32,
              left: 32,
              right: 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: RoundedWhiteContainer(
                    padding: const EdgeInsets.all(20),
                    borderColor:
                        Theme.of(context).extension<StackColors>()!.background,
                    child: child,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: "Cancel",
                        desktopMed: true,
                        onPressed: Navigator.of(context).pop,
                      ),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Expanded(
                      child: PrimaryButton(
                        label: "Save changes",
                        desktopMed: true,
                        onPressed: Navigator.of(context).pop,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        child: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
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
                          setState(() => filter = newString);
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
                                "currencySelect_${currenciesWithoutSelected[index]}"),
                            child: RoundedContainer(
                              padding: const EdgeInsets.all(0),
                              color: currenciesWithoutSelected[index] == current
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
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          value: true,
                                          groupValue: currenciesWithoutSelected[
                                                  index] ==
                                              current,
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
                                            currenciesWithoutSelected[index],
                                            key: (currenciesWithoutSelected[
                                                        index] ==
                                                    current)
                                                ? const Key(
                                                    "selectedCurrencySettingsCurrencyText")
                                                : null,
                                            style: STextStyles.largeMedium14(
                                                context),
                                          ),
                                          const SizedBox(
                                            height: 2,
                                          ),
                                          Text(
                                            ref.watch(baseCurrenciesProvider
                                                        .select((value) =>
                                                            value.map))[
                                                    currenciesWithoutSelected[
                                                        index]] ??
                                                "",
                                            key: (currenciesWithoutSelected[
                                                        index] ==
                                                    current)
                                                ? const Key(
                                                    "selectedCurrencySettingsCurrencyTextDescription")
                                                : null,
                                            style: STextStyles.itemSubtitle(
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
                        );
                      },
                      childCount: currenciesWithoutSelected.length,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
