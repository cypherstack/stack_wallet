import "package:dropdown_button2/dropdown_button2.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";

import "../../../themes/stack_colors.dart";
import "../../../utilities/assets.dart";
import "../../../utilities/constants.dart";
import "../../../utilities/text_styles.dart";
import "../../../utilities/util.dart";

const List<String> _usStates = [
  "Alabama (AL)",
  "Alaska (AK)",
  "Arizona (AZ)",
  "Arkansas (AR)",
  "California (CA)",
  "Colorado (CO)",
  "Connecticut (CT)",
  "Delaware (DE)",
  "Florida (FL)",
  "Georgia (GA)",
  "Hawaii (HI)",
  "Idaho (ID)",
  "Illinois (IL)",
  "Indiana (IN)",
  "Iowa (IA)",
  "Kansas (KS)",
  "Kentucky (KY)",
  "Louisiana (LA)",
  "Maine (ME)",
  "Maryland (MD)",
  "Massachusetts (MA)",
  "Michigan (MI)",
  "Minnesota (MN)",
  "Mississippi (MS)",
  "Missouri (MO)",
  "Montana (MT)",
  "Nebraska (NE)",
  "Nevada (NV)",
  "New Hampshire (NH)",
  "New Jersey (NJ)",
  "New Mexico (NM)",
  "New York (NY)",
  "North Carolina (NC)",
  "North Dakota (ND)",
  "Ohio (OH)",
  "Oklahoma (OK)",
  "Oregon (OR)",
  "Pennsylvania (PA)",
  "Rhode Island (RI)",
  "South Carolina (SC)",
  "South Dakota (SD)",
  "Tennessee (TN)",
  "Texas (TX)",
  "Utah (UT)",
  "Vermont (VT)",
  "Virginia (VA)",
  "Washington (WA)",
  "West Virginia (WV)",
  "Wisconsin (WI)",

  // Wyoming is now allowed as per chat with shopinbit
  // "Wyoming (WY)",
];

const List<String> _canadaProvinces = [
  "Alberta (AB)",
  "British Columbia (BC)",
  "Manitoba (MB)",
  "New Brunswick (NB)",
  "Newfoundland and Labrador (NL)",
  "Northwest Territories (NT)",
  "Nova Scotia (NS)",
  "Nunavut (NU)",
  "Ontario (ON)",
  "Prince Edward Island (PE)",
  "Quebec (QC)",
  "Saskatchewan (SK)",
  "Yukon (YT)",
];

List<String> _statesForCountry(String countryIso) => switch (countryIso) {
  "US" => _usStates,
  "CA" => _canadaProvinces,
  _ => throw ArgumentError.value(countryIso, "countryIso", "Must be US or CA"),
};

String _hintTextForCountry(String countryIso) => switch (countryIso) {
  "US" => "Select state",
  "CA" => "Select province / territory",
  _ => throw ArgumentError.value(countryIso, "countryIso", "Must be US or CA"),
};

class ShopInBitStatePicker extends StatefulWidget {
  const ShopInBitStatePicker({
    super.key,
    required this.countryIso,
    required this.selectedState,
    required this.onChanged,
  });

  final String countryIso;
  final String? selectedState;
  final ValueChanged<String?> onChanged;

  @override
  State<ShopInBitStatePicker> createState() => _ShopInBitStatePickerState();
}

class _ShopInBitStatePickerState extends State<ShopInBitStatePicker> {
  final TextEditingController _searchController = TextEditingController();

  List<String> get _states => _statesForCountry(widget.countryIso);

  String? get _validatedSelection {
    final String? selected = widget.selectedState;
    if (selected == null) return null;
    return _states.contains(selected) ? selected : null;
  }

  @override
  void didUpdateWidget(ShopInBitStatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countryIso != widget.countryIso) {
      // Invalidate selection when country changes.
      if (widget.selectedState != null &&
          !_statesForCountry(
            widget.countryIso,
          ).contains(widget.selectedState)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onChanged(null);
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        value: _validatedSelection,
        items: _states
            .map(
              (state) => DropdownMenuItem<String>(
                value: state,
                child: Text(state, style: itemStyle),
              ),
            )
            .toList(),
        onMenuStateChange: (isOpen) {
          if (!isOpen) {
            _searchController.clear();
          }
        },
        onChanged: widget.onChanged,
        hint: Text(_hintTextForCountry(widget.countryIso), style: hintStyle),
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
          offset: const Offset(0, -10),
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
          searchMatchFn: (item, searchValue) =>
              item.value?.toLowerCase().contains(searchValue.toLowerCase()) ??
              false,
        ),
        menuItemStyleData: const MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}
