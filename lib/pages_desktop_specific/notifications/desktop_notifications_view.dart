/* 
 * This file is part of Stack Wallet.
 * 
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 * Generated by Cypher Stack on 2023-05-26
 *
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notifications/notification_card.dart';
import '../../providers/providers.dart';
import '../../providers/ui/unread_notifications_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/desktop/desktop_app_bar.dart';
import '../../widgets/desktop/desktop_scaffold.dart';
import '../../widgets/rounded_white_container.dart';

class DesktopNotificationsView extends ConsumerStatefulWidget {
  const DesktopNotificationsView({super.key});

  static const String routeName = "/desktopNotifications";

  @override
  ConsumerState<DesktopNotificationsView> createState() =>
      _DesktopNotificationsViewState();
}

class _DesktopNotificationsViewState
    extends ConsumerState<DesktopNotificationsView> {
  @override
  Widget build(BuildContext context) {
    final notifications =
        ref.watch(notificationsProvider.select((value) => value.notifications));

    return DesktopScaffold(
      background: Theme.of(context).extension<StackColors>()!.background,
      appBar: DesktopAppBar(
        isCompactHeight: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            "Notifications",
            style: STextStyles.desktopH3(context),
          ),
        ),
      ),
      body: notifications.isEmpty
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: RoundedWhiteContainer(
                    child: Center(
                      child: Text(
                        "Notifications will appear here",
                        style: STextStyles.desktopTextExtraExtraSmall(context),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              primary: false,
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                if (notification.read == false) {
                  ref
                      .read(unreadNotificationsStateProvider.state)
                      .state
                      .add(notification.id);
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 5,
                  ),
                  child: NotificationCard(
                    notification: notification,
                  ),
                );
              },
            ),
    );
  }
}
