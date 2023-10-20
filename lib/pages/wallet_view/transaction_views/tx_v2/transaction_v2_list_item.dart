import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/exchange_view/trade_details_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/tx_v2/transaction_v2_card.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/trade_card.dart';
import 'package:tuple/tuple.dart';

class TxListItem extends ConsumerWidget {
  const TxListItem({
    super.key,
    required this.tx,
    this.radius,
    required this.coin,
  });

  final TransactionV2 tx;
  final BorderRadius? radius;
  final Coin coin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchingTrades = ref
        .read(tradesServiceProvider)
        .trades
        .where((e) => e.payInTxid == tx.txid || e.payOutTxid == tx.txid);

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
            TransactionCardV2(
              key: UniqueKey(),
              transaction: tx,
            ),
            TradeCard(
              key: Key(tx.txid +
                  tx.type.name +
                  tx.hashCode.toString() +
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
                                      // TODO
                                      // transactionIfSentFromStack: tx,
                                      transactionIfSentFromStack: null,
                                      walletName: ref.watch(
                                        walletsChangeNotifierProvider.select(
                                          (value) => value
                                              .getManager(tx.walletId)
                                              .walletName,
                                        ),
                                      ),
                                      walletId: tx.walletId,
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
                        tx.walletId,
                        ref
                            .read(walletsChangeNotifierProvider)
                            .getManager(tx.walletId)
                            .walletName,
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
        child: TransactionCardV2(
          // this may mess with combined firo transactions
          key: UniqueKey(),
          transaction: tx,
        ),
      );
    }
  }
}
