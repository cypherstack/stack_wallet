import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/exchange_view/trade_details_view.dart';
import 'package:stackwallet/providers/exchange/trade_sent_from_stack_lookup_provider.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/trade_card.dart';
import 'package:tuple/tuple.dart';

class DesktopTradeHistory extends ConsumerStatefulWidget {
  const DesktopTradeHistory({Key? key}) : super(key: key);

  @override
  ConsumerState<DesktopTradeHistory> createState() =>
      _DesktopTradeHistoryState();
}

class _DesktopTradeHistoryState extends ConsumerState<DesktopTradeHistory> {
  @override
  Widget build(BuildContext context) {
    final trades =
        ref.watch(tradesServiceProvider.select((value) => value.trades));

    final tradeCount = trades.length;
    final hasHistory = tradeCount > 0;

    if (hasHistory) {
      return ListView.separated(
        shrinkWrap: true,
        primary: false,
        itemBuilder: (context, index) {
          return TradeCard(
            key: Key("tradeCard_${trades[index].uuid}"),
            trade: trades[index],
            onTap: () async {
              final String tradeId = trades[index].tradeId;

              final lookup = ref.read(tradeSentFromStackLookupProvider).all;

              debugPrint("ALL: $lookup");

              final String? txid = ref
                  .read(tradeSentFromStackLookupProvider)
                  .getTxidForTradeId(tradeId);
              final List<String>? walletIds = ref
                  .read(tradeSentFromStackLookupProvider)
                  .getWalletIdsForTradeId(tradeId);

              if (txid != null && walletIds != null && walletIds.isNotEmpty) {
                final manager = ref
                    .read(walletsChangeNotifierProvider)
                    .getManager(walletIds.first);

                debugPrint("name: ${manager.walletName}");

                // TODO store tx data completely locally in isar so we don't lock up ui here when querying txData
                final txData = await manager.transactionData;

                final tx = txData.getAllTransactions()[txid];

                if (mounted) {
                  unawaited(
                    Navigator.of(context).pushNamed(
                      TradeDetailsView.routeName,
                      arguments: Tuple4(
                          tradeId, tx, walletIds.first, manager.walletName),
                    ),
                  );
                }
              } else {
                unawaited(
                  Navigator.of(context).pushNamed(
                    TradeDetailsView.routeName,
                    arguments: Tuple4(tradeId, null, walletIds?.first, null),
                  ),
                );
              }
            },
          );
        },
        separatorBuilder: (context, index) {
          return Container(
            height: 1,
            color: Theme.of(context).extension<StackColors>()!.background,
          );
        },
        itemCount: tradeCount,
      );
    } else {
      return RoundedWhiteContainer(
        child: Center(
          child: Text(
            "Trades will appear here",
            style: STextStyles.desktopTextExtraExtraSmall(context),
          ),
        ),
      );
    }
  }
}
