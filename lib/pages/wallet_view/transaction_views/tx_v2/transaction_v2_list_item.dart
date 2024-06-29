import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

import '../../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../../models/isar/models/isar_models.dart';
import '../../../../providers/global/trades_service_provider.dart';
import '../../../../route_generator.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../../widgets/breathing.dart';
import '../../../../widgets/desktop/desktop_dialog.dart';
import '../../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../../widgets/trade_card.dart';
import '../../../exchange_view/trade_details_view.dart';
import 'fusion_tx_group_card.dart';
import 'transaction_v2_card.dart';

class TxListItem extends ConsumerWidget {
  const TxListItem({
    super.key,
    required this.tx,
    this.radius,
    required this.coin,
  }) : assert(tx is TransactionV2 || tx is FusionTxGroup);

  final Object tx;
  final BorderRadius? radius;
  final CryptoCurrency coin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tx is TransactionV2) {
      final _tx = tx as TransactionV2;

      final matchingTrades = ref
          .read(tradesServiceProvider)
          .trades
          .where((e) => e.payInTxid == _tx.txid || e.payOutTxid == _tx.txid);

      if (_tx.type == TransactionType.outgoing && matchingTrades.isNotEmpty) {
        final trade = matchingTrades.first;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).extension<StackColors>()!.popupBG,
            borderRadius: radius,
          ),
          child: Breathing(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TransactionCardV2(
                  key: UniqueKey(),
                  transaction: _tx,
                ),
                TradeCard(
                  key: Key(
                    _tx.txid +
                        _tx.type.name +
                        _tx.hashCode.toString() +
                        trade.uuid,
                  ), //
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
                                              style: STextStyles.desktopH3(
                                                  context),
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
                                          // TODO: [prio:med]
                                          // transactionIfSentFromStack: tx,
                                          transactionIfSentFromStack: null,
                                          walletName: ref
                                              .watch(pWalletName(_tx.walletId)),
                                          walletId: _tx.walletId,
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
                            _tx,
                            _tx.walletId,
                            ref.read(pWalletName(_tx.walletId)),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      } else {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).extension<StackColors>()!.popupBG,
            borderRadius: radius,
          ),
          child: Breathing(
            child: TransactionCardV2(
              // this may mess with combined firo transactions
              key: UniqueKey(),
              transaction: _tx,
            ),
          ),
        );
      }
    }

    final group = tx as FusionTxGroup;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).extension<StackColors>()!.popupBG,
        borderRadius: radius,
      ),
      child: Breathing(
        child: FusionTxGroupCard(
          key: UniqueKey(),
          group: group,
        ),
      ),
    );
  }
}
