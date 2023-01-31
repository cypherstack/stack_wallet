import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/models/paynym/paynym_account.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_bot.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';

class PaynymQrPopup extends StatelessWidget {
  const PaynymQrPopup({
    Key? key,
    required this.paynymAccount,
  }) : super(key: key);

  final PaynymAccount paynymAccount;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return DesktopDialog(
      maxWidth: isDesktop ? 580 : MediaQuery.of(context).size.width - 32,
      maxHeight: double.infinity,
      child: Column(
        children: [
          if (isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "Address details",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
          Padding(
            padding: EdgeInsets.only(
              left: isDesktop ? 32 : 24,
              top: isDesktop ? 16 : 24,
              right: 24,
              bottom: 16,
            ),
            child: Row(
              children: [
                PayNymBot(
                  paymentCodeString: paynymAccount.codes.first.code,
                  size: isDesktop ? 56 : 32,
                ),
                const SizedBox(
                  width: 12,
                ),
                Text(
                  paynymAccount.nymName,
                  style: isDesktop
                      ? STextStyles.w500_24(context)
                      : STextStyles.w600_12(context),
                ),
              ],
            ),
          ),
          if (!isDesktop)
            Container(
              color:
                  Theme.of(context).extension<StackColors>()!.backgroundAppBar,
              height: 1,
            ),
          Padding(
            padding: const EdgeInsets.only(
              left: 24,
              top: 16,
              right: 24,
              bottom: 24,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 107),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isDesktop ? "PayNym address" : "Your PayNym address",
                          style: isDesktop
                              ? STextStyles.desktopTextSmall(context).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textSubtitle1,
                                )
                              : STextStyles.infoSmall(context),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Text(
                          paynymAccount.codes.first.code,
                          style: isDesktop
                              ? STextStyles.desktopTextSmall(context)
                              : STextStyles.infoSmall(context).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textDark,
                                ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        CustomTextButton(
                          text: "Copy",
                          textSize: isDesktop ? 18 : 10,
                          onTap: () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: paynymAccount.codes.first.code,
                              ),
                            );
                            unawaited(
                              showFloatingFlushBar(
                                type: FlushBarType.info,
                                message: "Copied to clipboard",
                                iconAsset: Assets.svg.copy,
                                context: context,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                QrImage(
                  padding: const EdgeInsets.all(0),
                  size: 107,
                  data: paynymAccount.codes.first.code,
                  foregroundColor:
                      Theme.of(context).extension<StackColors>()!.textDark,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
