import "package:dropdown_button2/dropdown_button2.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";

import "../../../themes/stack_colors.dart";
import "../../../utilities/assets.dart";
import "../../../utilities/constants.dart";
import "../../../utilities/text_styles.dart";
import "../../../utilities/util.dart";

class ShopInBitStep4Dropdown extends StatelessWidget {
  const ShopInBitStep4Dropdown({
    super.key,
    required this.value,
    required this.items,
    required this.hintText,
    required this.onChanged,
  });

  final String? value;
  final List<String> items;
  final String hintText;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final stackColors = Theme.of(context).extension<StackColors>()!;

    final itemStyle = Util.isDesktop
        ? STextStyles.desktopTextExtraSmall(
            context,
          ).copyWith(color: stackColors.textFieldActiveText)
        : STextStyles.w500_14(context);

    final hintStyle = Util.isDesktop
        ? STextStyles.desktopTextExtraSmall(
            context,
          ).copyWith(color: stackColors.textFieldDefaultSearchIconLeft)
        : STextStyles.fieldLabel(context);

    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        value: value,
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: itemStyle),
              ),
            )
            .toList(),
        onChanged: onChanged,
        hint: Text(hintText, style: hintStyle),
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
          decoration: BoxDecoration(
            color: stackColors.textFieldDefaultBG,
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}
