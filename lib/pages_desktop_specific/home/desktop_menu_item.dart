import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages_desktop_specific/home/desktop_menu.dart';
import 'package:stackwallet/providers/desktop/current_desktop_menu_item.dart';
import 'package:stackwallet/providers/global/notifications_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class DMIController {
  VoidCallback? toggle;
  void dispose() {
    toggle = null;
  }
}

class DesktopNotificationsIcon extends ConsumerStatefulWidget {
  const DesktopNotificationsIcon({Key? key}) : super(key: key);

  @override
  ConsumerState<DesktopNotificationsIcon> createState() =>
      _DesktopNotificationsIconState();
}

class _DesktopNotificationsIconState
    extends ConsumerState<DesktopNotificationsIcon> {
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      ref.watch(notificationsProvider
              .select((value) => value.hasUnreadNotifications))
          ? Assets.svg.bellNew(context)
          : Assets.svg.bell,
      width: 20,
      height: 20,
      color: ref.watch(notificationsProvider
              .select((value) => value.hasUnreadNotifications))
          ? null
          : DesktopMenuItemId.notifications ==
                  ref.watch(currentDesktopMenuItemProvider.state).state
              ? Theme.of(context).extension<StackColors>()!.accentColorDark
              : Theme.of(context)
                  .extension<StackColors>()!
                  .accentColorDark
                  .withOpacity(0.8),
    );
  }
}

class DesktopMenuItem<T> extends ConsumerStatefulWidget {
  const DesktopMenuItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.duration,
    this.labelLength = 125,
    this.controller,
  }) : super(key: key);

  final Widget icon;
  final String label;
  final T value;
  final void Function(T) onChanged;
  final Duration duration;
  final double labelLength;
  final DMIController? controller;

  @override
  ConsumerState<DesktopMenuItem<T>> createState() => _DesktopMenuItemState<T>();
}

class _DesktopMenuItemState<T> extends ConsumerState<DesktopMenuItem<T>>
    with SingleTickerProviderStateMixin {
  late final Widget icon;
  late final String label;
  late final T value;
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
    onChanged = widget.onChanged;
    duration = widget.duration;
    labelLength = widget.labelLength;
    controller = widget.controller;

    controller?.toggle = toggle;
    animationController = AnimationController(
      vsync: this,
      duration: duration,
    )..forward();

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
    final group = ref.watch(currentDesktopMenuItemProvider.state).state;
    debugPrint("============ value:$value ============ group:$group");
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
