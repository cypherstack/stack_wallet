import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/rounded_container.dart';

class SplitTransactionWarning extends StatelessWidget {
  const SplitTransactionWarning({super.key, required this.transactionCount});

  final int transactionCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<StackColors>()!;
    return RoundedContainer(
      color: colors.warningBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                Assets.svg.alertCircle,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(colors.warningForeground, .srcIn),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Warning: split payment',
                  style: STextStyles.pageTitleH2(context)
                      .copyWith(color: colors.warningForeground),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This payment will be sent as $transactionCount '
            'separate transactions. Some vendors and swap services '
            'require a single transaction and may not credit '
            'your full payment.\n\n'
            'Only continue if the recipient accepts split payments. '
            'If you are unsure, go back and contact the recipient '
            'before sending.',
            style: STextStyles.smallMed14(context)
                .copyWith(color: colors.warningForeground),
          ),
        ],
      ),
    );
  }
}
