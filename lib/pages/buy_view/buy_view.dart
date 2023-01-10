import 'package:flutter/material.dart';
import 'package:stackwallet/pages/buy_view/buy_form.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class BuyView extends StatefulWidget {
  const BuyView({Key? key}) : super(key: key);

  @override
  State<BuyView> createState() => _BuyViewState();
}

class _BuyViewState extends State<BuyView> {
  @override
  Widget build(BuildContext context) {
    //todo: check if print needed
    // debugPrint("BUILD: BuyView");

    return SafeArea(
      child: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                  ),
                  child: BuyForm(),
                ),
              ),
            )
          ];
        },
        body: Builder(
          builder: (buildContext) {
            // final buys =
            //     ref.watch(buysServiceProvider.select((value) => value.buys));
            // final buyCount = buys.length;
            // final hasHistory = buyCount > 0;
            const hasHistory = false;

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
                  // if (hasHistory)
                  //   SliverList(
                  //     delegate: SliverChildBuilderDelegate((context, index) {
                  //       return Padding(
                  //         padding: const EdgeInsets.all(4),
                  //         child: TradeCard(
                  //           key: Key("tradeCard_${trades[index].uuid}"),
                  //           trade: trades[index],
                  //           onTap: () async {
                  //             final String tradeId = trades[index].tradeId;
                  //
                  //             final lookup = ref
                  //                 .read(tradeSentFromStackLookupProvider)
                  //                 .all;
                  //
                  //             //todo: check if print needed
                  //             // debugPrint("ALL: $lookup");
                  //
                  //             final String? txid = ref
                  //                 .read(tradeSentFromStackLookupProvider)
                  //                 .getTxidForTradeId(tradeId);
                  //             final List<String>? walletIds = ref
                  //                 .read(tradeSentFromStackLookupProvider)
                  //                 .getWalletIdsForTradeId(tradeId);
                  //
                  //             if (txid != null &&
                  //                 walletIds != null &&
                  //                 walletIds.isNotEmpty) {
                  //               final manager = ref
                  //                   .read(walletsChangeNotifierProvider)
                  //                   .getManager(walletIds.first);
                  //
                  //               //todo: check if print needed
                  //               // debugPrint("name: ${manager.walletName}");
                  //
                  //               // TODO store tx data completely locally in isar so we don't lock up ui here when querying txData
                  //               final txData = await manager.transactionData;
                  //
                  //               final tx = txData.getAllTransactions()[txid];
                  //
                  //               if (mounted) {
                  //                 unawaited(Navigator.of(context).pushNamed(
                  //                   TradeDetailsView.routeName,
                  //                   arguments: Tuple4(tradeId, tx,
                  //                       walletIds.first, manager.walletName),
                  //                 ));
                  //               }
                  //             } else {
                  //               unawaited(Navigator.of(context).pushNamed(
                  //                 TradeDetailsView.routeName,
                  //                 arguments: Tuple4(
                  //                     tradeId, null, walletIds?.first, null),
                  //               ));
                  //             }
                  //           },
                  //         ),
                  //       );
                  //     }, childCount: tradeCount),
                  //   ),
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
