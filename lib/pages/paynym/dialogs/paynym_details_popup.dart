import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/exceptions/wallet/insufficient_balance_exception.dart';
import 'package:stackwallet/models/paynym/paynym_account_lite.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/paynym/dialogs/confirm_paynym_connect_dialog.dart';
import 'package:stackwallet/pages/paynym/paynym_home_view.dart';
import 'package:stackwallet/pages/paynym/subwidgets/paynym_bot.dart';
import 'package:stackwallet/pages/send_view/confirm_transaction_view.dart';
import 'package:stackwallet/pages/send_view/send_view.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/services/mixins/paynym_wallet_interface.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/paynym_follow_toggle_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:tuple/tuple.dart';

class PaynymDetailsPopup extends ConsumerStatefulWidget {
  const PaynymDetailsPopup({
    Key? key,
    required this.walletId,
    required this.accountLite,
  }) : super(key: key);

  final String walletId;
  final PaynymAccountLite accountLite;

  @override
  ConsumerState<PaynymDetailsPopup> createState() => _PaynymDetailsPopupState();
}

class _PaynymDetailsPopupState extends ConsumerState<PaynymDetailsPopup> {
  bool _showInsufficientFundsInfo = false;

  Future<void> _onSend() async {
    final manager =
        ref.read(walletsChangeNotifierProvider).getManager(widget.walletId);
    await Navigator.of(context).pushNamed(
      SendView.routeName,
      arguments: Tuple3(
        manager.walletId,
        manager.coin,
        widget.accountLite,
      ),
    );
  }

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

    final manager =
        ref.read(walletsChangeNotifierProvider).getManager(widget.walletId);

    final wallet = manager.wallet as PaynymWalletInterface;

    if (await wallet.hasConnected(widget.accountLite.code)) {
      canPop = true;
      Navigator.of(context).pop();
      // TODO show info popup
      return;
    }

    final rates = await manager.fees;

    Map<String, dynamic> preparedTx;

    try {
      preparedTx = await wallet.prepareNotificationTx(
        selectedTxFeeRate: rates.medium,
        targetPaymentCodeString: widget.accountLite.code,
      );
    } on InsufficientBalanceException catch (_) {
      if (mounted) {
        canPop = true;
        Navigator.of(context).pop();
      }
      setState(() {
        _showInsufficientFundsInfo = true;
      });
      return;
    } catch (e) {
      if (mounted) {
        canPop = true;
        Navigator.of(context).pop();
      }

      await showDialog<void>(
        context: context,
        builder: (context) => StackOkDialog(
          title: "Error",
          message: e.toString(),
        ),
      );
      return;
    }

    if (mounted) {
      // We have enough balance and prepared tx should be good to go.

      canPop = true;
      // close loading
      Navigator.of(context).pop();

      // Close details
      Navigator.of(context).pop();

      // show info pop up
      await showDialog<void>(
        context: context,
        builder: (context) => ConfirmPaynymConnectDialog(
          nymName: widget.accountLite.nymName,
          locale: ref.read(localeServiceChangeNotifierProvider).locale,
          onConfirmPressed: () {
            //
            print("CONFIRM NOTIF TX: $preparedTx");

            Navigator.of(context).push(
              RouteGenerator.getRoute(
                builder: (_) => ConfirmTransactionView(
                  walletId: manager.walletId,
                  routeOnSuccessName: PaynymHomeView.routeName,
                  isPaynymNotificationTransaction: true,
                  transactionInfo: {
                    "hex": preparedTx["hex"],
                    "address": preparedTx["recipientPaynym"],
                    "recipientAmt": preparedTx["amount"],
                    "fee": preparedTx["fee"],
                    "vSize": preparedTx["vSize"],
                    "note": "PayNym connect"
                  },
                ),
              ),
            );
          },
          amount: (preparedTx["amount"] as Amount) +
              (preparedTx["fee"] as int).toAmountAsRaw(
                fractionDigits: manager.coin.decimals,
              ),
          coin: manager.coin,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId)));

    final wallet = manager.wallet as PaynymWalletInterface;

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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        PayNymBot(
                          paymentCodeString: widget.accountLite.code,
                          size: 36,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.accountLite.nymName,
                              style: STextStyles.w600_14(context),
                            ),
                            FutureBuilder(
                              future:
                                  wallet.hasConnected(widget.accountLite.code),
                              builder: (context, AsyncSnapshot<bool> snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.done &&
                                    snapshot.data == true) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        height: 2,
                                      ),
                                      Text(
                                        "Connected",
                                        style: STextStyles.w500_12(context)
                                            .copyWith(
                                          color: Theme.of(context)
                                              .extension<StackColors>()!
                                              .accentColorGreen,
                                        ),
                                      )
                                    ],
                                  );
                                } else {
                                  return Container();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    FutureBuilder(
                      future: wallet.hasConnected(widget.accountLite.code),
                      builder: (context, AsyncSnapshot<bool> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          if (snapshot.data!) {
                            return PrimaryButton(
                              label: "Send",
                              buttonHeight: ButtonHeight.xl,
                              icon: SvgPicture.asset(
                                Assets.svg.circleArrowUpRight,
                                width: 14,
                                height: 14,
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .buttonTextPrimary,
                              ),
                              iconSpacing: 8,
                              width: 100,
                              onPressed: _onSend,
                            );
                          } else {
                            return PrimaryButton(
                              label: "Connect",
                              buttonHeight: ButtonHeight.xl,
                              icon: SvgPicture.asset(
                                Assets.svg.circlePlusFilled,
                                width: 13,
                                height: 13,
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .buttonTextPrimary,
                              ),
                              iconSpacing: 8,
                              width: 128,
                              onPressed: _onConnectPressed,
                            );
                          }
                        } else {
                          return const SizedBox(
                            height: 32,
                            child: LoadingIndicator(),
                          );
                        }
                      },
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
                          style: STextStyles.infoSmall(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .warningForeground,
                            fontSize: 12,
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
                          style: STextStyles.infoSmall(context).copyWith(
                            fontSize: 12,
                          ),
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
                            fontSize: 12,
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
                  size: 100,
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
                    buttonHeight: ButtonHeight.xl,
                    iconSpacing: 8,
                    icon: SvgPicture.asset(
                      Assets.svg.copy,
                      width: 12,
                      height: 12,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .buttonTextSecondary,
                    ),
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
