import 'package:decimal/decimal.dart';
import 'package:epicmobile/models/paymint/fee_object_model.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/providers/ui/fee_rate_type_state_provider.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/enums/fee_rate_type_enum.dart';
import 'package:epicmobile/utilities/format.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/animated_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final feeSheetSessionCacheProvider =
    ChangeNotifierProvider<FeeSheetSessionCache>((ref) {
  return FeeSheetSessionCache();
});

class FeeSheetSessionCache extends ChangeNotifier {
  final Map<int, Decimal> fast = {};
  final Map<int, Decimal> average = {};
  final Map<int, Decimal> slow = {};

  void notify() => notifyListeners();
}

class TransactionFeeSelectionSheet extends ConsumerStatefulWidget {
  const TransactionFeeSelectionSheet({
    Key? key,
    required this.walletId,
    required this.amount,
    required this.updateChosen,
  }) : super(key: key);

  final String walletId;
  final Decimal amount;
  final Function updateChosen;

  @override
  ConsumerState<TransactionFeeSelectionSheet> createState() =>
      _TransactionFeeSelectionSheetState();
}

class _TransactionFeeSelectionSheetState
    extends ConsumerState<TransactionFeeSelectionSheet> {
  late final String walletId;
  late final Decimal amount;

  FeeObject? feeObject;

  final stringsToLoopThrough = [
    "Calculating",
    "Calculating.",
    "Calculating..",
    "Calculating...",
  ];

  Future<Decimal> feeFor({
    required int amount,
    required FeeRateType feeRateType,
    required int feeRate,
    required Coin coin,
  }) async {
    switch (feeRateType) {
      case FeeRateType.fast:
        if (ref.read(feeSheetSessionCacheProvider).fast[amount] == null) {
          final manager = ref.read(walletProvider)!;

          ref.read(feeSheetSessionCacheProvider).fast[amount] =
              Format.satoshisToAmount(
                  await manager.estimateFeeFor(amount, feeRate));
        }
        return ref.read(feeSheetSessionCacheProvider).fast[amount]!;

      case FeeRateType.average:
        if (ref.read(feeSheetSessionCacheProvider).average[amount] == null) {
          final manager = ref.read(walletProvider)!;

          ref.read(feeSheetSessionCacheProvider).average[amount] =
              Format.satoshisToAmount(
                  await manager.estimateFeeFor(amount, feeRate));
        }
        return ref.read(feeSheetSessionCacheProvider).average[amount]!;

      case FeeRateType.slow:
        if (ref.read(feeSheetSessionCacheProvider).slow[amount] == null) {
          final manager = ref.read(walletProvider)!;

          ref.read(feeSheetSessionCacheProvider).slow[amount] =
              Format.satoshisToAmount(
                  await manager.estimateFeeFor(amount, feeRate));
        }
        return ref.read(feeSheetSessionCacheProvider).slow[amount]!;
    }
  }

  String estimatedTimeToBeIncludedInNextBlock(
      int targetBlockTime, int estimatedNumberOfBlocks) {
    int time = targetBlockTime * estimatedNumberOfBlocks;

    int hours = (time / 3600).floor();
    if (hours > 1) {
      return "~$hours hours";
    } else if (hours == 1) {
      return "~$hours hour";
    }

    // less than an hour

    final string = (time / 60).toStringAsFixed(1);

    if (string == "1.0") {
      return "~1 minute";
    } else {
      if (string.endsWith(".0")) {
        return "~${(time / 60).floor()} minutes";
      }
      return "~$string minutes";
    }
  }

  @override
  void initState() {
    walletId = widget.walletId;
    amount = widget.amount;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final manager = ref.read(walletProvider)!;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).extension<StackColors>()!.popupBG,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 10,
          bottom: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldDefaultBG,
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                width: 60,
                height: 4,
              ),
            ),
            const SizedBox(
              height: 36,
            ),
            FutureBuilder(
              future: manager.fees,
              builder: (context, AsyncSnapshot<FeeObject> snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  feeObject = snapshot.data!;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Fee rate",
                      style: STextStyles.pageTitleH2(context),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    GestureDetector(
                      onTap: () {
                        final state =
                            ref.read(feeRateTypeStateProvider.state).state;
                        if (state != FeeRateType.fast) {
                          ref.read(feeRateTypeStateProvider.state).state =
                              FeeRateType.fast;
                        }
                        String? fee = getAmount(FeeRateType.fast);
                        if (fee != null) {
                          widget.updateChosen(fee);
                        }
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Radio(
                                    activeColor: Theme.of(context)
                                        .extension<StackColors>()!
                                        .radioButtonIconEnabled,
                                    value: FeeRateType.fast,
                                    groupValue: ref
                                        .watch(feeRateTypeStateProvider.state)
                                        .state,
                                    onChanged: (x) {
                                      ref
                                          .read(feeRateTypeStateProvider.state)
                                          .state = FeeRateType.fast;

                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        FeeRateType.fast.prettyName,
                                        style: STextStyles.bodyBold(context),
                                        textAlign: TextAlign.left,
                                      ),
                                      const SizedBox(
                                        width: 2,
                                      ),
                                      if (feeObject == null)
                                        AnimatedText(
                                          stringsToLoopThrough:
                                              stringsToLoopThrough,
                                          style:
                                              STextStyles.itemSubtitle(context),
                                        ),
                                      if (feeObject != null)
                                        FutureBuilder(
                                          future: feeFor(
                                              coin: manager.coin,
                                              feeRateType: FeeRateType.fast,
                                              feeRate: feeObject!.fast,
                                              amount: Format
                                                  .decimalAmountToSatoshis(
                                                      amount)),
                                          // future: manager.estimateFeeFor(
                                          //     Format.decimalAmountToSatoshis(
                                          //         amount),
                                          //     feeObject!.fast),
                                          builder: (_,
                                              AsyncSnapshot<Decimal> snapshot) {
                                            if (snapshot.connectionState ==
                                                    ConnectionState.done &&
                                                snapshot.hasData) {
                                              return Text(
                                                "(~${snapshot.data!} ${manager.coin.ticker})",
                                                style: STextStyles.itemSubtitle(
                                                    context),
                                                textAlign: TextAlign.left,
                                              );
                                            } else {
                                              return AnimatedText(
                                                stringsToLoopThrough:
                                                    stringsToLoopThrough,
                                                style: STextStyles.itemSubtitle(
                                                    context),
                                              );
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 2,
                                  ),
                                  if (feeObject == null)
                                    AnimatedText(
                                      stringsToLoopThrough:
                                          stringsToLoopThrough,
                                      style: STextStyles.itemSubtitle(context),
                                    ),
                                  if (feeObject != null)
                                    Text(
                                      estimatedTimeToBeIncludedInNextBlock(
                                        Constants.targetBlockTimeInSeconds(
                                            manager.coin),
                                        feeObject!.numberOfBlocksFast,
                                      ),
                                      style: STextStyles.itemSubtitle(context),
                                      textAlign: TextAlign.left,
                                    ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    GestureDetector(
                      onTap: () {
                        final state =
                            ref.read(feeRateTypeStateProvider.state).state;
                        if (state != FeeRateType.average) {
                          ref.read(feeRateTypeStateProvider.state).state =
                              FeeRateType.average;
                        }
                        String? fee = getAmount(FeeRateType.average);
                        if (fee != null) {
                          widget.updateChosen(fee);
                        }
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Radio(
                                    activeColor: Theme.of(context)
                                        .extension<StackColors>()!
                                        .radioButtonIconEnabled,
                                    value: FeeRateType.average,
                                    groupValue: ref
                                        .watch(feeRateTypeStateProvider.state)
                                        .state,
                                    onChanged: (x) {
                                      ref
                                          .read(feeRateTypeStateProvider.state)
                                          .state = FeeRateType.average;
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        FeeRateType.average.prettyName,
                                        style: STextStyles.bodyBold(context),
                                        textAlign: TextAlign.left,
                                      ),
                                      const SizedBox(
                                        width: 2,
                                      ),
                                      if (feeObject == null)
                                        AnimatedText(
                                          stringsToLoopThrough:
                                              stringsToLoopThrough,
                                          style:
                                              STextStyles.itemSubtitle(context),
                                        ),
                                      if (feeObject != null)
                                        FutureBuilder(
                                          future: feeFor(
                                              coin: manager.coin,
                                              feeRateType: FeeRateType.average,
                                              feeRate: feeObject!.medium,
                                              amount: Format
                                                  .decimalAmountToSatoshis(
                                                      amount)),
                                          // future: manager.estimateFeeFor(
                                          //     Format.decimalAmountToSatoshis(
                                          //         amount),
                                          //     feeObject!.fast),
                                          builder: (_,
                                              AsyncSnapshot<Decimal> snapshot) {
                                            if (snapshot.connectionState ==
                                                    ConnectionState.done &&
                                                snapshot.hasData) {
                                              return Text(
                                                "(~${snapshot.data!} ${manager.coin.ticker})",
                                                style: STextStyles.itemSubtitle(
                                                    context),
                                                textAlign: TextAlign.left,
                                              );
                                            } else {
                                              return AnimatedText(
                                                stringsToLoopThrough:
                                                    stringsToLoopThrough,
                                                style: STextStyles.itemSubtitle(
                                                    context),
                                              );
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 2,
                                  ),
                                  if (feeObject == null)
                                    AnimatedText(
                                      stringsToLoopThrough:
                                          stringsToLoopThrough,
                                      style: STextStyles.itemSubtitle(context),
                                    ),
                                  if (feeObject != null)
                                    Text(
                                      estimatedTimeToBeIncludedInNextBlock(
                                        Constants.targetBlockTimeInSeconds(
                                            manager.coin),
                                        feeObject!.numberOfBlocksAverage,
                                      ),
                                      style: STextStyles.itemSubtitle(context),
                                      textAlign: TextAlign.left,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    GestureDetector(
                      onTap: () {
                        final state =
                            ref.read(feeRateTypeStateProvider.state).state;
                        if (state != FeeRateType.slow) {
                          ref.read(feeRateTypeStateProvider.state).state =
                              FeeRateType.slow;
                        }
                        String? fee = getAmount(FeeRateType.slow);
                        print("fee $fee");
                        if (fee != null) {
                          widget.updateChosen(fee);
                        }
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Radio(
                                    activeColor: Theme.of(context)
                                        .extension<StackColors>()!
                                        .radioButtonIconEnabled,
                                    value: FeeRateType.slow,
                                    groupValue: ref
                                        .watch(feeRateTypeStateProvider.state)
                                        .state,
                                    onChanged: (x) {
                                      debugPrint(x.toString());
                                      ref
                                          .read(feeRateTypeStateProvider.state)
                                          .state = FeeRateType.slow;
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        FeeRateType.slow.prettyName,
                                        style: STextStyles.bodyBold(context),
                                        textAlign: TextAlign.left,
                                      ),
                                      const SizedBox(
                                        width: 2,
                                      ),
                                      if (feeObject == null)
                                        AnimatedText(
                                          stringsToLoopThrough:
                                              stringsToLoopThrough,
                                          style:
                                              STextStyles.itemSubtitle(context),
                                        ),
                                      if (feeObject != null)
                                        FutureBuilder(
                                          future: feeFor(
                                              coin: manager.coin,
                                              feeRateType: FeeRateType.slow,
                                              feeRate: feeObject!.slow,
                                              amount: Format
                                                  .decimalAmountToSatoshis(
                                                      amount)),
                                          // future: manager.estimateFeeFor(
                                          //     Format.decimalAmountToSatoshis(
                                          //         amount),
                                          //     feeObject!.fast),
                                          builder: (_,
                                              AsyncSnapshot<Decimal> snapshot) {
                                            if (snapshot.connectionState ==
                                                    ConnectionState.done &&
                                                snapshot.hasData) {
                                              return Text(
                                                "(~${snapshot.data!} ${manager.coin.ticker})",
                                                style: STextStyles.itemSubtitle(
                                                    context),
                                                textAlign: TextAlign.left,
                                              );
                                            } else {
                                              return AnimatedText(
                                                stringsToLoopThrough:
                                                    stringsToLoopThrough,
                                                style: STextStyles.itemSubtitle(
                                                    context),
                                              );
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 2,
                                  ),
                                  if (feeObject == null)
                                    AnimatedText(
                                      stringsToLoopThrough:
                                          stringsToLoopThrough,
                                      style: STextStyles.itemSubtitle(context),
                                    ),
                                  if (feeObject != null)
                                    Text(
                                      estimatedTimeToBeIncludedInNextBlock(
                                        Constants.targetBlockTimeInSeconds(
                                            manager.coin),
                                        feeObject!.numberOfBlocksSlow,
                                      ),
                                      style: STextStyles.itemSubtitle(context),
                                      textAlign: TextAlign.left,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String? getAmount(FeeRateType feeRateType) {
    try {
      print(feeRateType);
      var amount = Format.decimalAmountToSatoshis(this.amount);
      print(amount);
      print(ref.read(feeSheetSessionCacheProvider).fast);
      print(ref.read(feeSheetSessionCacheProvider).average);
      print(ref.read(feeSheetSessionCacheProvider).slow);
      switch (feeRateType) {
        case FeeRateType.fast:
          if (ref.read(feeSheetSessionCacheProvider).fast[amount] != null) {
            return (ref.read(feeSheetSessionCacheProvider).fast[amount]
                    as Decimal)
                .toString();
          }
          return null;

        case FeeRateType.average:
          if (ref.read(feeSheetSessionCacheProvider).average[amount] != null) {
            return (ref.read(feeSheetSessionCacheProvider).average[amount]
                    as Decimal)
                .toString();
          }
          return null;

        case FeeRateType.slow:
          print(ref.read(feeSheetSessionCacheProvider).slow);
          print(ref.read(feeSheetSessionCacheProvider).slow[amount]);
          if (ref.read(feeSheetSessionCacheProvider).slow[amount] != null) {
            return (ref.read(feeSheetSessionCacheProvider).slow[amount]
                    as Decimal)
                .toString();
          }
          return null;
      }
    } catch (e, s) {
      print("$e $s");
      return null;
    }
  }
}
