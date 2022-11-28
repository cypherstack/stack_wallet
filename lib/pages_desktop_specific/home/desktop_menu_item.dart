import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class DMIController {
  VoidCallback? toggle;
  void dispose() {
    toggle = null;
  }
}

class DesktopMenuItem<T> extends StatefulWidget {
  const DesktopMenuItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.group,
    required this.onChanged,
    required this.duration,
    this.labelLength = 125,
    this.controller,
  }) : super(key: key);

  final Widget icon;
  final String label;
  final T value;
  final T group;
  final void Function(T) onChanged;
  final Duration duration;
  final double labelLength;
  final DMIController? controller;

  @override
  State<DesktopMenuItem<T>> createState() => _DesktopMenuItemState<T>();
}

class _DesktopMenuItemState<T> extends State<DesktopMenuItem<T>>
    with SingleTickerProviderStateMixin {
  late final Widget icon;
  late final String label;
  late final T value;
  late final T group;
  late final void Function(T) onChanged;
  late final Duration duration;
  late final double labelLength;

  late final DMIController? controller;

  late final AnimationController animationController;

  bool _iconOnly = false;

  void toggle() {
    setState(() {
      _iconOnly = !_iconOnly;
    });
    if (_iconOnly) {
      animationController.reverse();
    } else {
      animationController.forward();
    }
  }

  @override
  void initState() {
    icon = widget.icon;
    label = widget.label;
    value = widget.value;
    group = widget.group;
    onChanged = widget.onChanged;
    duration = widget.duration;
    labelLength = widget.labelLength;
    controller = widget.controller;

    controller?.toggle = toggle;
    animationController = AnimationController(
      vsync: this,
      duration: duration,
    );

    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: value == group
          ? Theme.of(context)
              .extension<StackColors>()!
              .getDesktopMenuButtonColorSelected(context)
          : Theme.of(context)
              .extension<StackColors>()!
              .getDesktopMenuButtonColor(context),
      onPressed: () {
        onChanged(value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: duration,
              width: _iconOnly ? 0 : 16,
            ),
            icon,
            AnimatedOpacity(
              duration: duration,
              opacity: _iconOnly ? 0 : 1.0,
              child: SizeTransition(
                sizeFactor: animationController,
                axis: Axis.horizontal,
                axisAlignment: -1,
                child: SizedBox(
                  width: labelLength,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 12,
                      ),
                      Text(
                        label,
                        style: value == group
                            ? STextStyles.desktopMenuItemSelected(context)
                            : STextStyles.desktopMenuItem(context),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
