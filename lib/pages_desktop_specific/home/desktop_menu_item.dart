import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class DesktopMenuItem<T> extends StatelessWidget {
  const DesktopMenuItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.group,
    required this.onChanged,
  }) : super(key: key);

  final Widget icon;
  final String label;
  final T value;
  final T group;
  final void Function(T) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: value == group
          ? CFColors.getDesktopMenuButtonColorSelected(context)
          : CFColors.getDesktopMenuButtonColor(context),
      onPressed: () {
        onChanged(value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(
              width: 12,
            ),
            Text(
              label,
              style: value == group
                  ? STextStyles.desktopMenuItemSelected
                  : STextStyles.desktopMenuItem,
            ),
          ],
        ),
      ),
    );
  }
}
