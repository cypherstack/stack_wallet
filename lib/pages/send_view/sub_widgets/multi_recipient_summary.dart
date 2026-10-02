import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../themes/stack_colors.dart';
import '../../../utilities/address_utils.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/amount/amount_formatter.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../wallets/models/tx_data.dart';
import '../../../widgets/custom_buttons/blue_text_button.dart';
import '../../../widgets/rounded_container.dart';
import '../../../widgets/rounded_white_container.dart';

/// A recipient of a multi-recipient payment URI, with its amount parsed for
/// the sending coin.
typedef SendRecipient = ({String address, Amount amount, String? label});

/// Converts the recipients of [paymentData] to amounts of [coin].
///
/// Returns null if any recipient has a missing, invalid, or zero amount.
List<SendRecipient>? parseUriRecipients(
  PaymentUriData paymentData,
  CryptoCurrency coin,
) {
  final List<SendRecipient> recipients = [];
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

extension SendRecipientsExt on List<SendRecipient> {
  Amount get total => map((e) => e.amount).reduce((a, b) => a + b);

  bool allValidFor(CryptoCurrency coin) =>
      every((e) => coin.validateAddress(e.address));

  List<TxRecipient> toTxRecipients(CryptoCurrency coin) => [
    for (final e in this)
      TxRecipient(
        address: e.address,
        amount: e.amount,
        isChange: false,
        addressType: coin.getAddressType(e.address)!,
      ),
  ];
}

/// Read-only list of the recipients of a multi-recipient payment URI.
class MultiRecipientSummary extends ConsumerWidget {
  const MultiRecipientSummary({
    super.key,
    required this.coin,
    required this.recipients,
    required this.onClear,
  });

  final CryptoCurrency coin;
  final List<SendRecipient> recipients;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<StackColors>()!;
    final labelStyle = Util.isDesktop
        ? STextStyles.desktopTextExtraExtraSmall(context)
        : STextStyles.smallMed12(context);
    final valueStyle = Util.isDesktop
        ? STextStyles.desktopTextExtraExtraSmall(context)
              .copyWith(color: colors.textDark)
        : STextStyles.itemSubtitle12(context);
    final formatter = ref.watch(pAmountFormatter(coin));

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${recipients.length} recipients", style: labelStyle),
            CustomTextButton(text: "Clear", onTap: onClear),
          ],
        ),
        for (final recipient in recipients) ...[
          const SizedBox(height: 12),
          if (recipient.label != null)
            Text(recipient.label!, style: labelStyle),
          SelectableText(recipient.address, style: valueStyle),
          if (!coin.validateAddress(recipient.address))
            Text(
              "Invalid address",
              style: STextStyles.label(context)
                  .copyWith(color: colors.textError),
            ),
          const SizedBox(height: 4),
          Text(formatter.format(recipient.amount), style: valueStyle),
        ],
      ],
    );

    if (Util.isDesktop) {
      return RoundedContainer(
        color: Colors.transparent,
        borderColor: colors.textFieldDefaultBG,
        child: content,
      );
    }
    return RoundedWhiteContainer(child: content);
  }
}
