import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/pages/wallet_view/wallet_view.dart';
import 'package:stackduo/providers/providers.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';
import 'package:stackduo/widgets/rounded_white_container.dart';
import 'package:stackduo/widgets/wallet_info_row/wallet_info_row.dart';
import 'package:tuple/tuple.dart';

class WalletSheetCard extends ConsumerWidget {
  const WalletSheetCard({
    Key? key,
    required this.walletId,
    this.popPrevious = false,
  }) : super(key: key);

  final String walletId;
  final bool popPrevious;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: MaterialButton(
        // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
        key: Key("walletsSheetItemButtonKey_$walletId"),
        padding: const EdgeInsets.all(5),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        onPressed: () async {
          final manager =
              ref.read(walletsChangeNotifierProvider).getManager(walletId);
          if (manager.coin == Coin.monero) {
            await manager.initializeExisting();
          }
          if (popPrevious) Navigator.of(context).pop();
          Navigator.of(context).pushNamed(
            WalletView.routeName,
            arguments: Tuple2(
                walletId,
                ref
                    .read(walletsChangeNotifierProvider)
                    .getManagerProvider(walletId)),
          );
        },
        child: WalletInfoRow(
          walletId: walletId,
        ),
      ),
    );
  }
}
