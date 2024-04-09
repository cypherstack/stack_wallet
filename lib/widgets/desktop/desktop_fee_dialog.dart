import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/cw_legacy/monero_transasction_priority.dart';
import 'package:stackwallet/models/models.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/transaction_fee_selection_sheet.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_fee_dropdown.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/wallet/public_private_balance_state_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/wallets/isar/providers/eth/current_token_wallet_provider.dart';
import 'package:stackwallet/wallets/wallet/impl/firo_wallet.dart';
import 'package:stackwallet/widgets/animated_text.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';

class DesktopFeeDialog extends ConsumerStatefulWidget {
  const DesktopFeeDialog({
    Key? key,
    required this.walletId,
    this.isToken = false,
  }) : super(key: key);

  final String walletId;
  final bool isToken;

  @override
  ConsumerState<DesktopFeeDialog> createState() => _DesktopFeeDialogState();
}

class _DesktopFeeDialogState extends ConsumerState<DesktopFeeDialog> {
  late final String walletId;

  FeeObject? feeObject;
  FeeRateType feeRateType = FeeRateType.average;

  Future<Amount> feeFor({
    required Amount amount,
    required FeeRateType feeRateType,
    required int feeRate,
    required Coin coin,
  }) async {
    switch (feeRateType) {
      case FeeRateType.fast:
        if (ref
                .read(widget.isToken
                    ? tokenFeeSessionCacheProvider
                    : feeSheetSessionCacheProvider)
                .fast[amount] ==
            null) {
          if (widget.isToken == false) {
            final wallet = ref.read(pWallets).getWallet(walletId);

            if (coin == Coin.monero || coin == Coin.wownero) {
              final fee = await wallet.estimateFeeFor(
                  amount, MoneroTransactionPriority.fast.raw!);
              ref.read(feeSheetSessionCacheProvider).fast[amount] = fee;
            } else if (coin == Coin.firo || coin == Coin.firoTestNet) {
              final Amount fee;
              switch (ref.read(publicPrivateBalanceStateProvider.state).state) {
                case FiroType.spark:
                  fee =
                      await (wallet as FiroWallet).estimateFeeForSpark(amount);
                case FiroType.lelantus:
                  fee = await (wallet as FiroWallet)
                      .estimateFeeForLelantus(amount);
                case FiroType.public:
                  fee = await (wallet as FiroWallet)
                      .estimateFeeFor(amount, feeRate);
              }
              ref.read(feeSheetSessionCacheProvider).fast[amount] = fee;
            } else {
              ref.read(feeSheetSessionCacheProvider).fast[amount] =
                  await wallet.estimateFeeFor(amount, feeRate);
            }
          } else {
            final tokenWallet = ref.read(pCurrentTokenWallet)!;
            final fee = await tokenWallet.estimateFeeFor(amount, feeRate);
            ref.read(tokenFeeSessionCacheProvider).fast[amount] = fee;
          }
        }
        return ref
            .read(widget.isToken
                ? tokenFeeSessionCacheProvider
                : feeSheetSessionCacheProvider)
            .fast[amount]!;

      case FeeRateType.average:
        if (ref
                .read(widget.isToken
                    ? tokenFeeSessionCacheProvider
                    : feeSheetSessionCacheProvider)
                .average[amount] ==
            null) {
          if (widget.isToken == false) {
            final wallet = ref.read(pWallets).getWallet(walletId);

            if (coin == Coin.monero || coin == Coin.wownero) {
              final fee = await wallet.estimateFeeFor(
                  amount, MoneroTransactionPriority.regular.raw!);
              ref.read(feeSheetSessionCacheProvider).average[amount] = fee;
            } else if (coin == Coin.firo || coin == Coin.firoTestNet) {
              final Amount fee;
              switch (ref.read(publicPrivateBalanceStateProvider.state).state) {
                case FiroType.spark:
                  fee =
                      await (wallet as FiroWallet).estimateFeeForSpark(amount);
                case FiroType.lelantus:
                  fee = await (wallet as FiroWallet)
                      .estimateFeeForLelantus(amount);
                case FiroType.public:
                  fee = await (wallet as FiroWallet)
                      .estimateFeeFor(amount, feeRate);
              }
              ref.read(feeSheetSessionCacheProvider).average[amount] = fee;
            } else {
              ref.read(feeSheetSessionCacheProvider).average[amount] =
                  await wallet.estimateFeeFor(amount, feeRate);
            }
          } else {
            final tokenWallet = ref.read(pCurrentTokenWallet)!;
            final fee = await tokenWallet.estimateFeeFor(amount, feeRate);
            ref.read(tokenFeeSessionCacheProvider).average[amount] = fee;
          }
        }
        return ref
            .read(widget.isToken
                ? tokenFeeSessionCacheProvider
                : feeSheetSessionCacheProvider)
            .average[amount]!;

      case FeeRateType.slow:
        if (ref
                .read(widget.isToken
                    ? tokenFeeSessionCacheProvider
                    : feeSheetSessionCacheProvider)
                .slow[amount] ==
            null) {
          if (widget.isToken == false) {
            final wallet = ref.read(pWallets).getWallet(walletId);

            if (coin == Coin.monero || coin == Coin.wownero) {
              final fee = await wallet.estimateFeeFor(
                  amount, MoneroTransactionPriority.slow.raw!);
              ref.read(feeSheetSessionCacheProvider).slow[amount] = fee;
            } else if (coin == Coin.firo || coin == Coin.firoTestNet) {
              final Amount fee;
              switch (ref.read(publicPrivateBalanceStateProvider.state).state) {
                case FiroType.spark:
                  fee =
                      await (wallet as FiroWallet).estimateFeeForSpark(amount);
                case FiroType.lelantus:
                  fee = await (wallet as FiroWallet)
                      .estimateFeeForLelantus(amount);
                case FiroType.public:
                  fee = await (wallet as FiroWallet)
                      .estimateFeeFor(amount, feeRate);
              }
              ref.read(feeSheetSessionCacheProvider).slow[amount] = fee;
            } else {
              ref.read(feeSheetSessionCacheProvider).slow[amount] =
                  await wallet.estimateFeeFor(amount, feeRate);
            }
          } else {
            final tokenWallet = ref.read(pCurrentTokenWallet)!;
            final fee = await tokenWallet.estimateFeeFor(amount, feeRate);
            ref.read(tokenFeeSessionCacheProvider).slow[amount] = fee;
          }
        }
        return ref
            .read(widget.isToken
                ? tokenFeeSessionCacheProvider
                : feeSheetSessionCacheProvider)
            .slow[amount]!;
      default:
        return Amount.zero;
    }
  }

  @override
  void initState() {
    walletId = widget.walletId;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxWidth: 450,
      maxHeight: double.infinity,
      child: FutureBuilder(
        future: ref.watch(
          pWallets.select(
            (value) => value.getWallet(walletId).fees,
          ),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            feeObject = snapshot.data!;
          }

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      "Choose fee",
                      style: STextStyles.desktopH3(context),
                    ),
                  ),
                  const DesktopDialogCloseButton(),
                ],
              ),
              ...FeeRateType.values.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(
                    left: 32,
                    right: 32,
                    bottom: 16,
                  ),
                  child: DesktopFeeItem(
                    feeObject: feeObject,
                    feeRateType: e,
                    walletId: walletId,
                    feeFor: feeFor,
                    isSelected: false,
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
            ],
          );
        },
      ),
    );
  }
}

class DesktopFeeItem extends ConsumerStatefulWidget {
  const DesktopFeeItem({
    Key? key,
    required this.feeObject,
    required this.feeRateType,
    required this.walletId,
    required this.feeFor,
    required this.isSelected,
    this.isButton = true,
  }) : super(key: key);

  final FeeObject? feeObject;
  final FeeRateType feeRateType;
  final String walletId;
  final Future<Amount> Function({
    required Amount amount,
    required FeeRateType feeRateType,
    required int feeRate,
    required Coin coin,
  }) feeFor;
  final bool isSelected;
  final bool isButton;

  @override
  ConsumerState<DesktopFeeItem> createState() => _DesktopFeeItemState();
}

class _DesktopFeeItemState extends ConsumerState<DesktopFeeItem> {
  String? feeString;
  String? timeString;

  static const stringsToLoopThrough = [
    "Calculating",
    "Calculating.",
    "Calculating..",
    "Calculating...",
  ];

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
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType : ${widget.feeRateType}");

    return ConditionalParent(
      condition: widget.isButton,
      builder: (child) => MaterialButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: () {
          Navigator.of(context).pop(
            (
              widget.feeRateType,
              feeString,
              timeString,
            ),
          );
        },
        child: child,
      ),
      child: Builder(
        builder: (_) {
          if (!widget.isButton) {
            final coin = ref.watch(
              pWallets.select(
                (value) => value.getWallet(widget.walletId).info.coin,
              ),
            );
            if ((coin == Coin.firo || coin == Coin.firoTestNet) &&
                ref.watch(publicPrivateBalanceStateProvider.state).state ==
                    "Private") {
              return Text(
                "~${ref.watch(pAmountFormatter(coin)).format(
                      Amount(
                        rawValue: BigInt.parse("3794"),
                        fractionDigits: coin.decimals,
                      ),
                      indicatePrecisionLoss: false,
                    )}",
                style: STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldActiveText,
                ),
                textAlign: TextAlign.left,
              );
            }
          }

          if (widget.feeRateType == FeeRateType.custom) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.feeRateType.prettyName,
                  style:
                      STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldActiveText,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            );
          }

          final wallet = ref.watch(
              pWallets.select((value) => value.getWallet(widget.walletId)));

          if (widget.feeObject == null) {
            return AnimatedText(
              stringsToLoopThrough: stringsToLoopThrough,
              style: STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldActiveText,
              ),
            );
          } else {
            return FutureBuilder(
              future: widget.feeFor(
                coin: wallet.info.coin,
                feeRateType: widget.feeRateType,
                feeRate: widget.feeRateType == FeeRateType.fast
                    ? widget.feeObject!.fast
                    : widget.feeRateType == FeeRateType.slow
                        ? widget.feeObject!.slow
                        : widget.feeObject!.medium,
                amount: ref.watch(sendAmountProvider.state).state,
              ),
              builder: (_, AsyncSnapshot<Amount> snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  feeString = "${widget.feeRateType.prettyName} "
                      "(~${ref.watch(pAmountFormatter(wallet.info.coin)).format(
                            snapshot.data!,
                            indicatePrecisionLoss: false,
                          )})";

                  timeString = wallet.info.coin == Coin.ethereum
                      ? ""
                      : estimatedTimeToBeIncludedInNextBlock(
                          Constants.targetBlockTimeInSeconds(wallet.info.coin),
                          widget.feeRateType == FeeRateType.fast
                              ? widget.feeObject!.numberOfBlocksFast
                              : widget.feeRateType == FeeRateType.slow
                                  ? widget.feeObject!.numberOfBlocksSlow
                                  : widget.feeObject!.numberOfBlocksAverage,
                        );

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        feeString!,
                        style: STextStyles.desktopTextExtraExtraSmall(context)
                            .copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textFieldActiveText,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      if (widget.feeObject != null)
                        Text(
                          timeString!,
                          style: STextStyles.desktopTextExtraExtraSmall(context)
                              .copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textFieldActiveSearchIconRight,
                          ),
                        ),
                    ],
                  );
                } else {
                  return AnimatedText(
                    stringsToLoopThrough: stringsToLoopThrough,
                    style: STextStyles.desktopTextExtraExtraSmall(context)
                        .copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldActiveText,
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}
