import "package:flutter/material.dart";

import "../../../themes/stack_colors.dart";
import "../../../utilities/constants.dart";
import "../../../utilities/text_styles.dart";
import "../../../utilities/util.dart";

/// Label + minus/value/plus counter row used in the travel form to set the
/// number of adults, children, infants and pets.
class ShopInBitTravelerCounter extends StatelessWidget {
  const ShopInBitTravelerCounter({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 20,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = Util.isDesktop
        ? STextStyles.desktopTextSmall(context)
        : STextStyles.w500_14(context);

    return Row(
      children: [
        Text(label, style: textStyle),
        const Spacer(),
        _CounterButton(
          symbol: "-",
          onTap: value > min ? () => onChanged(value - 1) : null,
          textStyle: textStyle,
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 24,
          child: Center(child: Text("$value", style: textStyle)),
        ),
        const SizedBox(width: 16),
        _CounterButton(
          symbol: "+",
          onTap: value < max ? () => onChanged(value + 1) : null,
          textStyle: textStyle,
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.symbol,
    required this.onTap,
    required this.textStyle,
  });

  final String symbol;
  final VoidCallback? onTap;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Theme.of(context).extension<StackColors>()!.textFieldDefaultBG,
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        child: Center(child: Text(symbol, style: textStyle)),
      ),
    );
  }
}
