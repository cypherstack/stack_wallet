import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/cakepay/cakepay_service.dart';
import '../../services/cakepay/src/models/card.dart';
import '../../services/cakepay/src/models/country.dart';
import '../../services/cakepay/src/models/vendor.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/constants.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_dialog.dart';
import '../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_text_field.dart';
import '../../utilities/assets.dart';
import 'cakepay_card_detail_view.dart';

class CakePayVendorsView extends StatefulWidget {
  const CakePayVendorsView({super.key});

  static const String routeName = "/cakePayVendors";

  @override
  State<CakePayVendorsView> createState() => _CakePayVendorsViewState();
}

class _CakePayVendorsViewState extends State<CakePayVendorsView> {
  List<CakePayVendor> _vendors = [];
  List<CakePayCountry> _countries = [];
  String? _selectedCountryCode;
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _countrySearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _loadVendors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _countrySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    final resp = await CakePayService.instance.client.getAllCountries();
    if (mounted && !resp.hasError && resp.value != null) {
      // Deduplicate by country code: the API can return entries like both
      // "US" and "United States" with the same code, which breaks
      // DropdownButton2 (values must be unique).
      final seen = <String>{};
      final unique = <CakePayCountry>[];
      for (final c in resp.value!) {
        if (seen.add(c.countryCode)) {
          unique.add(c);
        }
      }
      setState(() => _countries = unique);
    }
  }

  Future<void> _loadVendors() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final resp = await CakePayService.instance.client.getVendors(
      countryCode: _selectedCountryCode,
      search: _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : null,
    );
    if (mounted) {
      setState(() {
        _loading = false;
        if (!resp.hasError && resp.value != null) {
          _vendors = resp.value!;
        } else {
          _error = resp.exception?.message ?? "Failed to load gift cards";
        }
      });
    }
  }

  List<CakePayCard> get _allCards {
    final cards = <CakePayCard>[];
    for (final vendor in _vendors) {
      cards.addAll(vendor.cards.where((c) => c.available));
    }
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final cards = _allCards;

    final searchField = ClipRRect(
      borderRadius: BorderRadius.circular(Constants.size.circularBorderRadius),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
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
              _searchFocusNode,
              context,
            ).copyWith(
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Icon(Icons.search, size: 20),
              ),
            ),
        onSubmitted: (_) => _loadVendors(),
      ),
    );

    final countryDropdown = _countries.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton2<String?>(
                  value: _selectedCountryCode,
                  isExpanded: true,
                  hint: Text(
                    "All countries",
                    style: isDesktop
                        ? STextStyles.desktopTextExtraSmall(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textFieldDefaultSearchIconLeft,
                          )
                        : STextStyles.fieldLabel(context),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        "All countries",
                        style: isDesktop
                            ? STextStyles.desktopTextExtraSmall(
                                context,
                              ).copyWith(
                                color: Theme.of(
                                  context,
                                ).extension<StackColors>()!.textFieldActiveText,
                              )
                            : STextStyles.w500_14(context),
                      ),
                    ),
                    ..._countries.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.countryCode,
                        child: Text(
                          c.name,
                          style: isDesktop
                              ? STextStyles.desktopTextExtraSmall(
                                  context,
                                ).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textFieldActiveText,
                                )
                              : STextStyles.w500_14(context),
                        ),
                      ),
                    ),
                  ],
                  onMenuStateChange: (isOpen) {
                    if (!isOpen) {
                      _countrySearchController.clear();
                    }
                  },
                  onChanged: (value) {
                    setState(() => _selectedCountryCode = value);
                    _loadVendors();
                  },
                  buttonStyleData: ButtonStyleData(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.textFieldDefaultBG,
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
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
                          Theme.of(context)
                              .extension<StackColors>()!
                              .textFieldActiveSearchIconRight,
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
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.textFieldDefaultBG,
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                    ),
                  ),
                  dropdownSearchData: DropdownSearchData<String?>(
                    searchController: _countrySearchController,
                    searchInnerWidgetHeight: 48,
                    searchInnerWidget: TextFormField(
                      controller: _countrySearchController,
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
                        return "all countries".contains(
                          searchValue.toLowerCase(),
                        );
                      }
                      final country = _countries
                          .where((c) => c.countryCode == item.value)
                          .firstOrNull;
                      return country?.name.toLowerCase().contains(
                            searchValue.toLowerCase(),
                          ) ??
                          false;
                    },
                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
            ),
          );

    final cardsList = _loading
        ? const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : cards.isEmpty
        ? Center(
            child: Text(
              _error ?? "No gift cards found",
              style: isDesktop
                  ? STextStyles.desktopTextSmall(context)
                  : STextStyles.itemSubtitle(context),
            ),
          )
        : ListView.separated(
            shrinkWrap: isDesktop,
            primary: isDesktop ? false : null,
            itemCount: cards.length,
            separatorBuilder: (_, __) => SizedBox(height: isDesktop ? 16 : 12),
            itemBuilder: (context, index) {
              final card = cards[index];
              return GestureDetector(
                onTap: () {
                  if (isDesktop) {
                    Navigator.of(context, rootNavigator: true).pop();
                    showDialog<void>(
                      context: context,
                      builder: (_) => CakePayCardDetailView(cardId: card.id),
                    );
                  } else {
                    Navigator.of(context).pushNamed(
                      CakePayCardDetailView.routeName,
                      arguments: card.id,
                    );
                  }
                },
                child: RoundedWhiteContainer(
                  child: Row(
                    children: [
                      if (card.cardImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            card.cardImageUrl!,
                            width: isDesktop ? 60 : 48,
                            height: isDesktop ? 40 : 32,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.card_giftcard,
                              size: isDesktop ? 40 : 32,
                            ),
                          ),
                        )
                      else
                        Icon(Icons.card_giftcard, size: isDesktop ? 40 : 32),
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
                              card.denominationRange.isNotEmpty
                                  ? "${card.denominationRange} ${card.currencyCode ?? ''}"
                                  : card.currencyCode ?? '',
                              style: isDesktop
                                  ? STextStyles.desktopTextExtraExtraSmall(
                                      context,
                                    )
                                  : STextStyles.itemSubtitle12(
                                      context,
                                    ).copyWith(
                                      color: Theme.of(
                                        context,
                                      ).extension<StackColors>()!.textSubtitle1,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(
                          context,
                        ).extension<StackColors>()!.textSubtitle1,
                      ),
                    ],
                  ),
                ),
              );
            },
          );

    final body = Column(
      children: [
        searchField,
        countryDropdown,
        SizedBox(height: isDesktop ? 16 : 12),
        Expanded(child: cardsList),
      ],
    );

    return ConditionalParent(
      condition: isDesktop,
      builder: (child) => DesktopDialog(
        maxWidth: 580,
        maxHeight: 650,
        child: Column(
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 8,
                ),
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
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        ),
        child: body,
      ),
    );
  }
}
