import 'package:flutter/material.dart';
import 'package:stackwallet/pages_desktop_specific/cashfusion/sub_widgets/fusion_progress.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

enum CashFusionStatus { waiting, running, success, failed }

class CashFusionState {
  final CashFusionStatus status;
  final String? info;

  CashFusionState({required this.status, this.info});
}

class FusionDialog extends StatelessWidget {
  const FusionDialog({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

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
                    FusionProgress(
                      walletId: walletId,
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
