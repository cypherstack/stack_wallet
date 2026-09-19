import 'package:flutter/material.dart';

import '../themes/stack_colors.dart';
import '../utilities/text_styles.dart';
import '../utilities/util.dart';
import '../widgets/rounded_container.dart';
import '../widgets/rounded_white_container.dart';

class NotificationCardLayout extends StatelessWidget {
  const NotificationCardLayout({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.dateString,
    required this.read,
  });

  final Widget icon;
  final String title;
  final String body;
  final String dateString;
  final bool read;

  static const double mobileIconSize = 24;
  static const double desktopIconSize = 30;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    final colors = Theme.of(context).extension<StackColors>()!;

    final TextStyle titleStyle = isDesktop
        ? STextStyles.desktopTextExtraExtraSmall(
            context,
          ).copyWith(color: colors.textDark)
        : STextStyles.titleBold12(context);
    final TextStyle subStyle = isDesktop
        ? STextStyles.desktopTextExtraExtraSmall(
            context,
          ).copyWith(color: colors.textSubtitle1)
        : STextStyles.label(context);

    return Stack(
      children: [
        RoundedWhiteContainer(
          padding: isDesktop
              ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
              : const EdgeInsets.all(12),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(title, style: titleStyle)),
                        if (isDesktop && !read)
                          Text(
                            "New",
                            style: STextStyles.desktopTextExtraExtraSmall(
                              context,
                            ).copyWith(color: colors.accentColorGreen),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(body, style: subStyle)),
                        const SizedBox(width: 8),
                        Text(dateString, style: subStyle),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (read)
          Positioned.fill(
            child: RoundedContainer(color: colors.background.withOpacity(0.5)),
          ),
      ],
    );
  }
}
