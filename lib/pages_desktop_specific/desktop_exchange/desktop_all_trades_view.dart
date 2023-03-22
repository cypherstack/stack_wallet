import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction_status.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/exchange_view/trade_details_view.dart';
import 'package:stackwallet/providers/exchange/trade_sent_from_stack_lookup_provider.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';
import 'package:tuple/tuple.dart';

import '../../db/isar/main_db.dart';

class DesktopAllTradesView extends ConsumerStatefulWidget {
  const DesktopAllTradesView({Key? key}) : super(key: key);

  static const String routeName = "/desktopAllTrades";

  @override
  ConsumerState<DesktopAllTradesView> createState() =>
      _DesktopAllTradesViewState();
}

class _DesktopAllTradesViewState extends ConsumerState<DesktopAllTradesView> {
  late final TextEditingController _searchController;
  late final FocusNode searchFieldFocusNode;

  String _searchString = "";

  List<Tuple2<String, List<Trade>>> groupTransactionsByMonth(
      List<Trade> trades) {
    Map<String, List<Trade>> map = {};

    for (var trade in trades) {
      final date = trade.timestamp;
      final monthYear = "${Constants.monthMap[date.month]} ${date.year}";
      if (map[monthYear] == null) {
        map[monthYear] = [];
      }
      map[monthYear]!.add(trade);
    }

    List<Tuple2<String, List<Trade>>> result = [];
    map.forEach((key, value) {
      result.add(Tuple2(key, value));
    });

    return result;
  }

  @override
  void initState() {
    _searchController = TextEditingController();
    searchFieldFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    searchFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      appBar: DesktopAppBar(
        isCompactHeight: true,
        background: Theme.of(context).extension<StackColors>()!.popupBG,
        leading: Row(
          children: [
            const SizedBox(
              width: 32,
            ),
            AppBarIconButton(
              size: 32,
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .textFieldDefaultBG,
              shadows: const [],
              icon: SvgPicture.asset(
                Assets.svg.arrowLeft,
                width: 18,
                height: 18,
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .topNavIconPrimary,
              ),
              onPressed: Navigator.of(context).pop,
            ),
            const SizedBox(
              width: 12,
            ),
            Text(
              "Trades",
              style: STextStyles.desktopH3(context),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 20,
          top: 20,
          right: 20,
        ),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 570,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                    child: TextField(
                      autocorrect: false,
                      enableSuggestions: false,
                      controller: _searchController,
                      focusNode: searchFieldFocusNode,
                      onChanged: (value) {
                        setState(() {
                          _searchString = value;
                        });
                      },
                      style:
                          STextStyles.desktopTextExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textFieldActiveText,
                        height: 1.8,
                      ),
                      decoration: standardInputDecoration(
                        "Search...",
                        searchFieldFocusNode,
                        context,
                        desktopMed: true,
                      ).copyWith(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 18,
                          ),
                          child: SvgPicture.asset(
                            Assets.svg.search,
                            width: 20,
                            height: 20,
                          ),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(right: 0),
                                child: UnconstrainedBox(
                                  child: Row(
                                    children: [
                                      TextFieldIconButton(
                                        child: const XIcon(),
                                        onTap: () async {
                                          setState(() {
                                            _searchController.text = "";
                                            _searchString = "";
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            Expanded(
              child: Consumer(
                builder: (_, ref, __) {
                  List<Trade> trades = ref.watch(
                      tradesServiceProvider.select((value) => value.trades));

                  if (_searchString.isNotEmpty) {
                    final term = _searchString.toLowerCase();
                    trades = trades
                        .where((e) => e.toString().toLowerCase().contains(term))
                        .toList(growable: false);
                  }
                  final monthlyList = groupTransactionsByMonth(trades);

                  return ListView.builder(
                    primary: false,
                    itemCount: monthlyList.length,
                    itemBuilder: (_, index) {
                      final month = monthlyList[index];
                      return Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (index != 0)
                              const SizedBox(
                                height: 12,
                              ),
                            Text(
                              month.item1,
                              style: STextStyles.smallMed12(context),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            RoundedWhiteContainer(
                              padding: const EdgeInsets.all(0),
                              child: ListView.separated(
                                shrinkWrap: true,
                                primary: false,
                                separatorBuilder: (context, _) => Container(
                                  height: 1,
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .background,
                                ),
                                itemCount: month.item2.length,
                                itemBuilder: (context, index) => Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: DesktopTradeRowCard(
                                    key: Key(
                                        "transactionCard_key_${month.item2[index].tradeId}"),
                                    tradeId: month.item2[index].tradeId,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DesktopTradeRowCard extends ConsumerStatefulWidget {
  const DesktopTradeRowCard({
    Key? key,
    required this.tradeId,
  }) : super(key: key);

  final String tradeId;

  @override
  ConsumerState<DesktopTradeRowCard> createState() =>
      _DesktopTradeRowCardState();
}

class _DesktopTradeRowCardState extends ConsumerState<DesktopTradeRowCard> {
  late final String tradeId;

  String _fetchIconAssetForStatus(String statusString, BuildContext context) {
    ChangeNowTransactionStatus? status;
    try {
      if (statusString.toLowerCase().startsWith("waiting")) {
        statusString = "Waiting";
      }
      status = changeNowTransactionStatusFromStringIgnoreCase(statusString);
    } on ArgumentError catch (_) {
      switch (statusString.toLowerCase()) {
        case "funds confirming":
        case "processing payment":
          return Assets.svg.txExchangePending(context);

        case "completed":
          return Assets.svg.txExchange(context);

        default:
          status = ChangeNowTransactionStatus.Failed;
      }
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
  void initState() {
    tradeId = widget.tradeId;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final String? txid =
        ref.read(tradeSentFromStackLookupProvider).getTxidForTradeId(tradeId);
    final List<String>? walletIds = ref
        .read(tradeSentFromStackLookupProvider)
        .getWalletIdsForTradeId(tradeId);

    final trade =
        ref.watch(tradesServiceProvider.select((value) => value.get(tradeId)))!;

    return Material(
      color: Theme.of(context).extension<StackColors>()!.popupBG,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(Constants.size.circularBorderRadius),
      ),
      child: RawMaterialButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        onPressed: () async {
          if (txid != null && walletIds != null && walletIds.isNotEmpty) {
            final manager = ref
                .read(walletsChangeNotifierProvider)
                .getManager(walletIds.first);

            //todo: check if print needed
            // debugPrint("name: ${manager.walletName}");

            final tx = await MainDB.instance
                .getTransactions(walletIds.first)
                .filter()
                .txidEqualTo(txid)
                .findFirst();

            await showDialog<void>(
              context: context,
              builder: (context) => DesktopDialog(
                maxHeight: MediaQuery.of(context).size.height - 64,
                maxWidth: 580,
                child: TradeDetailsView(
                  tradeId: tradeId,
                  transactionIfSentFromStack: tx,
                  walletName: manager.walletName,
                  walletId: walletIds.first,
                ),
              ),
            );

            if (mounted) {
              unawaited(
                showDialog<void>(
                  context: context,
                  builder: (context) => Navigator(
                    initialRoute: TradeDetailsView.routeName,
                    onGenerateRoute: RouteGenerator.generateRoute,
                    onGenerateInitialRoutes: (_, __) {
                      return [
                        FadePageRoute(
                          DesktopDialog(
                            maxHeight: null,
                            maxWidth: 580,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 32,
                                    bottom: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Trade details",
                                        style: STextStyles.desktopH3(context),
                                      ),
                                      DesktopDialogCloseButton(
                                        onPressedOverride: Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pop,
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: SingleChildScrollView(
                                    primary: false,
                                    child: TradeDetailsView(
                                      tradeId: tradeId,
                                      transactionIfSentFromStack: tx,
                                      walletName: manager.walletName,
                                      walletId: walletIds.first,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const RouteSettings(
                            name: TradeDetailsView.routeName,
                          ),
                        ),
                      ];
                    },
                  ),
                ),
              );
            }
          } else {
            unawaited(
              showDialog<void>(
                context: context,
                builder: (context) => Navigator(
                  initialRoute: TradeDetailsView.routeName,
                  onGenerateRoute: RouteGenerator.generateRoute,
                  onGenerateInitialRoutes: (_, __) {
                    return [
                      FadePageRoute(
                        DesktopDialog(
                          maxHeight: null,
                          maxWidth: 580,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 32,
                                  bottom: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Trade details",
                                      style: STextStyles.desktopH3(context),
                                    ),
                                    DesktopDialogCloseButton(
                                      onPressedOverride: Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pop,
                                    ),
                                  ],
                                ),
                              ),
                              Flexible(
                                child: SingleChildScrollView(
                                  primary: false,
                                  child: TradeDetailsView(
                                    tradeId: tradeId,
                                    transactionIfSentFromStack: null,
                                    walletName: null,
                                    walletId: walletIds?.first,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const RouteSettings(
                          name: TradeDetailsView.routeName,
                        ),
                      ),
                    ];
                  },
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 16,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    _fetchIconAssetForStatus(
                      trade.status,
                      context,
                    ),
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                flex: 3,
                child: Text(
                  "${trade.payInCurrency.toUpperCase()} → ${trade.payOutCurrency.toUpperCase()}",
                  style:
                      STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  Format.extractDateFrom(
                      trade.timestamp.millisecondsSinceEpoch ~/ 1000),
                  style: STextStyles.desktopTextExtraExtraSmall(context),
                ),
              ),
              Expanded(
                flex: 6,
                child: Text(
                  "-${Decimal.tryParse(trade.payInAmount)?.toStringAsFixed(8) ?? "..."} ${trade.payInCurrency.toUpperCase()}",
                  style:
                      STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  trade.exchangeName,
                  style: STextStyles.desktopTextExtraExtraSmall(context),
                ),
              ),
              SvgPicture.asset(
                Assets.svg.circleInfo,
                width: 20,
                height: 20,
                color:
                    Theme.of(context).extension<StackColors>()!.textSubtitle2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
