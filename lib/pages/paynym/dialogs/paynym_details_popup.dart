import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/models/paynym/paynym_account_lite.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_bot.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/paynym_follow_toggle_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

class PaynymDetailsPopup extends StatefulWidget {
  const PaynymDetailsPopup({
    Key? key,
    required this.walletId,
    required this.accountLite,
  }) : super(key: key);

  final String walletId;
  final PaynymAccountLite accountLite;

  @override
  State<PaynymDetailsPopup> createState() => _PaynymDetailsPopupState();
}

class _PaynymDetailsPopupState extends State<PaynymDetailsPopup> {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    PayNymBot(
                      paymentCodeString: widget.accountLite.code,
                      size: 32,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      widget.accountLite.nymName,
                      style: STextStyles.w600_12(context),
                    ),
                  ],
                ),
                PrimaryButton(
                  label: "Connect",
                  buttonHeight: ButtonHeight.l,
                  icon: SvgPicture.asset(
                    Assets.svg.circlePlusFilled,
                    width: 10,
                    height: 10,
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .buttonTextPrimary,
                  ),
                  iconSpacing: 4,
                  width: 86,
                  onPressed: () {
                    // todo notification tx
                  },
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
              bottom: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 86),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "PayNym address",
                          style: STextStyles.infoSmall(context),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Text(
                          widget.accountLite.code,
                          style: STextStyles.infoSmall(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
                        ),
                        const SizedBox(
                          height: 6,
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
                  size: 86,
                  data: widget.accountLite.code,
                  foregroundColor:
                      Theme.of(context).extension<StackColors>()!.textDark,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: 24,
            ),
            child: Row(
              children: [
                Expanded(
                  child: PaynymFollowToggleButton(
                    walletId: widget.walletId,
                    paymentCodeStringToFollow: widget.accountLite.code,
                    style: PaynymFollowToggleButtonStyle.detailsPopup,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: SecondaryButton(
                    label: "Copy",
                    buttonHeight: ButtonHeight.l,
                    icon: SvgPicture.asset(
                      Assets.svg.copy,
                      width: 10,
                      height: 10,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .buttonTextSecondary,
                    ),
                    iconSpacing: 4,
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(
                          text: widget.accountLite.code,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
