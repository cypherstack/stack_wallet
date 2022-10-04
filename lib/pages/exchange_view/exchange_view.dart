import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/exchange_view/exchange_form.dart';
import 'package:stackwallet/pages/exchange_view/trade_details_view.dart';
import 'package:stackwallet/providers/exchange/trade_sent_from_stack_lookup_provider.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/trade_card.dart';
import 'package:tuple/tuple.dart';

class ExchangeView extends ConsumerStatefulWidget {
  const ExchangeView({Key? key}) : super(key: key);

  @override
  ConsumerState<ExchangeView> createState() => _ExchangeViewState();
}

class _ExchangeViewState extends ConsumerState<ExchangeView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return SafeArea(
      child: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ExchangeForm(),
                ),
              ),
            )
          ];
        },
        body: Builder(
          builder: (buildContext) {
            final trades = ref
                .watch(tradesServiceProvider.select((value) => value.trades));
            final tradeCount = trades.length;
            final hasHistory = tradeCount > 0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CustomScrollView(
                slivers: [
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      buildContext,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            "Trades",
                            style: STextStyles.itemSubtitle(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textDark3,
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (hasHistory)
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(4),
                          child: TradeCard(
                            key: Key("tradeCard_${trades[index].uuid}"),
                            trade: trades[index],
                            onTap: () async {
                              final String tradeId = trades[index].tradeId;

                              final lookup = ref
                                  .read(tradeSentFromStackLookupProvider)
                                  .all;

                              debugPrint("ALL: $lookup");

                              final String? txid = ref
                                  .read(tradeSentFromStackLookupProvider)
                                  .getTxidForTradeId(tradeId);
                              final List<String>? walletIds = ref
                                  .read(tradeSentFromStackLookupProvider)
                                  .getWalletIdsForTradeId(tradeId);

                              if (txid != null &&
                                  walletIds != null &&
                                  walletIds.isNotEmpty) {
                                final manager = ref
                                    .read(walletsChangeNotifierProvider)
                                    .getManager(walletIds.first);

                                debugPrint("name: ${manager.walletName}");

                                // TODO store tx data completely locally in isar so we don't lock up ui here when querying txData
                                final txData = await manager.transactionData;

                                final tx = txData.getAllTransactions()[txid];

                                if (mounted) {
                                  unawaited(Navigator.of(context).pushNamed(
                                    TradeDetailsView.routeName,
                                    arguments: Tuple4(tradeId, tx,
                                        walletIds.first, manager.walletName),
                                  ));
                                }
                              } else {
                                unawaited(Navigator.of(context).pushNamed(
                                  TradeDetailsView.routeName,
                                  arguments: Tuple4(
                                      tradeId, null, walletIds?.first, null),
                                ));
                              }
                            },
                          ),
                        );
                      }, childCount: tradeCount),
                    ),
                  if (!hasHistory)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .popupBG,
                            borderRadius: BorderRadius.circular(
                              Constants.size.circularBorderRadius,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              "Trades will appear here",
                              textAlign: TextAlign.center,
                              style: STextStyles.itemSubtitle(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
