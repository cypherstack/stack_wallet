import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/trade_wallet_lookup.dart';
import 'package:stackwallet/pages/pinpad_views/lock_screen_view.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/sending_transaction_dialog.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_auth_send.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/utilities/amount.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:uuid/uuid.dart';

class ConfirmChangeNowSendView extends ConsumerStatefulWidget {
  const ConfirmChangeNowSendView({
    Key? key,
    required this.transactionInfo,
    required this.walletId,
    this.routeOnSuccessName = WalletView.routeName,
    required this.trade,
    this.shouldSendPublicFiroFunds,
    this.fromDesktopStep4 = false,
  }) : super(key: key);

  static const String routeName = "/confirmChangeNowSend";

  final Map<String, dynamic> transactionInfo;
  final String walletId;
  final String routeOnSuccessName;
  final Trade trade;
  final bool? shouldSendPublicFiroFunds;
  final bool fromDesktopStep4;

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

  final isDesktop = Util.isDesktop;

  Future<void> _attemptSend(BuildContext context) async {
    final manager =
        ref.read(walletsChangeNotifierProvider).getManager(walletId);
    unawaited(
      showDialog<void>(
        context: context,
        useSafeArea: false,
        barrierDismissible: false,
        builder: (context) {
          return SendingTransactionDialog(
            coin: manager.coin,
          );
        },
      ),
    );

    final time = Future<dynamic>.delayed(
      const Duration(
        milliseconds: 2500,
      ),
    );

    late String txid;
    Future<String> txidFuture;

    final String note = transactionInfo["note"] as String? ?? "";

    try {
      if (widget.shouldSendPublicFiroFunds == true) {
        txidFuture = (manager.wallet as FiroWallet)
            .confirmSendPublic(txData: transactionInfo);
      } else {
        txidFuture = manager.confirmSend(txData: transactionInfo);
      }

      unawaited(manager.refresh());

      final results = await Future.wait([
        txidFuture,
        time,
      ]);

      txid = results.first as String;

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
        if (Util.isDesktop) {
          Navigator.of(context, rootNavigator: true).pop();

          // stupid hack
          if (widget.fromDesktopStep4) {
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.of(context, rootNavigator: true).pop();
          }
        }

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
                  .getSecondaryEnabledButtonStyle(context),
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

  Future<void> _confirmSend() async {
    final dynamic unlocked;

    final coin =
        ref.read(walletsChangeNotifierProvider).getManager(walletId).coin;

    if (Util.isDesktop) {
      unlocked = await showDialog<bool?>(
        context: context,
        builder: (context) => DesktopDialog(
          maxWidth: 580,
          maxHeight: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  DesktopDialogCloseButton(),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                  right: 32,
                  bottom: 32,
                ),
                child: DesktopAuthSend(
                  coin: coin,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      unlocked = await Navigator.push(
        context,
        RouteGenerator.getRoute(
          shouldUseMaterialRoute: RouteGenerator.useMaterialPageRoute,
          builder: (_) => const LockscreenView(
            showBackButton: true,
            popOnSuccess: true,
            routeOnSuccessArguments: true,
            routeOnSuccess: "",
            biometricsCancelButtonString: "CANCEL",
            biometricsLocalizedReason: "Authenticate to send transaction",
            biometricsAuthenticationTitle: "Confirm Transaction",
          ),
          settings: const RouteSettings(name: "/confirmsendlockscreen"),
        ),
      );
    }

    if (unlocked is bool && unlocked && mounted) {
      await _attemptSend(context);
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

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) {
        return Background(
          child: Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              backgroundColor:
                  Theme.of(context).extension<StackColors>()!.backgroundAppBar,
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
                          child: child,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      child: ConditionalParent(
        condition: isDesktop,
        builder: (child) => DesktopDialog(
          maxHeight: double.infinity,
          maxWidth: 580,
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 6,
                  ),
                  const AppBarBackButton(
                    isCompact: true,
                    iconSize: 23,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Text(
                    "Confirm ${ref.watch(managerProvider.select((value) => value.coin)).ticker} transaction",
                    style: STextStyles.desktopH3(context),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                  right: 32,
                  bottom: 32,
                ),
                child: Column(
                  children: [
                    RoundedWhiteContainer(
                      padding: const EdgeInsets.all(0),
                      borderColor: Theme.of(context)
                          .extension<StackColors>()!
                          .background,
                      child: child,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Row(
                      children: [
                        Text(
                          "Transaction fee",
                          style:
                              STextStyles.desktopTextExtraExtraSmall(context),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    RoundedContainer(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldDefaultBG,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "${(transactionInfo["fee"] as int).toAmount(
                              fractionDigits: ref.watch(
                                managerProvider
                                    .select((value) => value.coin.decimals),
                              ),
                            )} ${ref.watch(
                                  managerProvider.select((value) => value.coin),
                                ).ticker}",
                            style:
                                STextStyles.desktopTextExtraExtraSmall(context)
                                    .copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 16,
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
                            style: STextStyles.titleBold12(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textConfirmTotalAmount,
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final coin = ref.watch(
                                managerProvider.select((value) => value.coin),
                              );
                              final fee =
                                  (transactionInfo["fee"] as int).toAmount(
                                fractionDigits: coin.decimals,
                              );
                              final amount =
                                  transactionInfo["recipientAmt"] as Amount;
                              final total = amount + fee;
                              final locale = ref.watch(
                                localeServiceChangeNotifierProvider.select(
                                  (value) => value.locale,
                                ),
                              );
                              return Text(
                                "${total.localizedStringAsFixed(
                                  locale: locale,
                                )}"
                                " ${coin.ticker}",
                                style: STextStyles.itemSubtitle12(context)
                                    .copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textConfirmTotalAmount,
                                ),
                                textAlign: TextAlign.right,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: "Cancel",
                            buttonHeight: ButtonHeight.l,
                            onPressed: Navigator.of(context).pop,
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: PrimaryButton(
                            label: "Send",
                            buttonHeight: isDesktop ? ButtonHeight.l : null,
                            onPressed: _confirmSend,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConditionalParent(
              condition: isDesktop,
              builder: (child) => Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).extension<StackColors>()!.background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      child,
                    ],
                  ),
                ),
              ),
              child: Text(
                "Send ${ref.watch(managerProvider.select((value) => value.coin)).ticker}",
                style: isDesktop
                    ? STextStyles.desktopTextMedium(context)
                    : STextStyles.pageTitleH1(context),
              ),
            ),
            isDesktop
                ? Container(
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    height: 1,
                  )
                : const SizedBox(
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
            isDesktop
                ? Container(
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    height: 1,
                  )
                : const SizedBox(
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
            isDesktop
                ? Container(
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    height: 1,
                  )
                : const SizedBox(
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
                  ConditionalParent(
                    condition: isDesktop,
                    builder: (child) => Row(
                      children: [
                        child,
                        Builder(builder: (context) {
                          final coin = ref.watch(
                              walletsChangeNotifierProvider.select(
                                  (value) => value.getManager(walletId).coin));
                          final price = ref.watch(
                              priceAnd24hChangeNotifierProvider
                                  .select((value) => value.getPrice(coin)));
                          final amount =
                              transactionInfo["recipientAmt"] as Amount;
                          final value = (price.item1 * amount.decimal)
                              .toAmount(fractionDigits: 2);
                          final currency = ref.watch(prefsChangeNotifierProvider
                              .select((value) => value.currency));
                          final locale = ref.watch(
                            localeServiceChangeNotifierProvider.select(
                              (value) => value.locale,
                            ),
                          );

                          return Text(
                            " | ${value.localizedStringAsFixed(locale: locale)} $currency",
                            style:
                                STextStyles.desktopTextExtraExtraSmall(context)
                                    .copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textSubtitle2,
                            ),
                          );
                        })
                      ],
                    ),
                    child: Text(
                      "${(transactionInfo["recipientAmt"] as Amount).localizedStringAsFixed(
                        locale: ref.watch(
                          localeServiceChangeNotifierProvider.select(
                            (value) => value.locale,
                          ),
                        ),
                      )} ${ref.watch(
                            managerProvider.select((value) => value.coin),
                          ).ticker}",
                      style: STextStyles.itemSubtitle12(context),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            isDesktop
                ? Container(
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    height: 1,
                  )
                : const SizedBox(
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
                    "${(transactionInfo["fee"] as int).toAmount(fractionDigits: ref.watch(
                          managerProvider.select(
                            (value) => value.coin.decimals,
                          ),
                        )).localizedStringAsFixed(
                          locale: ref.watch(
                            localeServiceChangeNotifierProvider.select(
                              (value) => value.locale,
                            ),
                          ),
                        )} ${ref.watch(
                          managerProvider.select((value) => value.coin),
                        ).ticker}",
                    style: STextStyles.itemSubtitle12(context),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            isDesktop
                ? Container(
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    height: 1,
                  )
                : const SizedBox(
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
            isDesktop
                ? Container(
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    height: 1,
                  )
                : const SizedBox(
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
            if (!isDesktop)
              const SizedBox(
                height: 12,
              ),
            if (!isDesktop)
              RoundedContainer(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .snackBarBackSuccess,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total amount",
                      style: STextStyles.titleBold12(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textConfirmTotalAmount,
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final coin = ref.watch(
                          managerProvider.select((value) => value.coin),
                        );
                        final fee = (transactionInfo["fee"] as int).toAmount(
                          fractionDigits: coin.decimals,
                        );
                        final amount =
                            transactionInfo["recipientAmt"] as Amount;
                        final total = amount + fee;
                        final locale = ref.watch(
                          localeServiceChangeNotifierProvider.select(
                            (value) => value.locale,
                          ),
                        );
                        return Text(
                          "${total.localizedStringAsFixed(
                            locale: locale,
                          )}"
                          " ${coin.ticker}",
                          style: STextStyles.itemSubtitle12(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textConfirmTotalAmount,
                          ),
                          textAlign: TextAlign.right,
                        );
                      },
                    ),
                  ],
                ),
              ),
            if (!isDesktop)
              const SizedBox(
                height: 16,
              ),
            if (!isDesktop) const Spacer(),
            if (!isDesktop)
              PrimaryButton(
                label: "Send",
                buttonHeight: isDesktop ? ButtonHeight.l : null,
                onPressed: _confirmSend,
              ),
          ],
        ),
      ),
    );
  }
}
