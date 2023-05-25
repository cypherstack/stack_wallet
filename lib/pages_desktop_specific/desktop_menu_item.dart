import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_menu.dart';
import 'package:stackwallet/providers/desktop/current_desktop_menu_item.dart';
import 'package:stackwallet/providers/global/notifications_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class DMIController {
  VoidCallback? toggle;
  void dispose() {
    toggle = null;
  }
}

class DesktopMyStackIcon extends ConsumerWidget {
  const DesktopMyStackIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SvgPicture.asset(
      Assets.svg.walletDesktop,
      width: 20,
      height: 20,
      color: DesktopMenuItemId.myStack ==
              ref.watch(currentDesktopMenuItemProvider.state).state
          ? Theme.of(context).extension<StackColors>()!.accentColorDark
          : Theme.of(context)
              .extension<StackColors>()!
              .accentColorDark
              .withOpacity(0.8),
    );
  }
}

class DesktopExchangeIcon extends ConsumerWidget {
  const DesktopExchangeIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SvgPicture.asset(
      Assets.svg.exchangeDesktop,
      width: 20,
      height: 20,
      color: DesktopMenuItemId.exchange ==
              ref.watch(currentDesktopMenuItemProvider.state).state
          ? Theme.of(context).extension<StackColors>()!.accentColorDark
          : Theme.of(context)
              .extension<StackColors>()!
              .accentColorDark
              .withOpacity(0.8),
    );
  }
}

class DesktopBuyIcon extends ConsumerWidget {
  const DesktopBuyIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SvgPicture.file(
      File(ref.watch(themeAssetsProvider).buy),
      width: 20,
      height: 20,
      color: DesktopMenuItemId.buy ==
              ref.watch(currentDesktopMenuItemProvider.state).state
          ? Theme.of(context).extension<StackColors>()!.accentColorDark
          : Theme.of(context)
              .extension<StackColors>()!
              .accentColorDark
              .withOpacity(0.8),
    );
  }
}

class DesktopNotificationsIcon extends ConsumerWidget {
  const DesktopNotificationsIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(notificationsProvider
            .select((value) => value.hasUnreadNotifications))
        ? SvgPicture.file(
            File(
              ref.watch(
                themeProvider.select(
                  (value) => value.assets.bellNew,
                ),
              ),
            ),
            width: 20,
            height: 20,
          )
        : SvgPicture.asset(
            Assets.svg.bell,
            width: 20,
            height: 20,
            color: ref.watch(notificationsProvider
                    .select((value) => value.hasUnreadNotifications))
                ? null
                : DesktopMenuItemId.notifications ==
                        ref.watch(currentDesktopMenuItemProvider.state).state
                    ? Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorDark
                    : Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorDark
                        .withOpacity(0.8),
          );
  }
}

class DesktopAddressBookIcon extends ConsumerWidget {
  const DesktopAddressBookIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SvgPicture.asset(
      Assets.svg.addressBookDesktop,
      width: 20,
      height: 20,
      color: DesktopMenuItemId.addressBook ==
              ref.watch(currentDesktopMenuItemProvider.state).state
          ? Theme.of(context).extension<StackColors>()!.accentColorDark
          : Theme.of(context)
              .extension<StackColors>()!
              .accentColorDark
              .withOpacity(0.8),
    );
  }
}

class DesktopSettingsIcon extends ConsumerWidget {
  const DesktopSettingsIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SvgPicture.asset(
      Assets.svg.gear,
      width: 20,
      height: 20,
      color: DesktopMenuItemId.settings ==
              ref.watch(currentDesktopMenuItemProvider.state).state
          ? Theme.of(context).extension<StackColors>()!.accentColorDark
          : Theme.of(context)
              .extension<StackColors>()!
              .accentColorDark
              .withOpacity(0.8),
    );
  }
}

class DesktopSupportIcon extends ConsumerWidget {
  const DesktopSupportIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SvgPicture.asset(
      Assets.svg.messageQuestion,
      width: 20,
      height: 20,
      color: DesktopMenuItemId.support ==
              ref.watch(currentDesktopMenuItemProvider.state).state
          ? Theme.of(context).extension<StackColors>()!.accentColorDark
          : Theme.of(context)
              .extension<StackColors>()!
              .accentColorDark
              .withOpacity(0.8),
    );
  }
}

class DesktopAboutIcon extends ConsumerWidget {
  const DesktopAboutIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SvgPicture.asset(
      Assets.svg.aboutDesktop,
      width: 20,
      height: 20,
      color: DesktopMenuItemId.about ==
              ref.watch(currentDesktopMenuItemProvider.state).state
          ? Theme.of(context).extension<StackColors>()!.accentColorDark
          : Theme.of(context)
              .extension<StackColors>()!
              .accentColorDark
              .withOpacity(0.8),
    );
  }
}

class DesktopExitIcon extends ConsumerWidget {
  const DesktopExitIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SvgPicture.asset(
      Assets.svg.exitDesktop,
      width: 20,
      height: 20,
      color: Theme.of(context)
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

    return TextButton(
      style: value == group
          ? Theme.of(context)
              .extension<StackColors>()!
              .getDesktopMenuButtonStyleSelected(context)
          : Theme.of(context)
              .extension<StackColors>()!
              .getDesktopMenuButtonStyle(context),
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
