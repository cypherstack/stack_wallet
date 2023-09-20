import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/sub_widgets/restoring_item_card.dart';
import 'package:stackwallet/providers/cash_fusion/fusion_progress_ui_state_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

enum CashFusionStatus { waiting, fusing, success, failed }

class FusionDialog extends StatelessWidget {
  const FusionDialog({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget _getIconForState(CashFusionStatus state) {
      switch (state) {
        case CashFusionStatus.waiting:
          return SvgPicture.asset(
            Assets.svg.loader,
            color:
                Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
          );
        case CashFusionStatus.fusing:
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

    return DesktopDialog(
      maxHeight: 600,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 10,
            left: 20,
            bottom: 20,
            right: 10,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text(
                      "Fusion progress",
                      style: STextStyles.desktopH2(context),
                    ),
                  ),
                  DesktopDialogCloseButton(
                    onPressedOverride: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    RoundedContainer(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .snackBarBackError,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Do not close this window. If you exit, "
                            "the process will be canceled.",
                            style: STextStyles.smallMed14(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Consumer(builder: (_, ref, __) {
                      final state = ref.watch(fusionProgressUIStateProvider
                          .select((value) => value.connecting));
                      return RoundedContainer(
                        padding: EdgeInsets.zero,
                        color:
                            Theme.of(context).extension<StackColors>()!.popupBG,
                        borderColor: Theme.of(context)
                            .extension<StackColors>()!
                            .background,
                        child: RestoringItemCard(
                          left: SizedBox(
                            width: 32,
                            height: 32,
                            child: RoundedContainer(
                              padding: const EdgeInsets.all(0),
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .buttonBackSecondary,
                              child: Center(
                                child: SvgPicture.asset(
                                  Assets.svg.node,
                                  width: 16,
                                  height: 16,
                                ),
                              ),
                            ),
                          ),
                          right: SizedBox(
                            width: 20,
                            height: 20,
                            child: _getIconForState(state),
                          ),
                          title: "Connecting to server",
                        ),
                      );
                    }),
                    const SizedBox(
                      height: 12,
                    ),
                    Consumer(builder: (_, ref, __) {
                      final state = ref.watch(fusionProgressUIStateProvider
                          .select((value) => value.outputs));
                      return RoundedContainer(
                        padding: EdgeInsets.zero,
                        color:
                            Theme.of(context).extension<StackColors>()!.popupBG,
                        borderColor: Theme.of(context)
                            .extension<StackColors>()!
                            .background,
                        child: RestoringItemCard(
                          left: SizedBox(
                            width: 32,
                            height: 32,
                            child: RoundedContainer(
                              padding: const EdgeInsets.all(0),
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .buttonBackSecondary,
                              child: Center(
                                child: SvgPicture.asset(
                                  Assets.svg.upFromLine,
                                  width: 30,
                                  height: 30,
                                ),
                              ),
                            ),
                          ),
                          right: SizedBox(
                            width: 20,
                            height: 20,
                            child: _getIconForState(state),
                          ),
                          title: "Allocating outputs",
                        ),
                      );
                    }),
                    const SizedBox(
                      height: 12,
                    ),
                    Consumer(builder: (_, ref, __) {
                      final state = ref.watch(fusionProgressUIStateProvider
                          .select((value) => value.peers));
                      return RoundedContainer(
                        padding: EdgeInsets.zero,
                        color:
                            Theme.of(context).extension<StackColors>()!.popupBG,
                        borderColor: Theme.of(context)
                            .extension<StackColors>()!
                            .background,
                        child: RestoringItemCard(
                          left: SizedBox(
                            width: 32,
                            height: 32,
                            child: RoundedContainer(
                              padding: const EdgeInsets.all(0),
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .buttonBackSecondary,
                              child: Center(
                                child: SvgPicture.asset(
                                  Assets.svg.peers,
                                  width: 30,
                                  height: 30,
                                ),
                              ),
                            ),
                          ),
                          right: SizedBox(
                            width: 20,
                            height: 20,
                            child: _getIconForState(state),
                          ),
                          title: "Waiting for peers",
                        ),
                      );
                    }),
                    const SizedBox(
                      height: 12,
                    ),
                    Consumer(builder: (_, ref, __) {
                      final state = ref.watch(fusionProgressUIStateProvider
                          .select((value) => value.fusing));
                      return RoundedContainer(
                        padding: EdgeInsets.zero,
                        color:
                            Theme.of(context).extension<StackColors>()!.popupBG,
                        borderColor: Theme.of(context)
                            .extension<StackColors>()!
                            .background,
                        child: RestoringItemCard(
                          left: SizedBox(
                            width: 32,
                            height: 32,
                            child: RoundedContainer(
                              padding: const EdgeInsets.all(0),
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .buttonBackSecondary,
                              child: Center(
                                child: SvgPicture.asset(
                                  Assets.svg.fusing,
                                  width: 30,
                                  height: 30,
                                ),
                              ),
                            ),
                          ),
                          right: SizedBox(
                            width: 20,
                            height: 20,
                            child: _getIconForState(state),
                          ),
                          title: "Fusing",
                        ),
                      );
                    }),
                    const SizedBox(
                      height: 12,
                    ),
                    Consumer(builder: (_, ref, __) {
                      final state = ref.watch(fusionProgressUIStateProvider
                          .select((value) => value.complete));
                      return RoundedContainer(
                        padding: EdgeInsets.zero,
                        color:
                            Theme.of(context).extension<StackColors>()!.popupBG,
                        borderColor:
                            Theme.of(context).extension<StackColors>()!.shadow,
                        child: RestoringItemCard(
                          left: SizedBox(
                            width: 32,
                            height: 32,
                            child: RoundedContainer(
                              padding: const EdgeInsets.all(0),
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .buttonBackSecondary,
                              child: Center(
                                child: SvgPicture.asset(
                                  Assets.svg.checkCircle,
                                  width: 16,
                                  height: 16,
                                ),
                              ),
                            ),
                          ),
                          right: SizedBox(
                            width: 20,
                            height: 20,
                            child: _getIconForState(state),
                          ),
                          title: "Complete",
                        ),
                      );
                    }),
                    const SizedBox(
                      height: 12,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SecondaryButton(
                          width: 248,
                          buttonHeight: ButtonHeight.m,
                          enabled: true,
                          label: "Cancel",
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
