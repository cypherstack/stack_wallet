import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/pages/exchange_view/exchange_form.dart';
import 'package:stackwallet/pages/exchange_view/trade_details_view.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/exchange/exchange_data_loading_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';
import 'package:stackwallet/widgets/trade_card.dart';
import 'package:tuple/tuple.dart';

class ExchangeView extends ConsumerStatefulWidget {
  const ExchangeView({Key? key}) : super(key: key);

  @override
  ConsumerState<ExchangeView> createState() => _ExchangeViewState();
}

class _ExchangeViewState extends ConsumerState<ExchangeView> {
  bool _initialCachePopulationUnderway = false;

  @override
  void initState() {
    if (!ref.read(prefsChangeNotifierProvider).externalCalls) {
      if (ExchangeDataLoadingService.currentCacheVersion <
          ExchangeDataLoadingService.cacheVersion) {
        _initialCachePopulationUnderway = true;
        ExchangeDataLoadingService.instance.onLoadingComplete = () {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
            await ExchangeDataLoadingService.instance.setCurrenciesIfEmpty(
              ref.read(efCurrencyPairProvider),
              ref.read(efRateTypeProvider),
            );
            setState(() {
              _initialCachePopulationUnderway = false;
            });
          });
        };
      }
      ExchangeDataLoadingService.instance.loadAll();
    } else if (ExchangeDataLoadingService.instance.isLoading &&
        ExchangeDataLoadingService.currentCacheVersion <
            ExchangeDataLoadingService.cacheVersion) {
      _initialCachePopulationUnderway = true;
      ExchangeDataLoadingService.instance.onLoadingComplete = () {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
          await ExchangeDataLoadingService.instance.setCurrenciesIfEmpty(
            ref.read(efCurrencyPairProvider),
            ref.read(efRateTypeProvider),
          );
          setState(() {
            _initialCachePopulationUnderway = false;
          });
        });
      };
    }

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return ConditionalParent(
      condition: _initialCachePopulationUnderway,
      builder: (child) {
        return Stack(
          children: [
            child,
            Material(
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .overlay
                  .withOpacity(0.6),
              child: const CustomLoadingOverlay(
                message: "Updating exchange data",
                subMessage: "This could take a few minutes",
                eventBus: null,
              ),
            )
          ],
        );
      },
      child: SafeArea(
        child: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                    ),
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

                                //todo: check if print needed
                                // debugPrint("ALL: $lookup");

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

                                  //todo: check if print needed
                                  // debugPrint("name: ${manager.walletName}");

                                  final tx = await MainDB.instance
                                      .getTransactions(walletIds.first)
                                      .filter()
                                      .txidEqualTo(txid)
                                      .findFirst();

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
      ),
    );
  }
}
