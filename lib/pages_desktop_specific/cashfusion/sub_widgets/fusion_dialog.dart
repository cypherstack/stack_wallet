import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages_desktop_specific/cashfusion/sub_widgets/fusion_progress.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/mixins/fusion_wallet_interface.dart';
import 'package:stackwallet/utilities/show_loading.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

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
    final shouldCancel = await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StackDialog(
        title: "Cancel fusion?",
        leftButton: SecondaryButton(
          label: "No",
          buttonHeight: ButtonHeight.l,
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        rightButton: PrimaryButton(
          label: "Yes",
          buttonHeight: ButtonHeight.l,
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ),
    );

    if (shouldCancel == true && mounted) {
      final fusionWallet = ref
          .read(walletsChangeNotifierProvider)
          .getManager(widget.walletId)
          .wallet as FusionWalletInterface;

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

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  children: [
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SecondaryButton(
                          width: 248,
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
