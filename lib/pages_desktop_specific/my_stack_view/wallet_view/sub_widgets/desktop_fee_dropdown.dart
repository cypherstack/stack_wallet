import 'package:cw_core/monero_transaction_priority.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/models.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/transaction_fee_selection_sheet.dart';
import 'package:stackwallet/pages/token_view/token_view.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/ui/fee_rate_type_state_provider.dart';
import 'package:stackwallet/providers/wallet/public_private_balance_state_provider.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/animated_text.dart';

final tokenFeeSessionCacheProvider =
    ChangeNotifierProvider<FeeSheetSessionCache>((ref) {
  return FeeSheetSessionCache();
});

class DesktopFeeDropDown extends ConsumerStatefulWidget {
  const DesktopFeeDropDown({
    Key? key,
    required this.walletId,
    this.isToken = false,
  }) : super(key: key);

  final String walletId;
  final bool isToken;

  @override
  ConsumerState<DesktopFeeDropDown> createState() => _DesktopFeeDropDownState();
}

class _DesktopFeeDropDownState extends ConsumerState<DesktopFeeDropDown> {
  late final String walletId;

  FeeObject? feeObject;
  FeeRateType feeRateType = FeeRateType.average;

  final stringsToLoopThrough = [
    "Calculating",
    "Calculating.",
    "Calculating..",
    "Calculating...",
  ];

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
            final manager =
                ref.read(walletsChangeNotifierProvider).getManager(walletId);

            if (coin == Coin.monero || coin == Coin.wownero) {
              final fee = await manager.estimateFeeFor(
                  amount, MoneroTransactionPriority.fast.raw!);
              ref.read(feeSheetSessionCacheProvider).fast[amount] = fee;
            } else if ((coin == Coin.firo || coin == Coin.firoTestNet) &&
                ref.read(publicPrivateBalanceStateProvider.state).state !=
                    "Private") {
              ref.read(feeSheetSessionCacheProvider).fast[amount] =
                  await (manager.wallet as FiroWallet)
                      .estimateFeeForPublic(amount, feeRate);
            } else {
              ref.read(feeSheetSessionCacheProvider).fast[amount] =
                  await manager.estimateFeeFor(amount, feeRate);
            }
          } else {
            final tokenWallet = ref.read(tokenServiceProvider)!;
            final fee = tokenWallet.estimateFeeFor(feeRate);
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
            final manager =
                ref.read(walletsChangeNotifierProvider).getManager(walletId);

            if (coin == Coin.monero || coin == Coin.wownero) {
              final fee = await manager.estimateFeeFor(
                  amount, MoneroTransactionPriority.regular.raw!);
              ref.read(feeSheetSessionCacheProvider).average[amount] = fee;
            } else if ((coin == Coin.firo || coin == Coin.firoTestNet) &&
                ref.read(publicPrivateBalanceStateProvider.state).state !=
                    "Private") {
              ref.read(feeSheetSessionCacheProvider).average[amount] =
                  await (manager.wallet as FiroWallet)
                      .estimateFeeForPublic(amount, feeRate);
            } else {
              ref.read(feeSheetSessionCacheProvider).average[amount] =
                  await manager.estimateFeeFor(amount, feeRate);
            }
          } else {
            final tokenWallet = ref.read(tokenServiceProvider)!;
            final fee = tokenWallet.estimateFeeFor(feeRate);
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
            final manager =
                ref.read(walletsChangeNotifierProvider).getManager(walletId);

            if (coin == Coin.monero || coin == Coin.wownero) {
              final fee = await manager.estimateFeeFor(
                  amount, MoneroTransactionPriority.slow.raw!);
              ref.read(feeSheetSessionCacheProvider).slow[amount] = fee;
            } else if ((coin == Coin.firo || coin == Coin.firoTestNet) &&
                ref.read(publicPrivateBalanceStateProvider.state).state !=
                    "Private") {
              ref.read(feeSheetSessionCacheProvider).slow[amount] =
                  await (manager.wallet as FiroWallet)
                      .estimateFeeForPublic(amount, feeRate);
            } else {
              ref.read(feeSheetSessionCacheProvider).slow[amount] =
                  await manager.estimateFeeFor(amount, feeRate);
            }
          } else {
            final tokenWallet = ref.read(tokenServiceProvider)!;
            final fee = tokenWallet.estimateFeeFor(feeRate);
            ref.read(tokenFeeSessionCacheProvider).slow[amount] = fee;
          }
        }
        return ref
            .read(widget.isToken
                ? tokenFeeSessionCacheProvider
                : feeSheetSessionCacheProvider)
            .slow[amount]!;
    }
  }

  @override
  void initState() {
    walletId = widget.walletId;
    super.initState();
  }

  String? labelSlow;
  String? labelAverage;
  String? labelFast;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final manager = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(walletId)));

    return FutureBuilder(
      future: manager.fees,
      builder: (context, AsyncSnapshot<FeeObject> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          feeObject = snapshot.data!;
        }
        return DropdownButtonHideUnderline(
          child: DropdownButton2(
            isExpanded: true,
            value: ref.watch(feeRateTypeStateProvider.state).state,
            items: [
              ...FeeRateType.values.map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: FeeDropDownChild(
                    feeObject: feeObject,
                    feeRateType: e,
                    walletId: walletId,
                    feeFor: feeFor,
                    isSelected: false,
                  ),
                ),
              ),
            ],
            onChanged: (newRateType) {
              if (newRateType is FeeRateType) {
                ref.read(feeRateTypeStateProvider.state).state = newRateType;
              }
            },
            iconStyleData: IconStyleData(
              icon: SvgPicture.asset(
                Assets.svg.chevronDown,
                width: 12,
                height: 6,
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              offset: const Offset(0, -10),
              elevation: 0,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
              ),
            ),
            menuItemStyleData: const MenuItemStyleData(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          ),
        );
      },
    );
  }
}

final sendAmountProvider =
    StateProvider.autoDispose<Amount>((_) => Amount.zero);

class FeeDropDownChild extends ConsumerWidget {
  const FeeDropDownChild({
    Key? key,
    required this.feeObject,
    required this.feeRateType,
    required this.walletId,
    required this.feeFor,
    required this.isSelected,
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
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("BUILD: $runtimeType : $feeRateType");

    final manager = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(walletId)));

    if (feeObject == null) {
      return AnimatedText(
        stringsToLoopThrough: stringsToLoopThrough,
        style: STextStyles.desktopTextExtraExtraSmall(context).copyWith(
          color:
              Theme.of(context).extension<StackColors>()!.textFieldActiveText,
        ),
      );
    } else {
      return FutureBuilder(
        future: feeFor(
          coin: manager.coin,
          feeRateType: feeRateType,
          feeRate: feeRateType == FeeRateType.fast
              ? feeObject!.fast
              : feeRateType == FeeRateType.slow
                  ? feeObject!.slow
                  : feeObject!.medium,
          amount: ref.watch(sendAmountProvider.state).state,
        ),
        builder: (_, AsyncSnapshot<Amount> snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${feeRateType.prettyName} "
                  "(~${ref.watch(pAmountFormatter(manager.coin)).format(
                        snapshot.data!,
                        indicatePrecisionLoss: false,
                      )})",
                  style:
                      STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldActiveText,
                  ),
                  textAlign: TextAlign.left,
                ),
                if (feeObject != null)
                  Text(
                    manager.coin == Coin.ethereum
                        ? ""
                        : estimatedTimeToBeIncludedInNextBlock(
                            Constants.targetBlockTimeInSeconds(manager.coin),
                            feeRateType == FeeRateType.fast
                                ? feeObject!.numberOfBlocksFast
                                : feeRateType == FeeRateType.slow
                                    ? feeObject!.numberOfBlocksSlow
                                    : feeObject!.numberOfBlocksAverage,
                          ),
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
              style: STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldActiveText,
              ),
            );
          }
        },
      );
    }
  }
}
