import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ui/fee_rate_type_state_provider.dart';
import '../../providers/wallet/send_fee_providers.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/amount/amount_formatter.dart';
import '../../utilities/enums/fee_rate_type_enum.dart';
import '../../utilities/text_styles.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../calculating_future_builder.dart';
import '../conditional_parent.dart';
import 'desktop_dialog.dart';
import 'desktop_dialog_close_button.dart';

class DesktopFeeDialog extends StatelessWidget {
  const DesktopFeeDialog({super.key, required this.fees, required this.amount});

  final SendFeeRates fees;
  final Amount? amount;

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxWidth: 450,
      maxHeight: double.infinity,
      child: Column(
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
          ...sendFeeRateTypes(fees.coin).map(
            (e) => Padding(
              padding: const EdgeInsets.only(left: 32, right: 32, bottom: 16),
              child: DesktopFeeItem(fees: fees, feeRateType: e, amount: amount),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class DesktopFeeItem extends ConsumerStatefulWidget {
  const DesktopFeeItem({
    super.key,
    required this.fees,
    required this.feeRateType,
    required this.amount,
    this.isButton = true,
  });

  final SendFeeRates fees;
  final FeeRateType feeRateType;
  final Amount? amount;
  final bool isButton;

  @override
  ConsumerState<DesktopFeeItem> createState() => _DesktopFeeItemState();
}

class _DesktopFeeItemState extends ConsumerState<DesktopFeeItem> {
  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType : ${widget.feeRateType}");
    final (fees, feeRateType) = (widget.fees, widget.feeRateType);
    final colors = Theme.of(context).extension<StackColors>()!;
    final style = STextStyles.desktopTextExtraExtraSmall(context)
        .copyWith(color: colors.textFieldActiveText);
    final coin = fees.coin;
    final fee = feeRateType.isCustom
        ? null
        : fees.estimate(ref.watch, feeRateType, amount: widget.amount);

    return ConditionalParent(
      condition: widget.isButton,
      builder: (child) => MaterialButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: () {
          ref.read(pFeeRateType.state).state = feeRateType;
          Navigator.of(context).pop();
        },
        child: child,
      ),
      child: fee == null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  feeRateType.prettyName,
                  style: style,
                  textAlign: TextAlign.left,
                ),
              ],
            )
          : FutureBuilder(
              future: fees.rates,
              builder: (_, rates) => CalculatingFutureBuilder(
                future: fee,
                style: style,
                builder: (fee) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${feeRateType.prettyName} "
                      "(~${ref.watch(pAmountFormatter(coin)).format(fee, indicatePrecisionLoss: false)})",
                      style: style,
                      textAlign: TextAlign.left,
                    ),
                    Text(
                      // A Spark fee shows while the fee rates load or fail.
                      coin is Ethereum || !rates.hasData
                          ? ""
                          : sendFeeTime(coin, rates.data!, feeRateType),
                      style: style.copyWith(
                        color: colors.textFieldActiveSearchIconRight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
