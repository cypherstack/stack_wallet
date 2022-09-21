import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';

class DesktopMenuItem<T> extends StatelessWidget {
  const DesktopMenuItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.group,
    required this.onChanged,
    required this.iconOnly,
  }) : super(key: key);

  final Widget icon;
  final String label;
  final T value;
  final T group;
  final void Function(T) onChanged;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: value == group
          ? StackTheme.instance.getDesktopMenuButtonColorSelected(context)
          : StackTheme.instance.getDesktopMenuButtonColor(context),
      onPressed: () {
        onChanged(value);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: iconOnly ? 0 : 16,
        ),
        child: Row(
          mainAxisAlignment:
              iconOnly ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            icon,
            if (!iconOnly)
              const SizedBox(
                width: 12,
              ),
            if (!iconOnly)
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
