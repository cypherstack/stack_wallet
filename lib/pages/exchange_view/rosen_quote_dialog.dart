import 'package:flutter/material.dart';

import '../../models/exchange/incomplete_exchange.dart';
import '../../services/exchange/rosen/rosen_exchange.dart';
import '../../utilities/enums/exchange_rate_type_enum.dart';
import '../../utilities/util.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/dialogs/basic_dialog.dart';

Future<bool> showRosenQuoteChangedDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => BasicDialog(
        title: 'Bridge fees changed',
        message:
            'Rosen Bridge fees changed. No funds were sent. Refresh the quote, '
            'then review the updated amount before confirming again.',
        desktopHeight: 340,
        canPopWithBackButton: true,
        flex: true,
        leftButton: SecondaryButton(
          label: 'Cancel',
          buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        rightButton: PrimaryButton(
          label: 'Refresh quote',
          buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ),
    ) ??
    false;

Future<IncompleteExchangeModel> refreshRosenEstimate(
  IncompleteExchangeModel model,
) async {
  final response = await RosenExchange.instance.getEstimates(
    model.sendTicker,
    model.sendCurrency.network,
    model.receiveTicker,
    model.receiveCurrency.network,
    model.sendAmount,
    model.rateType == ExchangeRateType.fixed,
    model.reversed,
  );
  if (response.value == null || response.value!.isEmpty) {
    throw response.exception ??
        StateError('Unable to refresh the bridge quote.');
  }
  final estimate = response.value!.single;
  return IncompleteExchangeModel(
      sendCurrency: model.sendCurrency,
      receiveCurrency: model.receiveCurrency,
      rateInfo:
          '1 ${model.sendTicker.toUpperCase()} '
          '~${(estimate.estimatedAmount / model.sendAmount).toDecimal(scaleOnInfinitePrecision: 8).toStringAsFixed(8)} '
          '${model.receiveTicker.toUpperCase()}',
      sendAmount: model.sendAmount,
      receiveAmount: estimate.estimatedAmount,
      rateType: model.rateType,
      reversed: model.reversed,
      walletInitiated: model.walletInitiated,
      estimate: estimate,
    )
    ..recipientAddress = model.recipientAddress
    ..refundAddress = model.refundAddress;
}
