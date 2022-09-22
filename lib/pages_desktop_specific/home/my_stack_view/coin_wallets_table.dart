import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/wallet_info_row/wallet_info_row.dart';

class CoinWalletsTable extends ConsumerWidget {
  const CoinWalletsTable({
    Key? key,
    required this.walletIds,
  }) : super(key: key);

  final List<String> walletIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).extension<StackColors>()!.popupBG,
        borderRadius: BorderRadius.circular(
          Constants.size.circularBorderRadius,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        child: Column(
          children: [
            for (int i = 0; i < walletIds.length; i++)
              Column(
                children: [
                  if (i != 0)
                    const SizedBox(
                      height: 32,
                    ),
                  WalletInfoRow(
                    walletId: walletIds[i],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
