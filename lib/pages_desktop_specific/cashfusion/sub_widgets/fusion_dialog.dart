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
                    onPressedOverride: () => Navigator.of(context).pop(true),
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
                    const SizedBox(height: 20),
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
