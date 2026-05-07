import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/cakepay/cakepay_service.dart';
import '../../services/cakepay/src/models/card.dart';
import '../../services/cakepay/src/models/vendor.dart';
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
import '../../widgets/loading_indicator.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_text_field.dart';
import 'cakepay_card_detail_view.dart';

class CakePayVendorsView extends StatefulWidget {
  const CakePayVendorsView({super.key});

  static const String routeName = "/cakePayVendors";

  @override
  State<CakePayVendorsView> createState() => _CakePayVendorsViewState();
}

class _CakePayVendorsViewState extends State<CakePayVendorsView> {
  List<CakePayVendor> _vendors = [];
  List<String> _countryNames = [];
  String? _selectedCountry;
  bool _loading = true;
  String? _error;

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _countrySearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _countrySearchController.dispose();
    super.dispose();
  }

  List<CakePayCard> _availableCards() =>
      _vendors.expand((v) => v.cards.where((c) => c.available)).toList();

  /// Derive a country list from the loaded vendors so we don't need the
  /// broken /marketplace/countries/ endpoint.
  void _deriveCountries() {
    final seen = <String>{};
    _countryNames =
        _vendors
            .map((v) => v.country)
            .whereType<String>()
            .where((c) => c.isNotEmpty && seen.add(c))
            .toList()
          ..sort();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final resp = await CakePayService.instance.client.getVendors(
      country: _selectedCountry,
      search: _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : null,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      if (!resp.hasError && resp.value != null) {
        _vendors = resp.value!;
        _deriveCountries();
      } else {
        _error = resp.exception?.message ?? "Failed to load gift cards";
      }
    });
  }

  void _onCardTapped(CakePayCard card) {
    if (Util.isDesktop) {
      Navigator.of(context, rootNavigator: true).pop();
      showDialog<void>(
        context: context,
        builder: (_) => CakePayCardDetailView(card: card),
      );
    } else {
      Navigator.of(
        context,
      ).pushNamed(CakePayCardDetailView.routeName, arguments: card);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final cards = _availableCards();

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
        child: Column(
          children: [
            _SearchField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onSubmitted: (_) => _loadVendors(),
            ),
            if (_countryNames.isNotEmpty) ...[
              SizedBox(height: isDesktop ? 12 : 12),
              _CountryDropdown(
                countryNames: _countryNames,
                selectedCountry: _selectedCountry,
                searchController: _countrySearchController,
                onChanged: (value) {
                  setState(() => _selectedCountry = value);
                  _loadVendors();
                },
              ),
            ],
            SizedBox(height: isDesktop ? 16 : 12),
            Expanded(
              child: _loading
                  ? const LoadingIndicator(width: 48, height: 48)
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
                      separatorBuilder: (_, __) =>
                          SizedBox(height: isDesktop ? 16 : 12),
                      itemBuilder: (_, index) => _CardTile(
                        card: cards[index],
                        onTap: () => _onCardTapped(cards[index]),
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
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Icon(Icons.search, size: 20),
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

    return GestureDetector(
      onTap: onTap,
      child: RoundedWhiteContainer(
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
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.card_giftcard, size: isDesktop ? 40 : 32),
                    )
                  : Icon(Icons.card_giftcard, size: isDesktop ? 40 : 32),
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
            Icon(Icons.chevron_right, color: colors.textSubtitle1),
          ],
        ),
      ),
    );
  }
}
