import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/amount/amount_formatter.dart';
import '../../utilities/util.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/detail_item.dart';
import '../../widgets/rounded_white_container.dart';
import 'slatepack_popup.dart';

/// What an imported slatepack will do, with a button to go ahead. Pops true
/// when the user confirms.
class SlatepackSummaryDialog extends ConsumerWidget {
  const SlatepackSummaryDialog({
    super.key,
    required this.title,
    required this.coin,
    required this.actionLabel,
    this.amount,
    this.fee,
    this.details = const [],
  });

  final String title;
  final CryptoCurrency coin;
  final String actionLabel;
  final Amount? amount;
  final Amount? fee;

  /// Extra label and value rows shown under the amount and fee.
  final List<(String, String)> details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Util.isDesktop;
    final colors = Theme.of(context).extension<StackColors>()!;
    final formatter = ref.watch(pAmountFormatter(coin));

    final rows = <(String, String)>[
      if (amount != null) ("Amount", formatter.format(amount!)),
      if (fee != null) ("Fee", formatter.format(fee!)),
      ...details,
    ];

    return SlatepackPopupLayout(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoundedWhiteContainer(
            padding: EdgeInsets.zero,
            borderColor: isDesktop ? colors.backgroundAppBar : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  if (i > 0) const DetailDivider(),
                  DetailItem(title: rows[i].$1, detail: rows[i].$2),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: "Cancel",
                  buttonHeight: isDesktop ? ButtonHeight.l : null,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(
                  label: actionLabel,
                  buttonHeight: isDesktop ? ButtonHeight.l : null,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
