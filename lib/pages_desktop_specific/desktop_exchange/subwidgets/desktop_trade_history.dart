import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/pages/exchange_view/trade_details_view.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/desktop_all_trades_view.dart';
import 'package:stackwallet/providers/exchange/trade_sent_from_stack_lookup_provider.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/trade_card.dart';

import '../../../db/main_db.dart';

class DesktopTradeHistory extends ConsumerStatefulWidget {
  const DesktopTradeHistory({Key? key}) : super(key: key);

  @override
  ConsumerState<DesktopTradeHistory> createState() =>
      _DesktopTradeHistoryState();
}

class _DesktopTradeHistoryState extends ConsumerState<DesktopTradeHistory> {
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

  @override
  Widget build(BuildContext context) {
    final trades =
        ref.watch(tradesServiceProvider.select((value) => value.trades));

    final tradeCount = trades.length;
    final hasHistory = tradeCount > 0;

    if (hasHistory) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent trades",
                style: STextStyles.desktopTextExtraExtraSmall(context),
              ),
              CustomTextButton(
                text: "See all",
                onTap: () {
                  Navigator.of(context)
                      .pushNamed(DesktopAllTradesView.routeName);
                },
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              primary: false,
              itemBuilder: (context, index) {
                BorderRadius? radius;
                if (index == tradeCount - 1) {
                  radius = _borderRadiusLast;
                } else if (index == 0) {
                  radius = _borderRadiusFirst;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).extension<StackColors>()!.popupBG,
                    borderRadius: radius,
                  ),
                  child: TradeCard(
                    key: Key("tradeCard_${trades[index].uuid}"),
                    trade: trades[index],
                    onTap: () async {
                      final String tradeId = trades[index].tradeId;

                      final lookup =
                          ref.read(tradeSentFromStackLookupProvider).all;

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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Trade details",
                                                  style: STextStyles.desktopH3(
                                                      context),
                                                ),
                                                DesktopDialogCloseButton(
                                                  onPressedOverride:
                                                      Navigator.of(
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Trade details",
                                                  style: STextStyles.desktopH3(
                                                      context),
                                                ),
                                                DesktopDialogCloseButton(
                                                  onPressedOverride:
                                                      Navigator.of(
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
                                                transactionIfSentFromStack:
                                                    null,
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
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return Container(
                  height: 1,
                  color: Theme.of(context).extension<StackColors>()!.background,
                );
              },
              itemCount: tradeCount,
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent trades",
            style: STextStyles.desktopTextExtraExtraSmall(context),
          ),
          const SizedBox(
            height: 16,
          ),
          RoundedWhiteContainer(
            child: Center(
              child: Text(
                "Trades will appear here",
                style: STextStyles.desktopTextExtraExtraSmall(context),
              ),
            ),
          ),
        ],
      );
    }
  }
}
