import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/sub_widgets/restoring_item_card.dart';
import 'package:stackwallet/pages_desktop_specific/cashfusion/sub_widgets/fusion_dialog.dart';
import 'package:stackwallet/providers/cash_fusion/fusion_progress_ui_state_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class FusionProgress extends ConsumerWidget {
  const FusionProgress({super.key, required this.walletId});

  final String walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoundedContainer(
          color: Theme.of(context).extension<StackColors>()!.snackBarBackError,
          child: Text(
            "Do not close this window. If you exit, "
            "the process will be canceled.",
            style: Util.isDesktop
                ? STextStyles.smallMed14(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .snackBarTextError,
                  )
                : STextStyles.w500_14(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .snackBarTextError,
                  ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        _ProgressItem(
            iconAsset: Assets.svg.node,
            label: "Connecting to server",
            status: ref.watch(fusionProgressUIStateProvider(walletId)
                .select((value) => value.connecting)),
            info: ref.watch(fusionProgressUIStateProvider(walletId)
                .select((value) => value.connectionInfo))),
        const SizedBox(
          height: 12,
        ),
        _ProgressItem(
            iconAsset: Assets.svg.upFromLine,
            label: "Allocating outputs",
            status: ref.watch(fusionProgressUIStateProvider(walletId)
                .select((value) => value.outputs)),
            info: ref.watch(fusionProgressUIStateProvider(walletId)
                .select((value) => value.outputsInfo))),
        const SizedBox(
          height: 12,
        ),
        _ProgressItem(
            iconAsset: Assets.svg.peers,
            label: "Waiting for peers",
            status: ref.watch(fusionProgressUIStateProvider(walletId)
                .select((value) => value.peers)),
            info: ref.watch(fusionProgressUIStateProvider(walletId)
                .select((value) => value.peersInfo))),
        const SizedBox(
          height: 12,
        ),
        _ProgressItem(
            iconAsset: Assets.svg.fusing,
            label: "Fusing",
            status: ref.watch(fusionProgressUIStateProvider(walletId)
                .select((value) => value.fusing)),
            info: ref.watch(fusionProgressUIStateProvider(walletId)
                .select((value) => value.fusingInfo))),
        const SizedBox(
          height: 12,
        ),
        _ProgressItem(
            iconAsset: Assets.svg.checkCircle,
            label: "Complete",
            status: ref.watch(fusionProgressUIStateProvider(walletId)
                .select((value) => value.complete)),
            info: ref.watch(fusionProgressUIStateProvider(walletId)
                .select((value) => value.completeInfo))),
      ],
    );
  }
}

class _ProgressItem extends StatelessWidget {
  const _ProgressItem({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.status,
    this.info,
  });

  final String iconAsset;
  final String label;
  final CashFusionStatus status;
  final String? info;

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
        subTitle: info != null
            ? Text(info!) // TODO style error message eg. red.
            : null,
      ),
    );
  }
}
