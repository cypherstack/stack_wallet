import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../themes/stack_colors.dart';
import '../../../utilities/address_utils.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/amount/amount_formatter.dart';
import '../../../utilities/amount/amount_unit.dart';
import '../../../utilities/util.dart';
import '../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../wallets/models/tx_data.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/dialogs/basic_dialog.dart';
import '../frost_ms/recipient.dart';

/// Converts the recipients of [paymentData] to amounts of [coin].
///
/// Returns null if any recipient has a missing, invalid, or zero amount.
List<RecipientData>? parseUriRecipients(
  PaymentUriData paymentData,
  CryptoCurrency coin,
) {
  final List<RecipientData> recipients = [];
  for (final recipient in paymentData.recipients) {
    final amount = recipient.amount == null
        ? null
        : Amount.tryParseCanonicalAmount(
            recipient.amount!,
            fractionDigits: coin.fractionDigits,
            truncateOverprecision: true,
          );
    if (amount == null || amount <= Amount.zero) {
      return null;
    }
    recipients.add((
      address: recipient.address,
      amount: amount,
      label: recipient.label,
    ));
  }
  return recipients;
}

extension RecipientDataListExt on List<RecipientData> {
  /// The sum of the amounts, or null if any recipient is missing one.
  Amount? get total {
    Amount? sum;
    for (final e in this) {
      if (e.amount == null) {
        return null;
      }
      sum = sum == null ? e.amount : sum + e.amount!;
    }
    return sum;
  }

  /// Whether every recipient has a valid address and an amount above zero.
  bool isValidFor(CryptoCurrency coin) => every(
    (e) =>
        coin.validateAddress(e.address) &&
        e.amount != null &&
        e.amount! > Amount.zero,
  );

  /// One transaction output per recipient. Requires [isValidFor].
  List<TxRecipient> toTxRecipients(CryptoCurrency coin) => [
    for (final e in this)
      TxRecipient(
        address: e.address,
        amount: e.amount!,
        isChange: false,
        addressType: coin.getAddressType(e.address)!,
      ),
  ];
}

/// Asks whether to replace the recipients on screen with the [count]
/// recipients of a scanned or pasted payment request.
Future<bool> confirmReplaceRecipients(
  BuildContext context, {
  required int count,
}) async {
  final replace = await showDialog<bool>(
    context: context,
    builder: (context) => BasicDialog(
      title: "Replace recipients?",
      message:
          "This payment request has $count recipients. Replace the "
          "recipients you have entered with them?",
      desktopHeight: double.infinity,
      desktopWidth: 450,
      leftButton: SecondaryButton(
        label: "Cancel",
        buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
        onPressed: () => Navigator.of(context).pop(false),
      ),
      rightButton: PrimaryButton(
        label: "Replace",
        buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
        onPressed: () => Navigator.of(context).pop(true),
      ),
    ),
  );
  return replace ?? false;
}

/// A form for each recipient of a transaction with several recipients, and a
/// button to add another.
class RecipientForms extends StatelessWidget {
  const RecipientForms({
    super.key,
    required this.walletId,
    required this.coin,
    required this.indexes,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
    required this.onMultiRecipientUri,
  });

  final String walletId;
  final CryptoCurrency coin;

  /// The [pRecipient] index of each recipient's form, in order.
  final List<int> indexes;
  final VoidCallback onChanged;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(PaymentUriData paymentData) onMultiRecipientUri;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, index) in indexes.indexed)
          Padding(
            key: Key("recipientKey_$index"),
            padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
            child: Recipient(
              walletId: walletId,
              index: index,
              displayNumber: i + 1,
              coin: coin,
              onChanged: onChanged,
              remove: () => onRemove(index),
              addAnotherRecipientTapped: onAdd,
              // Send all is not offered with several recipients.
              sendAllTapped: () => "",
              onMultiRecipientUri: onMultiRecipientUri,
            ),
          ),
        const SizedBox(height: 16),
        SecondaryButton(
          label: "Add recipient",
          width: double.infinity,
          buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

/// Each recipient's address and amount, separated by dividers, for the
/// confirmation screen.
class RecipientAmountList extends ConsumerWidget {
  const RecipientAmountList({
    super.key,
    required this.coin,
    required this.recipients,
    this.labels,
    required this.labelStyle,
    required this.valueStyle,
  });

  final CryptoCurrency coin;
  final List<TxRecipient> recipients;

  /// The payment request's names for [recipients], in the same order.
  final List<String?>? labels;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<StackColors>()!;
    final formatter = ref.watch(pAmountFormatter(coin));

    final divider = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(height: 1, color: colors.backgroundAppBar),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < recipients.length; i++) ...[
          if (i > 0) divider,
          Text(
            (labels != null && i < labels!.length ? labels![i] : null) ??
                "Recipient ${i + 1}",
            style: labelStyle,
          ),
          const SizedBox(height: 4),
          SelectableText(recipients[i].address, style: valueStyle),
          const SizedBox(height: 8),
          Row(
            children: [
              Text("Amount", style: labelStyle),
              const SizedBox(width: 12),
              Expanded(
                child: SelectableText(
                  // Without trailing zeros, e.g. "1 XMR" rather than
                  // "1.000000000000 XMR".
                  "${formatter.formatEditable(recipients[i].amount)} "
                  "${formatter.unit.unitForCoin(coin)}",
                  style: valueStyle,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
