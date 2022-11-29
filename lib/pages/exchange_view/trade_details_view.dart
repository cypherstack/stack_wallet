import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:epicmobile/models/exchange/change_now/exchange_transaction_status.dart';
import 'package:epicmobile/models/paymint/transactions_model.dart';
import 'package:epicmobile/notifications/show_flush_bar.dart';
import 'package:epicmobile/pages/exchange_view/edit_trade_note_view.dart';
import 'package:epicmobile/pages/exchange_view/send_from_view.dart';
import 'package:epicmobile/pages/wallet_view/transaction_views/edit_note_view.dart';
import 'package:epicmobile/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:epicmobile/providers/global/trades_service_provider.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/services/exchange/change_now/change_now_exchange.dart';
import 'package:epicmobile/services/exchange/exchange.dart';
import 'package:epicmobile/services/exchange/simpleswap/simpleswap_exchange.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/clipboard_interface.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/enums/flush_bar_type.dart';
import 'package:epicmobile/utilities/format.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/desktop/secondary_button.dart';
import 'package:epicmobile/widgets/rounded_container.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
import 'package:epicmobile/widgets/stack_dialog.dart';
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

    if (ref.read(prefsChangeNotifierProvider).externalCalls) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        final trade = ref
            .read(tradesServiceProvider)
            .trades
            .firstWhere((e) => e.tradeId == tradeId);

        if (mounted) {
          final exchange = Exchange.fromName(trade.exchangeName);
          final response = await exchange.updateTrade(trade);

          if (mounted && response.value != null) {
            await ref
                .read(tradesServiceProvider)
                .edit(trade: response.value!, shouldNotifyListeners: true);
          }
        }
      });
    }
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

    final trade = ref.watch(tradesServiceProvider.select(
        (value) => value.trades.firstWhere((e) => e.tradeId == tradeId)));

    final bool hasTx = sentFromStack ||
        !(trade.status == "New" ||
            trade.status == "new" ||
            trade.status == "Waiting" ||
            trade.status == "waiting" ||
            trade.status == "Refunded" ||
            trade.status == "refunded" ||
            trade.status == "Closed" ||
            trade.status == "closed" ||
            trade.status == "Expired" ||
            trade.status == "expired" ||
            trade.status == "Failed" ||
            trade.status == "failed");

    debugPrint("sentFromStack: $sentFromStack");
    debugPrint("hasTx: $hasTx");
    debugPrint("trade: ${trade.toString()}");

    final sendAmount =
        Decimal.tryParse(trade.payInAmount) ?? Decimal.parse("-1");

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
                            "${trade.payInCurrency.toUpperCase()} → ${trade.payOutCurrency.toUpperCase()}",
                            style: STextStyles.titleBold12(context),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          SelectableText(
                            "${Format.localizedStringAsFixed(value: sendAmount, locale: ref.watch(
                                  localeServiceChangeNotifierProvider
                                      .select((value) => value.locale),
                                ), decimalPlaces: trade.payInCurrency.toLowerCase() == "xmr" ? 12 : 8)} ${trade.payInCurrency.toUpperCase()}",
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
                            _fetchIconAssetForStatus(trade.status),
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
                        trade.status,
                        style: STextStyles.itemSubtitle(context).copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .colorForStatus(trade.status),
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
                            trade.payInCurrency.toLowerCase() == "xmr" ? 12 : 8,
                          )} ${trade.payInCurrency.toUpperCase()}. ",
                          style: STextStyles.label700(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .warningForeground,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  "If you send less than ${sendAmount.toStringAsFixed(
                                trade.payInCurrency.toLowerCase() == "xmr"
                                    ? 12
                                    : 8,
                              )} ${trade.payInCurrency.toUpperCase()}, your transaction may not be converted and it may not be refunded.",
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
                                trade.payInCurrency);

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
                          "${trade.exchangeName} address",
                          style: STextStyles.itemSubtitle(context),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        SelectableText(
                          trade.payInAddress,
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
                              "Send ${trade.payInCurrency.toUpperCase()} to this address",
                              style: STextStyles.itemSubtitle(context),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final address = trade.payInAddress;
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
                          trade.payInAddress,
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
                                          "Send ${trade.payInCurrency.toUpperCase()} to this address",
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
                                                data: trade.payInAddress,
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
                            trade.timestamp.millisecondsSinceEpoch ~/ 1000),
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
                      SelectableText(
                        trade.exchangeName,
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
                    children: [
                      Text(
                        "Trade ID",
                        style: STextStyles.itemSubtitle(context),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            trade.tradeId,
                            style: STextStyles.itemSubtitle12(context),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          GestureDetector(
                            onTap: () async {
                              final data = ClipboardData(text: trade.tradeId);
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
                      Builder(builder: (context) {
                        late final String url;
                        switch (trade.exchangeName) {
                          case ChangeNowExchange.exchangeName:
                            url =
                                "https://changenow.io/exchange/txs/${trade.tradeId}";
                            break;
                          case SimpleSwapExchange.exchangeName:
                            url =
                                "https://simpleswap.io/exchange?id=${trade.tradeId}";
                            break;
                        }
                        return GestureDetector(
                          onTap: () {
                            launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          child: Text(
                            url,
                            style: STextStyles.link2(context),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                if (isStackCoin(trade.payInCurrency) &&
                    (trade.status == "New" ||
                        trade.status == "new" ||
                        trade.status == "waiting" ||
                        trade.status == "Waiting"))
                  SecondaryButton(
                    label: "Send from Stack",
                    onPressed: () {
                      final amount = sendAmount;
                      final address = trade.payInAddress;

                      final coin =
                          coinFromTickerCaseInsensitive(trade.payInCurrency);

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
