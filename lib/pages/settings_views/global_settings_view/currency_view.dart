import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/global/base_currencies_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

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
    if (index == 0 || current.isEmpty) {
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
    return Scaffold(
      backgroundColor: CFColors.almostWhite,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            if (FocusScope.of(context).hasFocus) {
              FocusScope.of(context).unfocus();
              await Future<void>.delayed(const Duration(milliseconds: 75));
            }
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          "Currency",
          style: STextStyles.navBarTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          top: 12,
          left: 16,
          right: 16,
        ),
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
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (newString) {
                          setState(() => filter = newString);
                        },
                        style: STextStyles.field,
                        decoration: standardInputDecoration(
                          "Search",
                          _searchFocusNode,
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
                            color: CFColors.white,
                            borderRadius: _borderRadius(index),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            key: Key(
                                "currencySelect_${currenciesWithoutSelected[index]}"),
                            child: RoundedContainer(
                              padding: const EdgeInsets.all(0),
                              color: index == 0
                                  ? CFColors.selected
                                  : CFColors.white,
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
                                          activeColor: CFColors.link2,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
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
                                            currenciesWithoutSelected[index],
                                            key: (index == 0)
                                                ? const Key(
                                                    "selectedCurrencySettingsCurrencyText")
                                                : null,
                                            style: STextStyles.largeMedium14,
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
                                            key: (index == 0)
                                                ? const Key(
                                                    "selectedCurrencySettingsCurrencyTextDescription")
                                                : null,
                                            style: STextStyles.itemSubtitle,
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
