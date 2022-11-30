import 'dart:async';

import 'package:epicmobile/models/exchange/response_objects/trade.dart';
import 'package:epicmobile/models/trade_wallet_lookup.dart';
import 'package:epicmobile/pages/pinpad_views/lock_screen_view.dart';
import 'package:epicmobile/pages/send_view/sub_widgets/sending_transaction_dialog.dart';
import 'package:epicmobile/pages/wallet_view/wallet_view.dart';
import 'package:epicmobile/providers/exchange/trade_sent_from_stack_lookup_provider.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/route_generator.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/format.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/rounded_container.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
import 'package:epicmobile/widgets/stack_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class ConfirmChangeNowSendView extends ConsumerStatefulWidget {
  const ConfirmChangeNowSendView({
    Key? key,
    required this.transactionInfo,
    required this.walletId,
    this.routeOnSuccessName = WalletView.routeName,
    required this.trade,
    this.shouldSendPublicFiroFunds,
  }) : super(key: key);

  static const String routeName = "/confirmChangeNowSend";

  final Map<String, dynamic> transactionInfo;
  final String walletId;
  final String routeOnSuccessName;
  final Trade trade;
  final bool? shouldSendPublicFiroFunds;

  @override
  ConsumerState<ConfirmChangeNowSendView> createState() =>
      _ConfirmChangeNowSendViewState();
}

class _ConfirmChangeNowSendViewState
    extends ConsumerState<ConfirmChangeNowSendView> {
  late final Map<String, dynamic> transactionInfo;
  late final String walletId;
  late final String routeOnSuccessName;
  late final Trade trade;

  Future<void> _attemptSend(BuildContext context) async {
    unawaited(showDialog<void>(
      context: context,
      useSafeArea: false,
      barrierDismissible: false,
      builder: (context) {
        return const SendingTransactionDialog();
      },
    ));

    final String note = transactionInfo["note"] as String? ?? "";
    final manager =
        ref.read(walletsChangeNotifierProvider).getManager(walletId);

    try {
      late final String txid;

      txid = await manager.confirmSend(txData: transactionInfo);

      unawaited(manager.refresh());

      // save note
      await ref
          .read(notesServiceChangeNotifierProvider(walletId))
          .editOrAddNote(txid: txid, note: note);

      await ref.read(tradeSentFromStackLookupProvider).save(
            tradeWalletLookup: TradeWalletLookup(
              uuid: const Uuid().v1(),
              txid: txid,
              tradeId: trade.tradeId,
              walletIds: [walletId],
            ),
          );

      // pop back to wallet
      if (mounted) {
        Navigator.of(context).popUntil(ModalRoute.withName(routeOnSuccessName));
      }
    } catch (e) {
      // pop sending dialog
      Navigator.of(context).pop();

      await showDialog<dynamic>(
        context: context,
        useSafeArea: false,
        barrierDismissible: true,
        builder: (context) {
          return StackDialog(
            title: "Broadcast transaction failed",
            message: e.toString(),
            rightButton: TextButton(
              style: Theme.of(context)
                  .extension<StackColors>()!
                  .getSecondaryEnabledButtonColor(context),
              child: Text(
                "Ok",
                style: STextStyles.button(context).copyWith(
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .buttonTextSecondary,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          );
        },
      );
    }
  }

  @override
  void initState() {
    transactionInfo = widget.transactionInfo;
    walletId = widget.walletId;
    routeOnSuccessName = widget.routeOnSuccessName;
    trade = widget.trade;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final managerProvider = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManagerProvider(walletId)));
    return Scaffold(
      backgroundColor: Theme.of(context).extension<StackColors>()!.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        leading: AppBarBackButton(
          onPressed: () async {
            // if (FocusScope.of(context).hasFocus) {
            //   FocusScope.of(context).unfocus();
            //   await Future<void>.delayed(Duration(milliseconds: 50));
            // }
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Confirm transaction",
          style: STextStyles.navBarTitle(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (builderContext, constraints) {
          return Padding(
            padding: const EdgeInsets.only(
              left: 12,
              top: 12,
              right: 12,
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Send ${ref.watch(managerProvider.select((value) => value.coin)).ticker}",
                          style: STextStyles.pageTitleH1(context),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedWhiteContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Send from",
                                style: STextStyles.smallMed12(context),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                ref
                                    .watch(walletsChangeNotifierProvider)
                                    .getManager(walletId)
                                    .walletName,
                                style: STextStyles.itemSubtitle12(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedWhiteContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "${trade.exchangeName} address",
                                style: STextStyles.smallMed12(context),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                "${transactionInfo["address"] ?? "ERROR"}",
                                style: STextStyles.itemSubtitle12(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedWhiteContainer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Amount",
                                style: STextStyles.smallMed12(context),
                              ),
                              Text(
                                "${Format.satoshiAmountToPrettyString(
                                  transactionInfo["recipientAmt"] as int,
                                  ref.watch(
                                    localeServiceChangeNotifierProvider
                                        .select((value) => value.locale),
                                  ),
                                )} ${ref.watch(
                                      managerProvider
                                          .select((value) => value.coin),
                                    ).ticker}",
                                style: STextStyles.itemSubtitle12(context),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedWhiteContainer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Transaction fee",
                                style: STextStyles.smallMed12(context),
                              ),
                              Text(
                                "${Format.satoshiAmountToPrettyString(
                                  transactionInfo["fee"] as int,
                                  ref.watch(
                                    localeServiceChangeNotifierProvider
                                        .select((value) => value.locale),
                                  ),
                                )} ${ref.watch(
                                      managerProvider
                                          .select((value) => value.coin),
                                    ).ticker}",
                                style: STextStyles.itemSubtitle12(context),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedWhiteContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Note",
                                style: STextStyles.smallMed12(context),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                transactionInfo["note"] as String? ?? "",
                                style: STextStyles.itemSubtitle12(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedWhiteContainer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Trade ID",
                                style: STextStyles.smallMed12(context),
                              ),
                              Text(
                                trade.tradeId,
                                style: STextStyles.itemSubtitle12(context),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedContainer(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .snackBarBackSuccess,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total amount",
                                style:
                                    STextStyles.titleBold12(context).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textConfirmTotalAmount,
                                ),
                              ),
                              Text(
                                "${Format.satoshiAmountToPrettyString(
                                  (transactionInfo["fee"] as int) +
                                      (transactionInfo["recipientAmt"] as int),
                                  ref.watch(
                                    localeServiceChangeNotifierProvider
                                        .select((value) => value.locale),
                                  ),
                                )} ${ref.watch(
                                      managerProvider
                                          .select((value) => value.coin),
                                    ).ticker}",
                                style: STextStyles.itemSubtitle12(context)
                                    .copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textConfirmTotalAmount,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        const Spacer(),
                        TextButton(
                          style: Theme.of(context)
                              .extension<StackColors>()!
                              .getPrimaryEnabledButtonColor(context),
                          onPressed: () async {
                            final unlocked = await Navigator.push(
                              context,
                              RouteGenerator.getRoute(
                                shouldUseMaterialRoute:
                                    RouteGenerator.useMaterialPageRoute,
                                builder: (_) => const LockscreenView(
                                  showBackButton: true,
                                  popOnSuccess: true,
                                  routeOnSuccessArguments: true,
                                  routeOnSuccess: "",
                                  biometricsCancelButtonString: "CANCEL",
                                  biometricsLocalizedReason:
                                      "Authenticate to send transaction",
                                  biometricsAuthenticationTitle:
                                      "Confirm Transaction",
                                ),
                                settings: const RouteSettings(
                                    name: "/confirmsendlockscreen"),
                              ),
                            );

                            if (unlocked is bool && unlocked && mounted) {
                              await _attemptSend(context);
                            }
                          },
                          child: Text(
                            "Send",
                            style: STextStyles.button(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
