import 'dart:math';

import 'package:epicpay/providers/global/base_currencies_provider.dart';
import 'package:epicpay/providers/providers.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/utilities/util.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/conditional_parent.dart';
import 'package:epicpay/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicpay/widgets/desktop/primary_button.dart';
import 'package:epicpay/widgets/desktop/secondary_button.dart';
import 'package:epicpay/widgets/rounded_white_container.dart';
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
              centerTitle: true,
              title: Text(
                "Currency",
                style: STextStyles.titleH4(context),
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 24,
                  left: 24,
                  right: 24,
                ),
                child: child,
              ),
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
                  child: Container(),
                  // child: Padding(
                  //   padding: const EdgeInsets.only(bottom: 16),
                  //   child: ClipRRect(
                  //     borderRadius: BorderRadius.circular(
                  //       Constants.size.circularBorderRadius,
                  //     ),
                  //     child: TextField(
                  //       autocorrect: Util.isDesktop ? false : true,
                  //       enableSuggestions: Util.isDesktop ? false : true,
                  //       controller: _searchController,
                  //       focusNode: _searchFocusNode,
                  //       onChanged: (newString) {
                  //         setState(() => filter = newString);
                  //       },
                  //       style: STextStyles.field(context),
                  //       decoration: standardInputDecoration(
                  //         "Search",
                  //         _searchFocusNode,
                  //         context,
                  //       ).copyWith(
                  //         prefixIcon: Padding(
                  //           padding: const EdgeInsets.symmetric(
                  //             horizontal: 10,
                  //             vertical: 16,
                  //           ),
                  //           child: SvgPicture.asset(
                  //             Assets.svg.search,
                  //             width: 16,
                  //             height: 16,
                  //           ),
                  //         ),
                  //         suffixIcon: _searchController.text.isNotEmpty
                  //             ? Padding(
                  //                 padding: const EdgeInsets.only(right: 0),
                  //                 child: UnconstrainedBox(
                  //                   child: Row(
                  //                     children: [
                  //                       TextFieldIconButton(
                  //                         child: const XIcon(),
                  //                         onTap: () async {
                  //                           setState(() {
                  //                             _searchController.text = "";
                  //                             filter = "";
                  //                           });
                  //                         },
                  //                       ),
                  //                     ],
                  //                   ),
                  //                 ),
                  //               )
                  //             : null,
                  //       ),
                  //     ),
                  //   ),
                  // ),
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
                        final realIndex = index ~/ 2;

                        if (index % 2 == 0) {
                          final isCurrent =
                              current == currenciesWithoutSelected[realIndex];
                          return GestureDetector(
                            key: Key(
                                "languageSelect_${currenciesWithoutSelected[realIndex]}"),
                            onTap: () {
                              onTap(realIndex);
                            },
                            child: Container(
                              color: Colors.transparent,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      currenciesWithoutSelected[realIndex],
                                      style: isCurrent
                                          ? STextStyles.bodyBold(context)
                                              .copyWith(
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
                        } else {
                          return Container(
                            height: 1,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .popupBG,
                          );
                        }
                      },
                      semanticIndexCallback: (Widget widget, int localIndex) {
                        if (localIndex % 2 == 0) {
                          return localIndex ~/ 2;
                        }
                        return null;
                      },
                      childCount:
                          max(0, currenciesWithoutSelected.length * 2 - 1),
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
