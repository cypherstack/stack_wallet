import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../db/drift/shared_db/shared_database.dart';
import '../themes/stack_colors.dart';
import '../utilities/assets.dart';
import '../utilities/format.dart';
import '../utilities/util.dart';
import 'notification_card_layout.dart';

class ShopInBitNotificationCard extends StatelessWidget {
  const ShopInBitNotificationCard({super.key, required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<StackColors>()!;
    final double iconSize = Util.isDesktop
        ? NotificationCardLayout.desktopIconSize
        : NotificationCardLayout.mobileIconSize;

    return NotificationCardLayout(
      icon: SvgPicture.asset(
        notification.iconAsset ?? Assets.svg.sib,
        width: iconSize,
        height: iconSize,
        color: colors.accentColorDark,
      ),
      title: notification.title,
      body: notification.body,
      dateString: Format.extractDateFrom(
        notification.createdAt.millisecondsSinceEpoch ~/ 1000,
      ),
      read: notification.read,
    );
  }
}
