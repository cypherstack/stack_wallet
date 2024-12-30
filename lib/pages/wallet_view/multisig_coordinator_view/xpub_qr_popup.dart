import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../notifications/show_flush_bar.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/assets.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../widgets/desktop/desktop_dialog.dart';
import '../../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/detail_item.dart';
import '../../../../widgets/qr.dart';
import '../../../../widgets/rounded_white_container.dart';

class XpubQrPopup extends StatelessWidget {
  const XpubQrPopup({
    super.key,
    required this.xpub,
  });

  final String xpub;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: xpub),
    );
    if (context.mounted) {
      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.info,
          message: "Copied to clipboard",
          iconAsset: Assets.svg.copy,
          context: context,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return DesktopDialog(
      maxWidth: isDesktop ? 600 : MediaQuery.of(context).size.width - 32,
      maxHeight: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  "Your xPub",
                  style: STextStyles.desktopH2(context),
                ),
              ),
              DesktopDialogCloseButton(
                onPressedOverride:
                    Navigator.of(context, rootNavigator: true).pop,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: isDesktop ? 12 : 16,
                ),
                DetailItem(
                  title: "Derivation path",
                  detail: "m/48'/0'/0'/2'", // TODO: Get actual derivation path
                  horizontal: true,
                  borderColor: isDesktop
                      ? Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldDefaultBG
                      : null,
                ),
                SizedBox(
                  height: isDesktop ? 12 : 16,
                ),
                QR(
                  data: xpub,
                  size:
                      isDesktop ? 256 : MediaQuery.of(context).size.width / 1.5,
                ),
                SizedBox(
                  height: isDesktop ? 12 : 16,
                ),
                RoundedWhiteContainer(
                  borderColor: isDesktop
                      ? Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldDefaultBG
                      : null,
                  child: SelectableText(
                    xpub,
                    style: STextStyles.w500_14(context),
                  ),
                ),
                SizedBox(
                  height: isDesktop ? 12 : 16,
                ),
                Row(
                  children: [
                    if (isDesktop) const Spacer(),
                    if (isDesktop)
                      const SizedBox(
                        width: 16,
                      ),
                    Expanded(
                      child: PrimaryButton(
                        label: "Copy",
                        onPressed: () => _copy(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
