import "package:flutter/material.dart";

import "../../../utilities/text_styles.dart";
import "../../../utilities/util.dart";

class ShopInBitLabeledCheckbox extends StatelessWidget {
  const ShopInBitLabeledCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle = Util.isDesktop
        ? STextStyles.desktopTextSmall(context)
        : STextStyles.w500_14(context);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: IgnorePointer(
                child: Checkbox(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  value: value,
                  onChanged: (_) {},
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: labelStyle)),
          ],
        ),
      ),
    );
  }
}
