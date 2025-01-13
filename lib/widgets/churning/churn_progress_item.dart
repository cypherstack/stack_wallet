import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../pages/settings_views/global_settings_view/stack_backup_views/sub_widgets/restoring_item_card.dart';
import '../../services/churning_service.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../conditional_parent.dart';
import '../rounded_container.dart';

class ProgressItem extends StatelessWidget {
  const ProgressItem({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.status,
    this.error,
  });

  final String iconAsset;
  final String label;
  final ChurnStatus status;
  final Object? error;

  Widget _getIconForState(ChurnStatus status, BuildContext context) {
    switch (status) {
      case ChurnStatus.waiting:
        return SvgPicture.asset(
          Assets.svg.loader,
          color:
              Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
        );
      case ChurnStatus.running:
        return SvgPicture.asset(
          Assets.svg.loader,
          color: Theme.of(context).extension<StackColors>()!.accentColorGreen,
        );
      case ChurnStatus.success:
        return SvgPicture.asset(
          Assets.svg.checkCircle,
          color: Theme.of(context).extension<StackColors>()!.accentColorGreen,
        );
      case ChurnStatus.failed:
        return SvgPicture.asset(
          Assets.svg.circleAlert,
          color: Theme.of(context).extension<StackColors>()!.textError,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) => RoundedContainer(
        padding: EdgeInsets.zero,
        color: Theme.of(context).extension<StackColors>()!.popupBG,
        borderColor: Theme.of(context).extension<StackColors>()!.background,
        child: child,
      ),
      child: RestoringItemCard(
        left: SizedBox(
          width: 32,
          height: 32,
          child: RoundedContainer(
            padding: const EdgeInsets.all(0),
            color:
                Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
            child: Center(
              child: SvgPicture.asset(
                iconAsset,
                width: 18,
                height: 18,
                color: Theme.of(context).extension<StackColors>()!.textDark,
              ),
            ),
          ),
        ),
        right: SizedBox(
          width: 20,
          height: 20,
          child: _getIconForState(status, context),
        ),
        title: label,
        subTitle: error != null
            ? Text(
                error!.toString(),
                style: STextStyles.w500_12(context).copyWith(
                  color: Theme.of(context).extension<StackColors>()!.textError,
                ),
              )
            : null,
      ),
    );
  }
}
