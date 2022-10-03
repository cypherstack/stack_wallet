import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/exchange_view/exchange_form.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:stackwallet/pages/exchange_view/trade_details_view.dart';
import 'package:stackwallet/providers/exchange/changenow_initial_load_status.dart';
import 'package:stackwallet/providers/exchange/estimate_rate_exchange_form_provider.dart';
import 'package:stackwallet/providers/exchange/fixed_rate_exchange_form_provider.dart';
import 'package:stackwallet/providers/exchange/trade_sent_from_stack_lookup_provider.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/trade_card.dart';
import 'package:tuple/tuple.dart';

const kFixedRateEnabled = true;

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

class RateInfo extends ConsumerWidget {
  const RateInfo({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  final void Function(ExchangeRateType) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(
        prefsChangeNotifierProvider.select((pref) => pref.exchangeRateType));
    final isEstimated = type == ExchangeRateType.estimated;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).extension<StackColors>()!.popupBG,
        borderRadius: BorderRadius.circular(
          Constants.size.circularBorderRadius,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: kFixedRateEnabled
                  ? () async {
                      if (isEstimated) {
                        if (ref
                                .read(
                                    changeNowFixedInitialLoadStatusStateProvider
                                        .state)
                                .state ==
                            ChangeNowLoadStatus.loading) {
                          bool userPoppedDialog = false;
                          await showDialog<void>(
                            context: context,
                            builder: (context) => Consumer(
                              builder: (context, ref, __) {
                                return StackOkDialog(
                                  title: "Loading rate data...",
                                  message:
                                      "Performing initial fetch of ChangeNOW fixed rate market data",
                                  onOkPressed: (value) {
                                    userPoppedDialog = value == "OK";
                                  },
                                );
                              },
                            ),
                          );
                          if (ref
                                  .read(
                                      changeNowFixedInitialLoadStatusStateProvider
                                          .state)
                                  .state ==
                              ChangeNowLoadStatus.loading) {
                            return;
                          }
                        }
                      }

                      unawaited(showModalBottomSheet<dynamic>(
                        backgroundColor: Colors.transparent,
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) => const ExchangeRateSheet(),
                      ).then((value) {
                        if (value is ExchangeRateType && value != type) {
                          onChanged(value);
                        }
                      }));
                    }
                  : null,
              style: Theme.of(context).textButtonTheme.style?.copyWith(
                    minimumSize: MaterialStateProperty.all(
                      const Size(0, 0),
                    ),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(2),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.transparent,
                    ),
                  ),
              child: Row(
                children: [
                  Text(
                    isEstimated ? "Estimated rate" : "Fixed rate",
                    style: STextStyles.itemSubtitle(context),
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  if (kFixedRateEnabled)
                    SvgPicture.asset(
                      Assets.svg.chevronDown,
                      width: 5,
                      height: 2.5,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .infoItemLabel,
                    ),
                ],
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 1,
                ),
                child: Text(
                  isEstimated
                      ? ref.watch(estimatedRateExchangeFormProvider
                          .select((value) => value.rateDisplayString))
                      : ref.watch(fixedRateExchangeFormProvider
                          .select((value) => value.rateDisplayString)),
                  style: STextStyles.itemSubtitle12(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
