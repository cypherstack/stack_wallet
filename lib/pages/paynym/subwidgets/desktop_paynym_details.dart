import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/models/paynym/paynym_account_lite.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/paynym/dialogs/confirm_paynym_connect_dialog.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_bot.dart';
import 'package:stackwallet/pages/send_view/confirm_transaction_view.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/coins/coin_paynym_extension.dart';
import 'package:stackwallet/services/coins/dogecoin/dogecoin_wallet.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/custom_buttons/paynym_follow_toggle_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class DesktopPaynymDetails extends ConsumerStatefulWidget {
  const DesktopPaynymDetails({
    Key? key,
    required this.walletId,
    required this.accountLite,
  }) : super(key: key);

  final String walletId;
  final PaynymAccountLite accountLite;

  @override
  ConsumerState<DesktopPaynymDetails> createState() =>
      _PaynymDetailsPopupState();
}

class _PaynymDetailsPopupState extends ConsumerState<DesktopPaynymDetails> {
  bool _showInsufficientFundsInfo = false;

  Future<void> _onConnectPressed() async {
    bool canPop = false;
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => WillPopScope(
          onWillPop: () async => canPop,
          child: const LoadingIndicator(
            width: 200,
          ),
        ),
      ),
    );

    final wallet = ref
        .read(walletsChangeNotifierProvider)
        .getManager(widget.walletId)
        .wallet as DogecoinWallet;

    // sanity check to prevent second notification tx
    if (wallet.hasConnectedConfirmed(widget.accountLite.code)) {
      canPop = true;
      Navigator.of(context, rootNavigator: true).pop();
      // TODO show info popup
      return;
    } else if (wallet.hasConnected(widget.accountLite.code)) {
      canPop = true;
      Navigator.of(context, rootNavigator: true).pop();
      // TODO show info popup
      return;
    }

    final rates = await wallet.fees;

    Map<String, dynamic> preparedTx;

    try {
      preparedTx = await wallet.buildNotificationTx(
        selectedTxFeeRate: rates.medium,
        targetPaymentCodeString: widget.accountLite.code,
      );
    } on InsufficientBalanceException catch (e) {
      if (mounted) {
        canPop = true;
        Navigator.of(context, rootNavigator: true).pop();
      }
      setState(() {
        _showInsufficientFundsInfo = true;
      });
      return;
    }

    if (mounted) {
      // We have enough balance and prepared tx should be good to go.

      canPop = true;
      // close loading
      Navigator.of(context, rootNavigator: true).pop();

      // show info pop up
      await showDialog<void>(
        context: context,
        builder: (context) => ConfirmPaynymConnectDialog(
          nymName: widget.accountLite.nymName,
          onConfirmPressed: () {
            //
            print("CONFIRM NOTIF TX: $preparedTx");
            Navigator.of(context, rootNavigator: true).pop();
            unawaited(
              showDialog(
                context: context,
                builder: (context) => DesktopDialog(
                  maxHeight: double.infinity,
                  maxWidth: 580,
                  child: ConfirmTransactionView(
                    walletId: wallet.walletId,
                    isPaynymNotificationTransaction: true,
                    transactionInfo: {
                      "hex": preparedTx["hex"],
                      "address": preparedTx["recipientPaynym"],
                      "recipientAmt": preparedTx["amount"],
                      "fee": preparedTx["fee"],
                      "vSize": preparedTx["vSize"],
                      "note": "PayNym connect"
                    },
                    onSuccessInsteadOfRouteOnSuccess: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      Navigator.of(context, rootNavigator: true).pop();
                      unawaited(
                        showFloatingFlushBar(
                          type: FlushBarType.success,
                          message:
                              "Connection initiated to ${widget.accountLite.nymName}",
                          iconAsset: Assets.svg.copy,
                          context: context,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          amount: (preparedTx["amount"] as int) + (preparedTx["fee"] as int),
          coin: wallet.coin,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      style: STextStyles.desktopTextSmall(context),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: "Connect",
                        buttonHeight: ButtonHeight.s,
                        icon: SvgPicture.asset(
                          Assets.svg.circlePlusFilled,
                          width: 16,
                          height: 16,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .buttonTextPrimary,
                        ),
                        iconSpacing: 6,
                        onPressed: _onConnectPressed,
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      child: PaynymFollowToggleButton(
                        walletId: widget.walletId,
                        paymentCodeStringToFollow: widget.accountLite.code,
                        style: PaynymFollowToggleButtonStyle.detailsDesktop,
                      ),
                    ),
                  ],
                ),
                if (_showInsufficientFundsInfo)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 24,
                      ),
                      RoundedContainer(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .warningBackground,
                        child: Text(
                          "Adding a PayNym to your contacts requires a one-time "
                          "transaction fee for creating the record on the "
                          "blockchain. Please deposit more "
                          "${ref.read(walletsChangeNotifierProvider).getManager(widget.walletId).wallet.coin.ticker} "
                          "into your wallet and try again.",
                          style: STextStyles.desktopTextExtraExtraSmall(context)
                              .copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .warningForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            color: Theme.of(context).extension<StackColors>()!.backgroundAppBar,
            height: 1,
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PayNym address",
                  style: STextStyles.desktopTextExtraExtraSmall(context),
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 100),
                        child: Text(
                          widget.accountLite.code,
                          style: STextStyles.desktopTextExtraExtraSmall(context)
                              .copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    QrImage(
                      padding: const EdgeInsets.all(0),
                      size: 100,
                      data: widget.accountLite.code,
                      foregroundColor:
                          Theme.of(context).extension<StackColors>()!.textDark,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                BlueTextButton(
                  text: "Copy",
                  onTap: () async {
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
