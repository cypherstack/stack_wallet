import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction_status.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/exchange_view/edit_trade_note_view.dart';
import 'package:stackwallet/pages/exchange_view/send_from_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/edit_note_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/providers/exchange/change_now_provider.dart';
import 'package:stackwallet/providers/exchange/trade_note_service_provider.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';

class TradeDetailsView extends ConsumerStatefulWidget {
  const TradeDetailsView({
    Key? key,
    required this.tradeId,
    required this.transactionIfSentFromStack,
    required this.walletId,
    required this.walletName,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/tradeDetails";

  final String tradeId;
  final ClipboardInterface clipboard;
  final Transaction? transactionIfSentFromStack;
  final String? walletId;
  final String? walletName;

  @override
  ConsumerState<TradeDetailsView> createState() => _TradeDetailsViewState();
}

class _TradeDetailsViewState extends ConsumerState<TradeDetailsView> {
  late final String tradeId;
  late final ClipboardInterface clipboard;
  late final Transaction? transactionIfSentFromStack;
  late final String? walletId;

  String _note = "";

  bool isStackCoin(String ticker) {
    try {
      coinFromTickerCaseInsensitive(ticker);
      return true;
    } on ArgumentError catch (_) {
      return false;
    }
  }

  @override
  initState() {
    tradeId = widget.tradeId;
    clipboard = widget.clipboard;
    transactionIfSentFromStack = widget.transactionIfSentFromStack;
    walletId = widget.walletId;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final trade = ref
          .read(tradesServiceProvider)
          .trades
          .firstWhere((e) => e.id == tradeId);

      if (mounted && trade.statusObject == null ||
          trade.statusObject!.amountSendDecimal.isEmpty) {
        final status = await ref
            .read(changeNowProvider)
            .getTransactionStatus(id: trade.id);

        if (mounted && status.value != null) {
          await ref.read(tradesServiceProvider).edit(
              trade: trade.copyWith(statusObject: status.value),
              shouldNotifyListeners: true);
        }
      }
    });
    super.initState();
  }

  String _fetchIconAssetForStatus(String statusString) {
    ChangeNowTransactionStatus? status;
    try {
      if (statusString.toLowerCase().startsWith("waiting")) {
        statusString = "Waiting";
      }
      status = changeNowTransactionStatusFromStringIgnoreCase(statusString);
    } on ArgumentError catch (_) {
      status = ChangeNowTransactionStatus.Failed;
    }

    switch (status) {
      case ChangeNowTransactionStatus.New:
      case ChangeNowTransactionStatus.Waiting:
      case ChangeNowTransactionStatus.Confirming:
      case ChangeNowTransactionStatus.Exchanging:
      case ChangeNowTransactionStatus.Sending:
      case ChangeNowTransactionStatus.Refunded:
      case ChangeNowTransactionStatus.Verifying:
        return Assets.svg.txExchangePending(context);
      case ChangeNowTransactionStatus.Finished:
        return Assets.svg.txExchange(context);
      case ChangeNowTransactionStatus.Failed:
        return Assets.svg.txExchangeFailed(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool sentFromStack =
        transactionIfSentFromStack != null && walletId != null;

    final trade = ref.watch(tradesServiceProvider
        .select((value) => value.trades.firstWhere((e) => e.id == tradeId)));

    final bool hasTx = sentFromStack ||
        !(trade.statusObject?.status == ChangeNowTransactionStatus.New ||
            trade.statusObject?.status == ChangeNowTransactionStatus.Waiting ||
            trade.statusObject?.status == ChangeNowTransactionStatus.Refunded ||
            trade.statusObject?.status == ChangeNowTransactionStatus.Failed);

    debugPrint("sentFromStack: $sentFromStack");
    debugPrint("hasTx: $hasTx");
    debugPrint("trade: ${trade.toString()}");

    final sendAmount = Decimal.tryParse(
            trade.statusObject?.amountSendDecimal ?? "") ??
        Decimal.tryParse(trade.statusObject?.expectedSendAmountDecimal ?? "") ??
        Decimal.parse("-1");

    return Scaffold(
      backgroundColor: Theme.of(context).extension<StackColors>()!.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        leading: AppBarBackButton(
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Trade details",
          style: STextStyles.navBarTitle(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RoundedWhiteContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            "${trade.fromCurrency.toUpperCase()} → ${trade.toCurrency.toUpperCase()}",
                            style: STextStyles.titleBold12(context),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          SelectableText(
                            "${Format.localizedStringAsFixed(value: sendAmount, locale: ref.watch(
                                  localeServiceChangeNotifierProvider
                                      .select((value) => value.locale),
                                ), decimalPlaces: trade.fromCurrency.toLowerCase() == "xmr" ? 12 : 8)} ${trade.fromCurrency.toUpperCase()}",
                            style: STextStyles.itemSubtitle(context),
                          ),
                        ],
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            _fetchIconAssetForStatus(
                                trade.statusObject?.status.name ??
                                    trade.statusString),
                            width: 32,
                            height: 32,
                          ),
                        ),
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
                        "Status",
                        style: STextStyles.itemSubtitle(context),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      SelectableText(
                        trade.statusObject?.status.name ?? trade.statusString,
                        style: STextStyles.itemSubtitle(context).copyWith(
                          color: trade.statusObject != null
                              ? Theme.of(context)
                                  .extension<StackColors>()!
                                  .colorForStatus(trade.statusObject!.status)
                              : Theme.of(context)
                                  .extension<StackColors>()!
                                  .accentColorDark,
                        ),
                      ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                if (!sentFromStack && !hasTx)
                  const SizedBox(
                    height: 12,
                  ),
                if (!sentFromStack && !hasTx)
                  RoundedContainer(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .warningBackground,
                    child: RichText(
                      text: TextSpan(
                          text:
                              "You must send at least ${sendAmount.toStringAsFixed(
                            trade.fromCurrency.toLowerCase() == "xmr" ? 12 : 8,
                          )} ${trade.fromCurrency.toUpperCase()}. ",
                          style: STextStyles.label700(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .warningForeground,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  "If you send less than ${sendAmount.toStringAsFixed(
                                trade.fromCurrency.toLowerCase() == "xmr"
                                    ? 12
                                    : 8,
                              )} ${trade.fromCurrency.toUpperCase()}, your transaction may not be converted and it may not be refunded.",
                              style: STextStyles.label(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .warningForeground,
                              ),
                            ),
                          ]),
                    ),
                  ),
                if (sentFromStack)
                  const SizedBox(
                    height: 12,
                  ),
                if (sentFromStack)
                  RoundedWhiteContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sent from",
                          style: STextStyles.itemSubtitle(context),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        SelectableText(
                          widget.walletName!,
                          style: STextStyles.itemSubtitle12(context),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            final Coin coin = coinFromTickerCaseInsensitive(
                                trade.fromCurrency);

                            Navigator.of(context).pushNamed(
                              TransactionDetailsView.routeName,
                              arguments: Tuple3(
                                  transactionIfSentFromStack!, coin, walletId!),
                            );
                          },
                          child: Text(
                            "View transaction",
                            style: STextStyles.link2(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (sentFromStack)
                  const SizedBox(
                    height: 12,
                  ),
                if (sentFromStack)
                  RoundedWhiteContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ChangeNOW address",
                          style: STextStyles.itemSubtitle(context),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        SelectableText(
                          trade.payinAddress,
                          style: STextStyles.itemSubtitle12(context),
                        ),
                      ],
                    ),
                  ),
                if (!sentFromStack && !hasTx)
                  const SizedBox(
                    height: 12,
                  ),
                if (!sentFromStack && !hasTx)
                  RoundedWhiteContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Send ${trade.fromCurrency.toUpperCase()} to this address",
                              style: STextStyles.itemSubtitle(context),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final address = trade.payinAddress;
                                await Clipboard.setData(
                                  ClipboardData(
                                    text: address,
                                  ),
                                );
                                unawaited(showFloatingFlushBar(
                                  type: FlushBarType.info,
                                  message: "Copied to clipboard",
                                  context: context,
                                ));
                              },
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    Assets.svg.copy,
                                    width: 12,
                                    height: 12,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .infoItemIcons,
                                  ),
                                  const SizedBox(
                                    width: 4,
                                  ),
                                  Text(
                                    "Copy",
                                    style: STextStyles.link2(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        SelectableText(
                          trade.payinAddress,
                          style: STextStyles.itemSubtitle12(context),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            showDialog<dynamic>(
                              context: context,
                              useSafeArea: false,
                              barrierDismissible: true,
                              builder: (_) {
                                final width =
                                    MediaQuery.of(context).size.width / 2;
                                return StackDialogBase(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Center(
                                        child: Text(
                                          "Send ${trade.fromCurrency.toUpperCase()} to this address",
                                          style:
                                              STextStyles.pageTitleH2(context),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      Center(
                                        child: RepaintBoundary(
                                          // key: _qrKey,
                                          child: SizedBox(
                                            width: width + 20,
                                            height: width + 20,
                                            child: QrImage(
                                                data: trade.payinAddress,
                                                size: width,
                                                backgroundColor: Theme.of(
                                                        context)
                                                    .extension<StackColors>()!
                                                    .popupBG,
                                                foregroundColor: Theme.of(
                                                        context)
                                                    .extension<StackColors>()!
                                                    .accentColorDark),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      Center(
                                        child: SizedBox(
                                          width: width,
                                          child: TextButton(
                                            onPressed: () async {
                                              // await _capturePng(true);
                                              Navigator.of(context).pop();
                                            },
                                            style: Theme.of(context)
                                                .extension<StackColors>()!
                                                .getSecondaryEnabledButtonColor(
                                                    context),
                                            child: Text(
                                              "Cancel",
                                              style: STextStyles.button(context)
                                                  .copyWith(
                                                      color: Theme.of(context)
                                                          .extension<
                                                              StackColors>()!
                                                          .accentColorDark),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                Assets.svg.qrcode,
                                width: 12,
                                height: 12,
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .infoItemIcons,
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Text(
                                "Show QR code",
                                style: STextStyles.link2(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(
                  height: 12,
                ),
                RoundedWhiteContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Trade note",
                            style: STextStyles.itemSubtitle(context),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                EditTradeNoteView.routeName,
                                arguments: Tuple2(
                                  tradeId,
                                  ref
                                      .read(tradeNoteServiceProvider)
                                      .getNote(tradeId: tradeId),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  Assets.svg.pencil,
                                  width: 10,
                                  height: 10,
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .infoItemIcons,
                                ),
                                const SizedBox(
                                  width: 4,
                                ),
                                Text(
                                  "Edit",
                                  style: STextStyles.link2(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      SelectableText(
                        ref.watch(tradeNoteServiceProvider.select(
                            (value) => value.getNote(tradeId: tradeId))),
                        style: STextStyles.itemSubtitle12(context),
                      ),
                    ],
                  ),
                ),
                if (sentFromStack)
                  const SizedBox(
                    height: 12,
                  ),
                if (sentFromStack)
                  RoundedWhiteContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Transaction note",
                              style: STextStyles.itemSubtitle(context),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  EditNoteView.routeName,
                                  arguments: Tuple3(
                                    transactionIfSentFromStack!.txid,
                                    walletId!,
                                    _note,
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    Assets.svg.pencil,
                                    width: 10,
                                    height: 10,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .infoItemIcons,
                                  ),
                                  const SizedBox(
                                    width: 4,
                                  ),
                                  Text(
                                    "Edit",
                                    style: STextStyles.link2(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        FutureBuilder(
                          future: ref.watch(
                              notesServiceChangeNotifierProvider(walletId!)
                                  .select((value) => value.getNoteFor(
                                      txid: transactionIfSentFromStack!.txid))),
                          builder:
                              (builderContext, AsyncSnapshot<String> snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData) {
                              _note = snapshot.data ?? "";
                            }
                            return SelectableText(
                              _note,
                              style: STextStyles.itemSubtitle12(context),
                            );
                          },
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
                        "Date",
                        style: STextStyles.itemSubtitle(context),
                      ),
                      // Flexible(
                      //   child: FittedBox(
                      //     fit: BoxFit.scaleDown,
                      //     child:
                      SelectableText(
                        Format.extractDateFrom(
                            trade.date.millisecondsSinceEpoch ~/ 1000),
                        style: STextStyles.itemSubtitle12(context),
                      ),
                      //   ),
                      // ),
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
                        "Exchange",
                        style: STextStyles.itemSubtitle(context),
                      ),
                      // Flexible(
                      //   child: FittedBox(
                      //     fit: BoxFit.scaleDown,
                      //     child:
                      SelectableText(
                        "ChangeNOW",
                        style: STextStyles.itemSubtitle12(context),
                      ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                RoundedWhiteContainer(
                  child: Row(
                    children: [
                      Text(
                        "Trade ID",
                        style: STextStyles.itemSubtitle(context),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            trade.id,
                            style: STextStyles.itemSubtitle12(context),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          GestureDetector(
                            onTap: () async {
                              final data = ClipboardData(text: trade.id);
                              await clipboard.setData(data);
                              unawaited(showFloatingFlushBar(
                                type: FlushBarType.info,
                                message: "Copied to clipboard",
                                context: context,
                              ));
                            },
                            child: SvgPicture.asset(
                              Assets.svg.copy,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .infoItemIcons,
                              width: 12,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                RoundedWhiteContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tracking",
                        style: STextStyles.itemSubtitle(context),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      GestureDetector(
                        onTap: () {
                          final url =
                              "https://changenow.io/exchange/txs/${trade.id}";
                          launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: Text(
                          "https://changenow.io/exchange/txs/${trade.id}",
                          style: STextStyles.link2(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                if (isStackCoin(trade.fromCurrency) &&
                    trade.statusObject != null &&
                    (trade.statusObject!.status ==
                            ChangeNowTransactionStatus.New ||
                        trade.statusObject!.status ==
                            ChangeNowTransactionStatus.Waiting))
                  SecondaryButton(
                    label: "Send from Stack",
                    onPressed: () {
                      final amount = sendAmount;
                      final address = trade.payinAddress;

                      final coin =
                          coinFromTickerCaseInsensitive(trade.fromCurrency);

                      print("amount: $amount");
                      print("address: $address");
                      print("coin: $coin");

                      Navigator.of(context).pushNamed(
                        SendFromView.routeName,
                        arguments: Tuple4(
                          coin,
                          amount,
                          address,
                          trade,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
