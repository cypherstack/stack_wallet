import 'package:flutter/material.dart';

import '../themes/stack_colors.dart';
import '../utilities/text_styles.dart';
import 'rounded_container.dart';

class CoinTickerTag extends StatelessWidget {
  const CoinTickerTag({super.key, required this.ticker});

  final String ticker;

  @override
  Widget build(BuildContext context) {
    return RoundedContainer(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      radiusMultiplier: 0.25,
      color: Theme.of(context).extension<StackColors>()!.ethTagBG,
      child: Text(
        ticker,
        style: STextStyles.w600_12(context).copyWith(
          color: Theme.of(context).extension<StackColors>()!.ethTagText,
        ),
      ),
    );
  }
}
