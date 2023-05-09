import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/exchange_view/trade_details_view.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/no_transactions_found.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
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
  List<Transaction> _transactions2 = [];

  late final ChangeNotifierProvider<Manager> managerProvider;

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
    BuildContext context,
    Transaction tx,
    BorderRadius? radius,
    Coin coin,
  ) {
    final matchingTrades = ref
        .read(tradesServiceProvider)
        .trades
        .where((e) => e.payInTxid == tx.txid || e.payOutTxid == tx.txid);

    final isConfirmed = tx.isConfirmed(
        ref.watch(
            widget.managerProvider.select((value) => value.currentHeight)),
        coin.requiredConfirmations);

    if (tx.type == TransactionType.outgoing && matchingTrades.isNotEmpty) {
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
              key: isConfirmed
                  ? Key(tx.txid + tx.type.name + tx.address.value.toString())
                  : UniqueKey(), //
              transaction: tx,
              walletId: widget.walletId,
            ),
            TradeCard(
              // this may mess with combined firo transactions
              key: Key(tx.txid +
                  tx.type.name +
                  tx.address.value.toString() +
                  trade.uuid), //
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
          key: isConfirmed
              ? Key(tx.txid + tx.type.name + tx.address.value.toString())
              : UniqueKey(),
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
    final manager = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId)));

    return FutureBuilder(
      future: manager.transactions,
      builder: (fbContext, AsyncSnapshot<List<Transaction>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          _transactions2 = snapshot.data!;
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
        if (_transactions2.isEmpty) {
          return const NoTransActionsFound();
        } else {
          _transactions2.sort((a, b) => b.timestamp - a.timestamp);
          return RefreshIndicator(
            onRefresh: () async {
              //todo: check if print needed
              // debugPrint("pulled down to refresh on transaction list");
              final managerProvider = ref
                  .read(walletsChangeNotifierProvider)
                  .getManagerProvider(widget.walletId);
              if (!ref.read(managerProvider).isRefreshing) {
                unawaited(ref.read(managerProvider).refresh());
              }
            },
            child: Util.isDesktop
                ? ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      BorderRadius? radius;
                      if (_transactions2.length == 1) {
                        radius = BorderRadius.circular(
                          Constants.size.circularBorderRadius,
                        );
                      } else if (index == _transactions2.length - 1) {
                        radius = _borderRadiusLast;
                      } else if (index == 0) {
                        radius = _borderRadiusFirst;
                      }
                      final tx = _transactions2[index];
                      return itemBuilder(context, tx, radius, manager.coin);
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
                    itemCount: _transactions2.length,
                  )
                : ListView.builder(
                    itemCount: _transactions2.length,
                    itemBuilder: (context, index) {
                      BorderRadius? radius;
                      bool shouldWrap = false;
                      if (_transactions2.length == 1) {
                        radius = BorderRadius.circular(
                          Constants.size.circularBorderRadius,
                        );
                      } else if (index == _transactions2.length - 1) {
                        radius = _borderRadiusLast;
                        shouldWrap = true;
                      } else if (index == 0) {
                        radius = _borderRadiusFirst;
                      }
                      final tx = _transactions2[index];
                      if (shouldWrap) {
                        return Column(
                          children: [
                            itemBuilder(context, tx, radius, manager.coin),
                            const SizedBox(
                              height: WalletView.navBarHeight + 14,
                            ),
                          ],
                        );
                      } else {
                        return itemBuilder(context, tx, radius, manager.coin);
                      }
                    },
                  ),
          );
        }
      },
    );
  }
}
