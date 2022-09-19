import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
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
        color: CFColors.background,
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
              WalletInfoRow(
                walletId: walletIds[i],
              ),
          ],
        ),
      ),
    );
  }
}
