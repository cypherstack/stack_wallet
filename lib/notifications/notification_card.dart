import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/notification_model.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    Key? key,
    required this.notification,
  }) : super(key: key);

  final NotificationModel notification;

  String extractPrettyDateString(DateTime date) {
    // TODO: format this differently to better match the design
    return Format.extractDateFrom(date.millisecondsSinceEpoch ~/ 1000);
  }

  static const double mobileIconSize = 24;
  static const double desktopIconSize = 30;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return Stack(
      children: [
        RoundedWhiteContainer(
          padding: isDesktop
              ? const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                )
              : const EdgeInsets.all(12),
          child: Row(
            children: [
              notification.changeNowId == null
                  ? SvgPicture.asset(
                      notification.iconAssetName,
                      width: isDesktop ? desktopIconSize : mobileIconSize,
                      height: isDesktop ? desktopIconSize : mobileIconSize,
                    )
                  : Container(
                      width: isDesktop ? desktopIconSize : mobileIconSize,
                      height: isDesktop ? desktopIconSize : mobileIconSize,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: SvgPicture.asset(
                        notification.iconAssetName,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark,
                        width: isDesktop ? desktopIconSize : mobileIconSize,
                        height: isDesktop ? desktopIconSize : mobileIconSize,
                      ),
                    ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConditionalParent(
                      condition: isDesktop && !notification.read,
                      builder: (child) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          child,
                          Text(
                            "New",
                            style:
                                STextStyles.desktopTextExtraExtraSmall(context)
                                    .copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .accentColorGreen,
                            ),
                          )
                        ],
                      ),
                      child: Text(
                        notification.title,
                        style: isDesktop
                            ? STextStyles.desktopTextExtraExtraSmall(context)
                                .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark,
                              )
                            : STextStyles.titleBold12(context),
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification.description,
                          style: isDesktop
                              ? STextStyles.desktopTextExtraExtraSmall(context)
                                  .copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textSubtitle1,
                                )
                              : STextStyles.label(context),
                        ),
                        Text(
                          extractPrettyDateString(notification.date),
                          style: isDesktop
                              ? STextStyles.desktopTextExtraExtraSmall(context)
                                  .copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textSubtitle1,
                                )
                              : STextStyles.label(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (notification.read)
          Positioned.fill(
            child: RoundedContainer(
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .background
                  .withOpacity(0.5),
            ),
          ),
      ],
    );
  }
}
