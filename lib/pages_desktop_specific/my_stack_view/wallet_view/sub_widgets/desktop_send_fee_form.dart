import 'package:cs_monero/cs_monero.dart' as lib_monero;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../pages/send_view/sub_widgets/transaction_fee_selection_sheet.dart';
import '../../../../providers/providers.dart';
import '../../../../providers/wallet/public_private_balance_state_provider.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/amount/amount.dart';
import '../../../../utilities/amount/amount_formatter.dart';
import '../../../../utilities/enums/fee_rate_type_enum.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../../wallets/wallet/impl/firo_wallet.dart';
import '../../../../wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';
import '../../../../widgets/animated_text.dart';
import '../../../../widgets/conditional_parent.dart';
import '../../../../widgets/custom_buttons/blue_text_button.dart';
import '../../../../widgets/desktop/desktop_fee_dialog.dart';
import '../../../../widgets/fee_slider.dart';

class DesktopSendFeeForm extends ConsumerStatefulWidget {
  const DesktopSendFeeForm({
    super.key,
    required this.walletId,
    required this.onCustomFeeSliderChanged,
    required this.onCustomFeeOptionChanged,
  });

  final String walletId;
  final void Function(int) onCustomFeeSliderChanged;
  final void Function(bool) onCustomFeeOptionChanged;

  @override
  ConsumerState<DesktopSendFeeForm> createState() => _DesktopSendFeeFormState();
}

class _DesktopSendFeeFormState extends ConsumerState<DesktopSendFeeForm> {
  final stringsToLoopThrough = [
    "Calculating",
    "Calculating.",
    "Calculating..",
    "Calculating...",
  ];

  late final CryptoCurrency cryptoCurrency;

  bool get isEth => cryptoCurrency is Ethereum;

  bool isCustomFee = false;
  (FeeRateType, String?, String?)? feeSelectionResult;

  @override
  void initState() {
    super.initState();
    cryptoCurrency = ref.read(pWalletCoin(widget.walletId));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConditionalParent(
          condition:
              ref.watch(pWallets).getWallet(widget.walletId)
                  is ElectrumXInterface &&
              !(((cryptoCurrency is Firo) &&
                  (ref.watch(publicPrivateBalanceStateProvider.state).state ==
                          FiroType.lelantus ||
                      ref
                              .watch(publicPrivateBalanceStateProvider.state)
                              .state ==
                          FiroType.spark))),
          builder:
              (child) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  child,
                  CustomTextButton(
                    text: "Edit",
                    onTap: () async {
                      feeSelectionResult =
                          await showDialog<(FeeRateType, String?, String?)?>(
                            context: context,
                            builder:
                                (_) =>
                                    DesktopFeeDialog(walletId: widget.walletId),
                          );

                      if (feeSelectionResult != null) {
                        if (isCustomFee &&
                            feeSelectionResult!.$1 != FeeRateType.custom) {
                          isCustomFee = false;
                        } else if (!isCustomFee &&
                            feeSelectionResult!.$1 == FeeRateType.custom) {
                          isCustomFee = true;
                        }
                      }

                      setState(() {});
                    },
                  ),
                ],
              ),
          child: Text(
            "Transaction fee"
            "${isCustomFee ? "" : " (${isEth ? "max" : "estimated"})"}",
            style: STextStyles.desktopTextExtraSmall(context).copyWith(
              color:
                  Theme.of(
                    context,
                  ).extension<StackColors>()!.textFieldActiveSearchIconRight,
            ),
            textAlign: TextAlign.left,
          ),
        ),
        const SizedBox(height: 10),
        if (!isCustomFee)
          Padding(
            padding: const EdgeInsets.all(10),
            child:
                (feeSelectionResult?.$2 == null)
                    ? FutureBuilder(
                      future: ref.watch(
                        pWallets.select(
                          (value) => value.getWallet(widget.walletId).fees,
                        ),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          return DesktopFeeItem(
                            feeObject: snapshot.data,
                            feeRateType: FeeRateType.average,
                            walletId: widget.walletId,
                            isButton: false,
                            feeFor: ({
                              required Amount amount,
                              required FeeRateType feeRateType,
                              required int feeRate,
                              required CryptoCurrency coin,
                            }) async {
                              if (ref
                                      .read(feeSheetSessionCacheProvider)
                                      .average[amount] ==
                                  null) {
                                final wallet = ref
                                    .read(pWallets)
                                    .getWallet(widget.walletId);

                                if (coin is Monero || coin is Wownero) {
                                  final fee = await wallet.estimateFeeFor(
                                    amount,
                                    lib_monero.TransactionPriority.medium.value,
                                  );
                                  ref
                                          .read(feeSheetSessionCacheProvider)
                                          .average[amount] =
                                      fee;
                                } else if ((coin is Firo) &&
                                    ref
                                            .read(
                                              publicPrivateBalanceStateProvider
                                                  .state,
                                            )
                                            .state !=
                                        FiroType.public) {
                                  final firoWallet = wallet as FiroWallet;

                                  if (ref
                                          .read(
                                            publicPrivateBalanceStateProvider
                                                .state,
                                          )
                                          .state ==
                                      FiroType.lelantus) {
                                    ref
                                        .read(feeSheetSessionCacheProvider)
                                        .average[amount] = await firoWallet
                                        .estimateFeeForLelantus(amount);
                                  } else if (ref
                                          .read(
                                            publicPrivateBalanceStateProvider
                                                .state,
                                          )
                                          .state ==
                                      FiroType.spark) {
                                    ref
                                        .read(feeSheetSessionCacheProvider)
                                        .average[amount] = await firoWallet
                                        .estimateFeeForSpark(amount);
                                  }
                                } else {
                                  ref
                                      .read(feeSheetSessionCacheProvider)
                                      .average[amount] = await wallet
                                      .estimateFeeFor(amount, feeRate);
                                }
                              }
                              return ref
                                  .read(feeSheetSessionCacheProvider)
                                  .average[amount]!;
                            },
                            isSelected: true,
                          );
                        } else {
                          return Row(
                            children: [
                              AnimatedText(
                                stringsToLoopThrough: stringsToLoopThrough,
                                style: STextStyles.desktopTextExtraExtraSmall(
                                  context,
                                ).copyWith(
                                  color:
                                      Theme.of(context)
                                          .extension<StackColors>()!
                                          .textFieldActiveText,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    )
                    : (cryptoCurrency is Firo) &&
                        ref
                                .watch(publicPrivateBalanceStateProvider.state)
                                .state ==
                            FiroType.lelantus
                    ? Builder(
                      builder: (context) {
                        final lelantusFee = ref
                            .watch(pAmountFormatter(cryptoCurrency))
                            .format(
                              Amount(
                                rawValue: BigInt.parse("3794"),
                                fractionDigits: cryptoCurrency.fractionDigits,
                              ),
                              indicatePrecisionLoss: false,
                            );
                        return Text(
                          "~$lelantusFee",
                          style: STextStyles.desktopTextExtraExtraSmall(
                            context,
                          ).copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).extension<StackColors>()!.textFieldActiveText,
                          ),
                          textAlign: TextAlign.left,
                        );
                      },
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          feeSelectionResult?.$2 ?? "",
                          style: STextStyles.desktopTextExtraExtraSmall(
                            context,
                          ).copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).extension<StackColors>()!.textFieldActiveText,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          feeSelectionResult?.$3 ?? "",
                          style: STextStyles.desktopTextExtraExtraSmall(
                            context,
                          ).copyWith(
                            color:
                                Theme.of(context)
                                    .extension<StackColors>()!
                                    .textFieldActiveSearchIconRight,
                          ),
                        ),
                      ],
                    ),
          ),
        if (isCustomFee)
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 16),
            child: FeeSlider(
              coin: cryptoCurrency,
              onSatVByteChanged: widget.onCustomFeeSliderChanged,
            ),
          ),
      ],
    );
  }
}
