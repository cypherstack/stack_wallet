import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/models/paynym/paynym_account.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/paynym/paynym_home_view.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';

class PaynymQrPopup extends StatelessWidget {
  const PaynymQrPopup({
    Key? key,
    required this.paynymAccount,
  }) : super(key: key);

  final PaynymAccount paynymAccount;

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxWidth: MediaQuery.of(context).size.width - 32,
      maxHeight: double.infinity,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 24,
              top: 24,
              right: 24,
              bottom: 16,
            ),
            child: Row(
              children: [
                PayNymBot(
                  paymentCodeString: paynymAccount.codes.first.code,
                  size: 32,
                ),
                const SizedBox(
                  width: 12,
                ),
                Text(
                  paynymAccount.nymName,
                  style: STextStyles.w600_12(context),
                ),
              ],
            ),
          ),
          Container(
            color: Theme.of(context).extension<StackColors>()!.backgroundAppBar,
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
                          "Your PayNym address",
                          style: STextStyles.infoSmall(context),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Text(
                          paynymAccount.codes.first.code,
                          style: STextStyles.infoSmall(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        BlueTextButton(
                          text: "Copy",
                          textSize: 10,
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
