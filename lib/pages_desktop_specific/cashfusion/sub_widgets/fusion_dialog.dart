import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages_desktop_specific/cashfusion/sub_widgets/fusion_progress.dart';
import 'package:stackwallet/providers/cash_fusion/fusion_progress_ui_state_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/show_loading.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/wallets/wallet/mixins/cash_fusion.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

enum CashFusionStatus { waiting, running, success, failed }

class CashFusionState {
  final CashFusionStatus status;
  final String? info;

  CashFusionState({required this.status, this.info});
}

class FusionDialogView extends ConsumerStatefulWidget {
  const FusionDialogView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  ConsumerState<FusionDialogView> createState() => _FusionDialogViewState();
}

class _FusionDialogViewState extends ConsumerState<FusionDialogView> {
  Future<bool> _requestAndProcessCancel() async {
    if (!ref.read(fusionProgressUIStateProvider(widget.walletId)).running) {
      return true;
    } else {
      bool? shouldCancel = await showDialog<bool?>(
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
                      "Cancel fusion?",
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
                        "Do you really want to cancel the fusion process?",
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
        final fusionWallet =
            ref.read(pWallets).getWallet(widget.walletId) as CashFusion;

        await showLoading(
          whileFuture: Future.wait([
            fusionWallet.stop(),
            Future<void>.delayed(const Duration(seconds: 2)),
          ]),
          context: context,
          isDesktop: true,
          message: "Stopping fusion",
        );

        return true;
      } else {
        return false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool _succeeded =
        ref.watch(fusionProgressUIStateProvider(widget.walletId)).succeeded;

    final bool _failed =
        ref.watch(fusionProgressUIStateProvider(widget.walletId)).failed;

    final int _fusionRoundsCompleted = ref
        .watch(fusionProgressUIStateProvider(widget.walletId))
        .fusionRoundsCompleted;

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
                    "Fusion progress",
                    style: STextStyles.desktopH2(context),
                  ),
                ),
                DesktopDialogCloseButton(
                  onPressedOverride: () async {
                    if (await _requestAndProcessCancel()) {
                      if (mounted) {
                        Navigator.of(context).pop();
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
                  _fusionRoundsCompleted > 0
                      ? RoundedWhiteContainer(
                          child: Text(
                            "Fusion rounds completed: $_fusionRoundsCompleted",
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
                  FusionProgress(
                    walletId: widget.walletId,
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
                            label: "Fuse again",
                            onPressed: _fuseAgain,
                          ),
                        ),
                      if (_succeeded)
                        const SizedBox(
                          width: 16,
                        ),
                      if (_failed)
                        Expanded(
                          child: PrimaryButton(
                            buttonHeight: ButtonHeight.m,
                            label: "Try again",
                            onPressed: _fuseAgain,
                          ),
                        ),
                      if (_failed)
                        const SizedBox(
                          width: 16,
                        ),
                      if (!_succeeded && !_failed) const Spacer(),
                      if (!_succeeded && !_failed)
                        const SizedBox(
                          width: 16,
                        ),
                      Expanded(
                        child: SecondaryButton(
                          buttonHeight: ButtonHeight.m,
                          enabled: true,
                          label: "Cancel",
                          onPressed: () async {
                            if (await _requestAndProcessCancel()) {
                              if (mounted) {
                                Navigator.of(context).pop();
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

  /// Fuse again.
  void _fuseAgain() async {
    final fusionWallet =
        ref.read(pWallets).getWallet(widget.walletId) as CashFusion;

    final fusionInfo = ref.read(prefsChangeNotifierProvider).fusionServerInfo;

    try {
      fusionWallet.uiState = ref.read(
        fusionProgressUIStateProvider(widget.walletId),
      );
    } catch (e) {
      if (!e.toString().contains(
          "FusionProgressUIState was already set for ${widget.walletId}")) {
        rethrow;
      }
    }

    unawaited(fusionWallet.fuse(fusionInfo: fusionInfo));
  }
}
