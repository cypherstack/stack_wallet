import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../pages/churning/churn_error_dialog.dart';
import '../../../providers/churning/churning_service_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/churning/churn_progress_item.dart';
import '../../../widgets/desktop/desktop_dialog.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/rounded_container.dart';
import '../../../widgets/rounded_white_container.dart';

class ChurnDialogView extends ConsumerStatefulWidget {
  const ChurnDialogView({
    super.key,
    required this.walletId,
  });

  final String walletId;

  @override
  ConsumerState<ChurnDialogView> createState() => _ChurnDialogViewState();
}

class _ChurnDialogViewState extends ConsumerState<ChurnDialogView> {
  Future<bool> _requestAndProcessCancel() async {
    final bool? shouldCancel = await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DesktopDialog(
        maxWidth: 580,
        maxHeight: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 32,
            right: 0,
            top: 0,
            bottom: 32,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Cancel churning?",
                    style: STextStyles.desktopH3(context),
                  ),
                  DesktopDialogCloseButton(
                    onPressedOverride: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 0,
                  right: 32,
                  top: 0,
                  bottom: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Do you really want to cancel the churning process?",
                      style: STextStyles.smallMed14(context),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: "No",
                            buttonHeight: ButtonHeight.l,
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: PrimaryButton(
                            label: "Yes",
                            buttonHeight: ButtonHeight.l,
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                          ),
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

    if (shouldCancel == true && mounted) {
      ref.read(pChurningService(widget.walletId)).stopChurning();

      await WakelockPlus.disable();

      return true;
    } else {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(pChurningService(widget.walletId)).churn();
    });
  }

  @override
  dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool _succeeded = ref.watch(
      pChurningService(widget.walletId).select((s) => s.done),
    );

    final int _roundsCompleted = ref.watch(
      pChurningService(widget.walletId).select((s) => s.roundsCompleted),
    );

    if (!Platform.isLinux) {
      WakelockPlus.enable();
    }

    ref.listen(
      pChurningService(widget.walletId).select((s) => s.lastSeenError),
      (p, n) {
        if (!ref.read(pChurningService(widget.walletId)).ignoreErrors &&
            n != null) {
          if (context.mounted) {
            showDialog<void>(
              context: context,
              builder: (context) => ChurnErrorDialog(
                error: n.toString(),
                walletId: widget.walletId,
              ),
            );
          }
        }
      },
    );

    return DesktopDialog(
      maxHeight: 600,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "Churn progress",
                    style: STextStyles.desktopH2(context),
                  ),
                ),
                DesktopDialogCloseButton(
                  onPressedOverride: () async {
                    if (_succeeded) {
                      Navigator.of(context).pop();
                    } else {
                      if (await _requestAndProcessCancel()) {
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    }
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 32,
                right: 32,
                bottom: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _roundsCompleted > 0
                      ? RoundedWhiteContainer(
                          child: Text(
                            "Churn rounds completed: $_roundsCompleted",
                            style: STextStyles.w500_14(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textSubtitle1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : RoundedContainer(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .snackBarBackError,
                          child: Text(
                            "Do not close this window. If you exit, "
                            "the process will be canceled.",
                            style: STextStyles.smallMed14(context).copyWith(
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
                  ProgressItem(
                    iconAsset: Assets.svg.peers,
                    label: "Waiting for balance to unlock",
                    status: ref.watch(
                      pChurningService(widget.walletId)
                          .select((s) => s.waitingForUnlockedBalance),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  ProgressItem(
                    iconAsset: Assets.svg.fusing,
                    label: "Creating churn transaction",
                    status: ref.watch(
                      pChurningService(widget.walletId)
                          .select((s) => s.makingChurnTransaction),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  ProgressItem(
                    iconAsset: Assets.svg.checkCircle,
                    label: "Complete",
                    status: ref.watch(
                      pChurningService(widget.walletId)
                          .select((s) => s.completedStatus),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Row(
                    children: [
                      if (_succeeded)
                        Expanded(
                          child: PrimaryButton(
                            buttonHeight: ButtonHeight.m,
                            label: "Churn again",
                            onPressed: ref
                                .read(pChurningService(widget.walletId))
                                .churn,
                          ),
                        ),
                      if (_succeeded)
                        const SizedBox(
                          width: 16,
                        ),
                      if (!_succeeded) const Spacer(),
                      if (!_succeeded)
                        const SizedBox(
                          width: 16,
                        ),
                      Expanded(
                        child: SecondaryButton(
                          buttonHeight: ButtonHeight.m,
                          enabled: true,
                          label: _succeeded ? "Done" : "Cancel",
                          onPressed: () async {
                            if (_succeeded) {
                              Navigator.of(context).pop();
                            } else {
                              if (await _requestAndProcessCancel()) {
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
