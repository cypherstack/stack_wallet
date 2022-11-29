import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart';
import 'package:stackwallet/pages/exchange_view/trade_details_view.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/no_transactions_found.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/trade_card.dart';
import 'package:stackwallet/widgets/transaction_card.dart';
import 'package:tuple/tuple.dart';

class TransactionsList extends ConsumerStatefulWidget {
  const TransactionsList({
    Key? key,
    required this.walletId,
    required this.managerProvider,
  }) : super(key: key);

  final String walletId;
  final ChangeNotifierProvider<Manager> managerProvider;

  @override
  ConsumerState<TransactionsList> createState() => _TransactionsListState();
}

class _TransactionsListState extends ConsumerState<TransactionsList> {
  //
  bool _hasLoaded = false;
  Map<String, Transaction> _transactions = {};

  late final ChangeNotifierProvider<Manager> managerProvider;

  void updateTransactions(TransactionData newData) {
    _transactions = {};
    final newTransactions =
        newData.txChunks.expand((element) => element.transactions);
    for (final tx in newTransactions) {
      _transactions[tx.txid] = tx;
    }
  }

  BorderRadius get _borderRadiusFirst {
    return BorderRadius.only(
      topLeft: Radius.circular(
        Constants.size.circularBorderRadius,
      ),
      topRight: Radius.circular(
        Constants.size.circularBorderRadius,
      ),
    );
  }

  BorderRadius get _borderRadiusLast {
    return BorderRadius.only(
      bottomLeft: Radius.circular(
        Constants.size.circularBorderRadius,
      ),
      bottomRight: Radius.circular(
        Constants.size.circularBorderRadius,
      ),
    );
  }

  Widget itemBuilder(
      BuildContext context, Transaction tx, BorderRadius? radius) {
    final matchingTrades = ref
        .read(tradesServiceProvider)
        .trades
        .where((e) => e.payInTxid == tx.txid || e.payOutTxid == tx.txid);
    if (tx.txType == "Sent" && matchingTrades.isNotEmpty) {
      final trade = matchingTrades.first;
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).extension<StackColors>()!.popupBG,
          borderRadius: radius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TransactionCard(
              // this may mess with combined firo transactions
              key: Key(tx.toString()), //
              transaction: tx,
              walletId: widget.walletId,
            ),
            TradeCard(
              // this may mess with combined firo transactions
              key: Key(tx.toString() + trade.uuid), //
              trade: trade,
              onTap: () async {
                if (Util.isDesktop) {
                  await showDialog<void>(
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
                                    child: TradeDetailsView(
                                      tradeId: trade.tradeId,
                                      transactionIfSentFromStack: tx,
                                      walletName:
                                          ref.read(managerProvider).walletName,
                                      walletId: widget.walletId,
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
                  );
                } else {
                  unawaited(
                    Navigator.of(context).pushNamed(
                      TradeDetailsView.routeName,
                      arguments: Tuple4(
                        trade.tradeId,
                        tx,
                        widget.walletId,
                        ref.read(managerProvider).walletName,
                      ),
                    ),
                  );
                }
              },
            )
          ],
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).extension<StackColors>()!.popupBG,
          borderRadius: radius,
        ),
        child: TransactionCard(
          // this may mess with combined firo transactions
          key: Key(tx.toString()), //
          transaction: tx,
          walletId: widget.walletId,
        ),
      );
    }
  }

  @override
  void initState() {
    managerProvider = widget.managerProvider;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // final managerProvider = ref
    //     .watch(walletsChangeNotifierProvider)
    //     .getManagerProvider(widget.walletId);

    return FutureBuilder(
      future:
          ref.watch(managerProvider.select((value) => value.transactionData)),
      builder: (fbContext, AsyncSnapshot<TransactionData> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          updateTransactions(snapshot.data!);
          _hasLoaded = true;
        }
        if (!_hasLoaded) {
          return Column(
            children: const [
              Spacer(),
              Center(
                child: LoadingIndicator(
                  height: 50,
                  width: 50,
                ),
              ),
              Spacer(
                flex: 4,
              ),
            ],
          );
        }
        if (_transactions.isEmpty) {
          return const NoTransActionsFound();
        } else {
          final list = _transactions.values.toList(growable: false);
          list.sort((a, b) => b.timestamp - a.timestamp);
          return RefreshIndicator(
            onRefresh: () async {
              debugPrint("pulled down to refresh on transaction list");
              final managerProvider = ref
                  .read(walletsChangeNotifierProvider)
                  .getManagerProvider(widget.walletId);
              if (!ref.read(managerProvider).isRefreshing) {
                unawaited(ref.read(managerProvider).refresh());
              }
            },
            child: Util.isDesktop
                ? ListView.separated(
                    itemBuilder: (context, index) {
                      BorderRadius? radius;
                      if (index == list.length - 1) {
                        radius = _borderRadiusLast;
                      } else if (index == 0) {
                        radius = _borderRadiusFirst;
                      }
                      final tx = list[index];
                      return itemBuilder(context, tx, radius);
                    },
                    separatorBuilder: (context, index) {
                      return Container(
                        width: double.infinity,
                        height: 2,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .background,
                      );
                    },
                    itemCount: list.length,
                  )
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      BorderRadius? radius;
                      if (index == list.length - 1) {
                        radius = _borderRadiusLast;
                      } else if (index == 0) {
                        radius = _borderRadiusFirst;
                      }
                      final tx = list[index];
                      return itemBuilder(context, tx, radius);
                    },
                  ),
          );
        }
      },
    );
  }
}
