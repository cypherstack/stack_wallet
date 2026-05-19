import "package:dropdown_button2/dropdown_button2.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";

import "../../../services/shopinbit/shopinbit_service.dart";
import "../../../themes/stack_colors.dart";
import "../../../utilities/assets.dart";
import "../../../utilities/constants.dart";
import "../../../utilities/text_styles.dart";
import "../../../utilities/util.dart";

class ShopInBitCountryPicker extends StatefulWidget {
  const ShopInBitCountryPicker({
    super.key,
    required this.selectedIso,
    required this.onChanged,
    this.hintText = "Delivery country",
  });

  final String? selectedIso;
  final ValueChanged<String?> onChanged;
  final String hintText;

  @override
  State<ShopInBitCountryPicker> createState() => _ShopInBitCountryPickerState();
}

class _ShopInBitCountryPickerState extends State<ShopInBitCountryPicker> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _countries = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCountries() async {
    setState(() => _loading = true);
    try {
      final resp = await ShopInBitService.instance.client.getCountries();
      if (resp.hasError || resp.value == null) return;
      _countries = resp.value!;
      if (widget.selectedIso != null &&
          !_countries.any((c) => c["iso"] == widget.selectedIso)) {
        widget.onChanged(null);
      }
    } catch (_) {
      // Leave list empty; user will see no items.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final StackColors stackColors = Theme.of(context).extension<StackColors>()!;

    final TextStyle itemStyle = Util.isDesktop
        ? STextStyles.desktopTextExtraSmall(
            context,
          ).copyWith(color: stackColors.textFieldActiveText)
        : STextStyles.w500_14(context);

    final TextStyle hintStyle = Util.isDesktop
        ? STextStyles.desktopTextExtraSmall(
            context,
          ).copyWith(color: stackColors.textFieldDefaultSearchIconLeft)
        : STextStyles.fieldLabel(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(Constants.size.circularBorderRadius),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          value: widget.selectedIso,
          items: _countries
              .map(
                (c) => DropdownMenuItem<String>(
                  value: c["iso"] as String,
                  child: Text(c["label"] as String, style: itemStyle),
                ),
              )
              .toList(),
          onMenuStateChange: (isOpen) {
            if (!isOpen) {
              _searchController.clear();
            }
          },
          onChanged: _loading ? null : widget.onChanged,
          hint: Text(
            _loading ? "Loading countries..." : widget.hintText,
            style: hintStyle,
          ),
          isExpanded: true,
          buttonStyleData: ButtonStyleData(
            decoration: BoxDecoration(
              color: stackColors.textFieldDefaultBG,
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
                color: stackColors.textFieldActiveSearchIconRight,
              ),
            ),
          ),
          dropdownStyleData: DropdownStyleData(
            offset: const Offset(0, 0),
            elevation: 0,
            maxHeight: 300,
            decoration: BoxDecoration(
              color: stackColors.textFieldDefaultBG,
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
            ),
          ),
          dropdownSearchData: DropdownSearchData<String>(
            searchController: _searchController,
            searchInnerWidgetHeight: 48,
            searchInnerWidget: TextFormField(
              controller: _searchController,
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
              final String? label = _countries
                  .where((c) => c["iso"] == item.value)
                  .map((c) => c["label"] as String)
                  .firstOrNull;
              return label?.toLowerCase().contains(searchValue.toLowerCase()) ??
                  false;
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
