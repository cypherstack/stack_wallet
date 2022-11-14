import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/notifications/notification_card.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class DesktopNotificationsView extends ConsumerStatefulWidget {
  const DesktopNotificationsView({Key? key}) : super(key: key);

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
          ? RoundedWhiteContainer(
              child: Center(
                child: Text(
                  "Notifications will appear here",
                  style: STextStyles.desktopTextExtraExtraSmall(context),
                ),
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return NotificationCard(
                  notification: notifications[index],
                );
              },
            ),
    );
  }
}
