import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/cakepay/cakepay_service.dart';
import '../../services/cakepay/src/models/card.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/constants.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/icon_widgets/credit_card_icon.dart';
import '../../widgets/infinite_scroll_list_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rounded_container.dart';
import '../../widgets/stack_text_field.dart';
import 'cakepay_card_detail_view.dart';

class CakePayVendorsView extends StatefulWidget {
  const CakePayVendorsView({super.key});

  static const String routeName = "/cakePayVendors";

  @override
  State<CakePayVendorsView> createState() => _CakePayVendorsViewState();
}

class _CakePayVendorsViewState extends State<CakePayVendorsView> {
  List<String> _countryNames = [];
  String? _selectedCountry;
  String? _searchQuery;
  bool _loading = true;

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _countrySearchController = TextEditingController();

  final _listController = InfiniteScrollListController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        _countryNames = await CakePayService.instance.getCountryNames();
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _countrySearchController.dispose();
    super.dispose();
  }

  Future<({List<CakePayCard> cards, int? nextPage})> _fetchCards(
    int page,
  ) async {
    final response = await CakePayService.instance.client.getVendors(
      page: page,
      pageSize: 50,
      country: _selectedCountry,
      search: _searchQuery,
    );

    if (response.hasError || response.value == null) {
      throw response.exception ??
          Exception("Unknown exception with value is null????");
    }

    return (
      cards: response.value!.vendors
          .expand((e) => e.cards.where((e) => e.available))
          .toList(),
      nextPage: response.value!.nextPage,
    );
  }

  Future<void> _onCardTapped(CakePayCard card) async {
    await Navigator.of(
      context,
    ).pushNamed(CakePayCardDetailView.routeName, arguments: card);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return ConditionalParent(
      condition: isDesktop,
      builder: (child) => DesktopDialog(
        maxWidth: 580,
        maxHeight: MediaQuery.of(context).size.height - 64,
        child: Column(
          mainAxisSize: .min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "Gift Cards",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Flexible(
              child: Padding(
                padding: const .only(left: 32, right: 32, top: 8),
                child: child,
              ),
            ),
          ],
        ),
      ),
      child: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => Background(
          child: Scaffold(
            backgroundColor: Theme.of(
              context,
            ).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                "Gift Cards",
                style: STextStyles.navBarTitle(context),
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: child,
              ),
            ),
          ),
        ),
        child: Column(
          children: [
            _SearchField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onSubmitted: (value) {
                setState(() => _searchQuery = value);
                _listController.refresh();
              },
            ),
            if (_countryNames.isNotEmpty) ...[
              SizedBox(height: isDesktop ? 12 : 12),
              _CountryDropdown(
                countryNames: _countryNames,
                selectedCountry: _selectedCountry,
                searchController: _countrySearchController,
                onChanged: (value) {
                  setState(() => _selectedCountry = value);
                  _listController.refresh();
                },
              ),
            ],
            SizedBox(height: isDesktop ? 16 : 12),
            Expanded(
              child: _loading
                  ? const LoadingIndicator(width: 64, height: 64)
                  : InfiniteScrollListView<CakePayCard, int>(
                      controller: _listController,
                      prefetchThreshold: 300,
                      padding: .only(bottom: isDesktop ? 32 : 16),
                      firstPageKey: 1,
                      separatorBuilder: (_, _) =>
                          SizedBox(height: isDesktop ? 16 : 12),
                      fetchPage: (pageKey) async {
                        final result = await _fetchCards(pageKey);
                        return InfiniteScrollPage(
                          items: result.cards,
                          nextPageKey: result.nextPage,
                        );
                      },
                      itemBuilder: (context, item, index) {
                        return _CardTile(
                          card: item,
                          onTap: () => _onCardTapped(item),
                        );
                      },
                      firstPageProgressBuilder: (_) =>
                          const LoadingIndicator(width: 64, height: 64),
                      newPageProgressBuilder: (_) => const Center(
                        child: Padding(
                          padding: .all(16),
                          child: LoadingIndicator(width: 48, height: 48),
                        ),
                      ),
                      emptyBuilder: (_) => Center(
                        child: Padding(
                          padding: const .all(24),
                          child: Text(
                            "No items",
                            style: STextStyles.w500_14(context).copyWith(
                              color: Theme.of(
                                context,
                              ).extension<StackColors>()!.textSubtitle1,
                            ),
                          ),
                        ),
                      ),
                      newPageErrorBuilder: (context, error, retry) => Center(
                        child: Padding(
                          padding: const .all(16),
                          child: Column(
                            mainAxisSize: .min,
                            children: [
                              Text(
                                error.toString(),
                                style: STextStyles.w500_14(context).copyWith(
                                  color: Theme.of(
                                    context,
                                  ).extension<StackColors>()!.textSubtitle1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SecondaryButton(
                                label: "Retry",
                                buttonHeight: isDesktop ? .s : .l,
                                width: 100,
                                onPressed: retry,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Constants.size.circularBorderRadius),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: isDesktop
            ? STextStyles.desktopTextExtraSmall(context).copyWith(
                color: Theme.of(
                  context,
                ).extension<StackColors>()!.textFieldActiveText,
              )
            : STextStyles.field(context),
        decoration:
            standardInputDecoration(
              "Search gift cards",
              focusNode,
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
            ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}

class _CountryDropdown extends StatelessWidget {
  const _CountryDropdown({
    required this.countryNames,
    required this.selectedCountry,
    required this.searchController,
    required this.onChanged,
  });

  final List<String> countryNames;
  final String? selectedCountry;
  final TextEditingController searchController;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final colors = Theme.of(context).extension<StackColors>()!;
    final borderRadius = BorderRadius.circular(
      Constants.size.circularBorderRadius,
    );

    final itemStyle = isDesktop
        ? STextStyles.desktopTextExtraSmall(
            context,
          ).copyWith(color: colors.textFieldActiveText)
        : STextStyles.w500_14(context);

    return ClipRRect(
      borderRadius: borderRadius,
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String?>(
          value: selectedCountry,
          isExpanded: true,
          hint: Text(
            "All countries",
            style: isDesktop
                ? STextStyles.desktopTextExtraSmall(
                    context,
                  ).copyWith(color: colors.textFieldDefaultSearchIconLeft)
                : STextStyles.fieldLabel(context),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text("All countries", style: itemStyle),
            ),
            ...countryNames.map(
              (name) => DropdownMenuItem<String?>(
                value: name,
                child: Text(name, style: itemStyle),
              ),
            ),
          ],
          onMenuStateChange: (isOpen) {
            if (!isOpen) searchController.clear();
          },
          onChanged: onChanged,
          buttonStyleData: ButtonStyleData(
            decoration: BoxDecoration(
              color: colors.textFieldDefaultBG,
              borderRadius: borderRadius,
            ),
          ),
          iconStyleData: IconStyleData(
            icon: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: SvgPicture.asset(
                Assets.svg.chevronDown,
                width: 12,
                height: 6,
                colorFilter: ColorFilter.mode(
                  colors.textFieldActiveSearchIconRight,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          dropdownStyleData: DropdownStyleData(
            offset: const Offset(0, -10),
            elevation: 0,
            maxHeight: 300,
            decoration: BoxDecoration(
              color: colors.textFieldDefaultBG,
              borderRadius: borderRadius,
            ),
          ),
          dropdownSearchData: DropdownSearchData<String?>(
            searchController: searchController,
            searchInnerWidgetHeight: 48,
            searchInnerWidget: TextFormField(
              controller: searchController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                hintText: "Search...",
                hintStyle: STextStyles.fieldLabel(context),
                border: InputBorder.none,
              ),
            ),
            searchMatchFn: (item, searchValue) {
              if (item.value == null) {
                return "all countries".contains(searchValue.toLowerCase());
              }
              return item.value!.toLowerCase().contains(
                searchValue.toLowerCase(),
              );
            },
          ),
          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.onTap});

  final CakePayCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final colors = Theme.of(context).extension<StackColors>()!;

    return RoundedContainer(
      color: colors.popupBG,
      borderColor: isDesktop ? colors.textFieldDefaultBG : null,
      onPressed: onTap,
      padding: isDesktop ? const .all(16) : const .all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: card.cardImageUrl != null
                ? Image.network(
                    card.cardImageUrl!,
                    width: isDesktop ? 60 : 48,
                    height: isDesktop ? 40 : 32,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => CreditCardIcon(
                      width: isDesktop ? 40 : 32,
                      height: isDesktop ? 40 : 32,
                    ),
                  )
                : CreditCardIcon(
                    width: isDesktop ? 40 : 32,
                    height: isDesktop ? 40 : 32,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  style: isDesktop
                      ? STextStyles.desktopTextSmall(context)
                      : STextStyles.titleBold12(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (card.denominationRange.isNotEmpty)
                      card.denominationRange,
                    if (card.currencyCode != null) card.currencyCode!,
                  ].join(' '),
                  style: isDesktop
                      ? STextStyles.desktopTextExtraExtraSmall(context)
                      : STextStyles.itemSubtitle12(
                          context,
                        ).copyWith(color: colors.textSubtitle1),
                ),
              ],
            ),
          ),
          SvgPicture.asset(
            Assets.svg.chevronRight,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(colors.textSubtitle1, .srcIn),
          ),
        ],
      ),
    );
  }
}
