import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../pages/settings_views/global_settings_view/stack_backup_views/sub_widgets/restoring_item_card.dart';
import '../../../providers/cash_fusion/fusion_progress_ui_state_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../widgets/conditional_parent.dart';
import '../../../widgets/rounded_container.dart';
import 'fusion_dialog.dart';

class FusionProgress extends ConsumerWidget {
  const FusionProgress({super.key, required this.walletId});

  final String walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressItem(
          iconAsset: Assets.svg.node,
          label: "Connecting to server",
          state: ref.watch(
            fusionProgressUIStateProvider(walletId)
                .select((value) => value.connecting),
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        _ProgressItem(
          iconAsset: Assets.svg.upFromLine,
          label: "Allocating outputs",
          state: ref.watch(
            fusionProgressUIStateProvider(walletId)
                .select((value) => value.outputs),
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        _ProgressItem(
          iconAsset: Assets.svg.peers,
          label: "Waiting for peers",
          state: ref.watch(
            fusionProgressUIStateProvider(walletId)
                .select((value) => value.peers),
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        _ProgressItem(
          iconAsset: Assets.svg.fusing,
          label: "Fusing",
          state: ref.watch(
            fusionProgressUIStateProvider(walletId)
                .select((value) => value.fusing),
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        _ProgressItem(
          iconAsset: Assets.svg.checkCircle,
          label: "Complete",
          state: ref.watch(
            fusionProgressUIStateProvider(walletId)
                .select((value) => value.complete),
          ),
        ),
      ],
    );
  }
}

class _ProgressItem extends StatelessWidget {
  const _ProgressItem({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.state,
  });

  final String iconAsset;
  final String label;
  final CashFusionState state;

  Widget _getIconForState(CashFusionStatus state, BuildContext context) {
    switch (state) {
      case CashFusionStatus.waiting:
        return SvgPicture.asset(
          Assets.svg.loader,
          color:
              Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
        );
      case CashFusionStatus.running:
        return SvgPicture.asset(
          Assets.svg.loader,
          color: Theme.of(context).extension<StackColors>()!.accentColorGreen,
        );
      case CashFusionStatus.success:
        return SvgPicture.asset(
          Assets.svg.checkCircle,
          color: Theme.of(context).extension<StackColors>()!.accentColorGreen,
        );
      case CashFusionStatus.failed:
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
          child: _getIconForState(state.status, context),
        ),
        title: label,
        subTitle: state.info != null && state.info!.isNotEmpty
            ? Text(
                state.info!,
                style: STextStyles.w500_12(context).copyWith(
                  color: Theme.of(context).extension<StackColors>()!.textError,
                ),
              )
            : null,
      ),
    );
  }
}
