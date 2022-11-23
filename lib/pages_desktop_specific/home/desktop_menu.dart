import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages_desktop_specific/home/desktop_menu_item.dart';
import 'package:stackwallet/providers/desktop/current_desktop_menu_item.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

enum DesktopMenuItemId {
  myStack,
  exchange,
  notifications,
  addressBook,
  settings,
  support,
  about,
}

class DesktopMenu extends ConsumerStatefulWidget {
  const DesktopMenu({
    Key? key,
    this.onSelectionChanged,
    this.onSelectionWillChange,
  }) : super(key: key);

  final void Function(DesktopMenuItemId)? onSelectionChanged;
  final void Function(DesktopMenuItemId)? onSelectionWillChange;

  @override
  ConsumerState<DesktopMenu> createState() => _DesktopMenuState();
}

class _DesktopMenuState extends ConsumerState<DesktopMenu> {
  static const expandedWidth = 225.0;
  static const minimizedWidth = 72.0;

  double _width = expandedWidth;

  void updateSelectedMenuItem(DesktopMenuItemId idKey) {
    widget.onSelectionWillChange?.call(idKey);

    ref.read(currentDesktopMenuItemProvider.state).state = idKey;

    widget.onSelectionChanged?.call(idKey);
  }

  void toggleMinimize() {
    setState(() {
      _width = _width == expandedWidth ? minimizedWidth : expandedWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).extension<StackColors>()!.popupBG,
      child: SizedBox(
        width: _width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: _width == expandedWidth ? 22 : 25,
            ),
            SizedBox(
              width: _width == expandedWidth ? 70 : 32,
              height: _width == expandedWidth ? 70 : 32,
              child: SvgPicture.asset(
                Assets.svg.stackIcon(context),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              _width == expandedWidth ? "Stack Wallet" : "",
              style: STextStyles.desktopH2(context).copyWith(
                fontSize: 18,
                height: 23.4 / 18,
              ),
            ),
            const SizedBox(
              height: 60,
            ),
            Expanded(
              child: SizedBox(
                width: _width == expandedWidth
                    ? _width - 32 // 16 padding on either side
                    : _width - 16, // 8 padding on either side
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DesktopMenuItem(
                      icon: SvgPicture.asset(
                        Assets.svg.walletDesktop,
                        width: 20,
                        height: 20,
                        color: DesktopMenuItemId.myStack ==
                                ref
                                    .watch(currentDesktopMenuItemProvider.state)
                                    .state
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorDark
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorDark
                                .withOpacity(0.8),
                      ),
                      label: "My Stack",
                      value: DesktopMenuItemId.myStack,
                      group:
                          ref.watch(currentDesktopMenuItemProvider.state).state,
                      onChanged: updateSelectedMenuItem,
                      iconOnly: _width == minimizedWidth,
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    DesktopMenuItem(
                      icon: SvgPicture.asset(
                        Assets.svg.exchangeDesktop,
                        width: 20,
                        height: 20,
                        color: DesktopMenuItemId.exchange ==
                                ref
                                    .watch(currentDesktopMenuItemProvider.state)
                                    .state
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorDark
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorDark
                                .withOpacity(0.8),
                      ),
                      label: "Exchange",
                      value: DesktopMenuItemId.exchange,
                      group:
                          ref.watch(currentDesktopMenuItemProvider.state).state,
                      onChanged: updateSelectedMenuItem,
                      iconOnly: _width == minimizedWidth,
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    DesktopMenuItem(
                      icon: SvgPicture.asset(
                        ref.watch(notificationsProvider.select(
                                (value) => value.hasUnreadNotifications))
                            ? Assets.svg.bellNew(context)
                            : Assets.svg.bell,
                        width: 20,
                        height: 20,
                        color: ref.watch(notificationsProvider.select(
                                (value) => value.hasUnreadNotifications))
                            ? null
                            : DesktopMenuItemId.notifications ==
                                    ref
                                        .watch(currentDesktopMenuItemProvider
                                            .state)
                                        .state
                                ? Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorDark
                                : Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorDark
                                    .withOpacity(0.8),
                      ),
                      label: "Notifications",
                      value: DesktopMenuItemId.notifications,
                      group:
                          ref.watch(currentDesktopMenuItemProvider.state).state,
                      onChanged: updateSelectedMenuItem,
                      iconOnly: _width == minimizedWidth,
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    DesktopMenuItem(
                      icon: SvgPicture.asset(
                        Assets.svg.addressBookDesktop,
                        width: 20,
                        height: 20,
                        color: DesktopMenuItemId.addressBook ==
                                ref
                                    .watch(currentDesktopMenuItemProvider.state)
                                    .state
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorDark
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorDark
                                .withOpacity(0.8),
                      ),
                      label: "Address Book",
                      value: DesktopMenuItemId.addressBook,
                      group:
                          ref.watch(currentDesktopMenuItemProvider.state).state,
                      onChanged: updateSelectedMenuItem,
                      iconOnly: _width == minimizedWidth,
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    DesktopMenuItem(
                      icon: SvgPicture.asset(
                        Assets.svg.gear,
                        width: 20,
                        height: 20,
                        color: DesktopMenuItemId.settings ==
                                ref
                                    .watch(currentDesktopMenuItemProvider.state)
                                    .state
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorDark
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorDark
                                .withOpacity(0.8),
                      ),
                      label: "Settings",
                      value: DesktopMenuItemId.settings,
                      group:
                          ref.watch(currentDesktopMenuItemProvider.state).state,
                      onChanged: updateSelectedMenuItem,
                      iconOnly: _width == minimizedWidth,
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    DesktopMenuItem(
                      icon: SvgPicture.asset(
                        Assets.svg.messageQuestion,
                        width: 20,
                        height: 20,
                        color: DesktopMenuItemId.support ==
                                ref
                                    .watch(currentDesktopMenuItemProvider.state)
                                    .state
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorDark
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorDark
                                .withOpacity(0.8),
                      ),
                      label: "Support",
                      value: DesktopMenuItemId.support,
                      group:
                          ref.watch(currentDesktopMenuItemProvider.state).state,
                      onChanged: updateSelectedMenuItem,
                      iconOnly: _width == minimizedWidth,
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    DesktopMenuItem(
                      icon: SvgPicture.asset(
                        Assets.svg.aboutDesktop,
                        width: 20,
                        height: 20,
                        color: DesktopMenuItemId.about ==
                                ref
                                    .watch(currentDesktopMenuItemProvider.state)
                                    .state
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorDark
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorDark
                                .withOpacity(0.8),
                      ),
                      label: "About",
                      value: DesktopMenuItemId.about,
                      group:
                          ref.watch(currentDesktopMenuItemProvider.state).state,
                      onChanged: updateSelectedMenuItem,
                      iconOnly: _width == minimizedWidth,
                    ),
                    const Spacer(),
                    DesktopMenuItem(
                      icon: SvgPicture.asset(
                        Assets.svg.exitDesktop,
                        width: 20,
                        height: 20,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark
                            .withOpacity(0.8),
                      ),
                      label: "Exit",
                      value: 7,
                      group:
                          ref.watch(currentDesktopMenuItemProvider.state).state,
                      onChanged: (_) {
                        // todo: save stuff/ notify before exit?
                        exit(0);
                      },
                      iconOnly: _width == minimizedWidth,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                const Spacer(),
                IconButton(
                  splashRadius: 18,
                  onPressed: toggleMinimize,
                  icon: SvgPicture.asset(
                    Assets.svg.minimize,
                    height: 12,
                    width: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
