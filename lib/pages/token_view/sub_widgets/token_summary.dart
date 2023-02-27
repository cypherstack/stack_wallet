import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/token_view/token_view.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class TokenSummary extends ConsumerWidget {
  const TokenSummary({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoundedContainer(
      color: const Color(0xFFE9EAFF), // todo: fix color
      // color: Theme.of(context).extension<StackColors>()!.,

      child: Column(
        children: [
          Text(
            ref.watch(
              walletsChangeNotifierProvider.select(
                (value) => value.getManager(walletId).walletName,
              ),
            ),
            style: STextStyles.label(context),
          ),
          Text(
            ref.watch(tokenServiceProvider.select((value) => value!.balance
                .getTotal()
                .toStringAsFixed(ref.watch(tokenServiceProvider
                    .select((value) => value!.token.decimals))))),
            style: STextStyles.label(context),
          ),
          Text(
            ref.watch(
              walletsChangeNotifierProvider.select(
                (value) => value.getManager(walletId).walletName,
              ),
            ),
            style: STextStyles.label(context),
          ),
        ],
      ),
    );
  }
}
