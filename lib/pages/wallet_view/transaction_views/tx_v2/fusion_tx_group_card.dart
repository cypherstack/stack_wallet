import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/tx_icon.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';

class FusionTxGroup {
  final List<TransactionV2> transactions;
  FusionTxGroup(this.transactions);
}

class FusionTxGroupCard extends ConsumerWidget {
  const FusionTxGroupCard({super.key, required this.group});

  final FusionTxGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletId = group.transactions.first.walletId;

    final coin = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(walletId).coin));

    final currentHeight = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(walletId).currentHeight));

    return Material(
      color: Theme.of(context).extension<StackColors>()!.popupBG,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(Constants.size.circularBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: RawMaterialButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
          ),
          onPressed: () async {
            if (Util.isDesktop) {
              // await showDialog<void>(
              //   context: context,
              //   builder: (context) => DesktopDialog(
              //     maxHeight: MediaQuery.of(context).size.height - 64,
              //     maxWidth: 580,
              //     child: TransactionV2DetailsView(
              //       transaction: _transaction,
              //       coin: coin,
              //       walletId: walletId,
              //     ),
              //   ),
              // );
            } else {
              // unawaited(
              //   Navigator.of(context).pushNamed(
              //     TransactionV2DetailsView.routeName,
              //     arguments: (
              //     tx: _transaction,
              //     coin: coin,
              //     walletId: walletId,
              //     ),
              //   ),
              // );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                TxIcon(
                  transaction: group.transactions.first,
                  coin: coin,
                  currentHeight: currentHeight,
                ),
                const SizedBox(
                  width: 14,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Fusions",
                                style: STextStyles.itemSubtitle12(context),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Builder(
                                builder: (_) {
                                  return Text(
                                    "${group.transactions.length} fusion transactions",
                                    style: STextStyles.itemSubtitle12(context),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        // crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                Format.extractDateFrom(
                                  group.transactions.last.timestamp,
                                ),
                                style: STextStyles.label(context),
                              ),
                            ),
                          ),
                          // if (ref.watch(prefsChangeNotifierProvider
                          //     .select((value) => value.externalCalls)))
                          //   const SizedBox(
                          //     width: 10,
                          //   ),
                          // if (ref.watch(prefsChangeNotifierProvider
                          //     .select((value) => value.externalCalls)))
                          //   Flexible(
                          //     child: FittedBox(
                          //       fit: BoxFit.scaleDown,
                          //       child: Builder(
                          //         builder: (_) {
                          //           return Text(
                          //             "$prefix${Amount.fromDecimal(
                          //               amount.decimal * price,
                          //               fractionDigits: 2,
                          //             ).fiatString(
                          //               locale: locale,
                          //             )} $baseCurrency",
                          //             style: STextStyles.label(context),
                          //           );
                          //         },
                          //       ),
                          //     ),
                          //   ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
