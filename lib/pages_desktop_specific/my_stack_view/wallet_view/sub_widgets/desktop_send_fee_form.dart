import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/providers.dart';
import '../../../../providers/ui/fee_rate_type_state_provider.dart';
import '../../../../providers/wallet/public_private_balance_state_provider.dart';
import '../../../../providers/wallet/send_fee_providers.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/amount/amount.dart';
import '../../../../utilities/enums/fee_rate_type_enum.dart';
import '../../../../utilities/eth_commons.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../../widgets/conditional_parent.dart';
import '../../../../widgets/custom_buttons/blue_text_button.dart';
import '../../../../widgets/desktop/desktop_fee_dialog.dart';
import '../../../../widgets/eth_fee_form.dart';
import '../../../../widgets/fee_slider.dart';

class SendFeeAmount extends ChangeNotifier {
  Amount? _value;
  bool _isTyped = false;

  Amount? get value => _value;

  /// Whether the fee follows [value] once typing pauses.
  bool get isTyped => _isTyped;

  void typed(Amount? amount) => _set(amount, isTyped: true);

  /// Each sync notifies, so a fee that failed is retried on the same amount
  /// too.
  void sync(Amount? amount) => _set(amount, isTyped: false);

  void _set(Amount? amount, {required bool isTyped}) {
    _value = amount;
    _isTyped = isTyped;
    notifyListeners();
  }
}

class DesktopSendFeeForm extends ConsumerStatefulWidget {
  const DesktopSendFeeForm({
    super.key,
    required this.walletId,
    required this.isToken,
    required this.amount,
    required this.onCustomFeeSliderChanged,
    this.onCustomEip1559FeeOptionChanged,
  });

  final String walletId;
  final bool isToken;
  final SendFeeAmount amount;
  final void Function(int) onCustomFeeSliderChanged;
  final void Function(EthEIP1559Fee?)? onCustomEip1559FeeOptionChanged;

  @override
  ConsumerState<DesktopSendFeeForm> createState() => _DesktopSendFeeFormState();
}

class _DesktopSendFeeFormState extends ConsumerState<DesktopSendFeeForm>
    with SendFeeForm {
  late final CryptoCurrency cryptoCurrency;

  bool get isEth => cryptoCurrency is Ethereum;

  @override
  void initState() {
    super.initState();
    cryptoCurrency = ref.read(pWalletCoin(widget.walletId));
    fees = SendFeeRates(
      ref.read,
      walletId: widget.walletId,
      isToken: widget.isToken,
    );
    feeAmount = widget.amount.value;
    widget.amount.addListener(_amountChanged);

    // A send form opened over another one shares its fee rate type, and a
    // Custom level picked in the other form has no custom fee rate in this one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(pFeeRateType.state).state = FeeRateType.average;
      }
    });
  }

  void _amountChanged() => widget.amount.isTyped
      ? followFeeAmount(widget.amount.value)
      : setFeeAmount(widget.amount.value);

  void _editFee() => chooseFee(
    (fees, amount) => showDialog<void>(
      context: context,
      builder: (_) => DesktopFeeDialog(fees: fees, amount: amount),
    ),
  );

  @override
  void dispose() {
    widget.amount.removeListener(_amountChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(publicPrivateBalanceStateProvider, (_, __) => retryFee());
    final feeRateType = ref.watch(pFeeRateType);
    final isCustomFee = feeRateType.isCustom;
    final locale = ref.watch(
      localeServiceChangeNotifierProvider.select((value) => value.locale),
    );
    final canPick = canPickFeeRateType(
      cryptoCurrency,
      ref.watch(publicPrivateBalanceStateProvider.state).state,
    );
    final canEditFees = canPick && cryptoCurrency is! Xelis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConditionalParent(
          condition: canEditFees,
          builder: (child) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              child,
              CustomTextButton(text: "Edit", onTap: _editFee),
            ],
          ),
          child: Text(
            isCustomFee && canPick || cryptoCurrency is Xelis
                ? "Transaction fee"
                : "Transaction fee (${isEth ? "max" : "estimated"})",
            style: STextStyles.desktopTextExtraSmall(context).copyWith(
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .textFieldActiveSearchIconRight,
            ),
            textAlign: TextAlign.left,
          ),
        ),
        const SizedBox(height: 10),
        if (cryptoCurrency is Xelis)
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text('Calculated when reviewing'),
          )
        else if (!isCustomFee || !canPick)
          Padding(
            padding: const EdgeInsets.all(10),
            child: DesktopFeeItem(
              fees: fees,
              feeRateType: canPick ? feeRateType : FeeRateType.average,
              amount: feeAmount,
              isButton: false,
            ),
          ),
        if (isCustomFee && isEth)
          EthFeeForm(
            locale: locale,
            minGasLimit: widget.isToken
                ? kEthereumTokenMinGasLimit
                : kEthereumMinGasLimit,
            stateChanged: (value) =>
                widget.onCustomEip1559FeeOptionChanged?.call(value),
          ),
        if (isCustomFee && canPick && !isEth)
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
