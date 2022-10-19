import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class SettingsMenuItem<T> extends StatelessWidget {
  const SettingsMenuItem({
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
      //if val == group, then button is selected, otherwise unselected
      style: value == group
          ? Theme.of(context)
              .extension<StackColors>()!
              .getDesktopSettingsButtonColor(context)
          : Theme.of(context)
              .extension<StackColors>()!
              .getDesktopSettingsButtonColor(context),
      onPressed: () {
        onChanged(value);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            icon,
            const SizedBox(
              width: 12,
            ),
            Text(
              label,
              style: value == group //checks if option is selected
                  ? STextStyles.settingsMenuItemSelected(context)
                  : STextStyles.settingsMenuItem(context),
            ),
          ],
        ),
      ),
    );
  }
}
