import 'package:epicpay/pages/wallet_view/wallet_view.dart';
import 'package:epicpay/providers/providers.dart';
import 'package:epicpay/utilities/constants.dart';
import 'package:epicpay/widgets/rounded_white_container.dart';
import 'package:epicpay/widgets/wallet_info_row/wallet_info_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        onPressed: () {
          if (popPrevious) Navigator.of(context).pop();
          Navigator.of(context).pushNamed(
            WalletView.routeName,
            arguments: Tuple2(
              walletId,
              ref.read(walletProvider),
            ),
          );
        },
        child: WalletInfoRow(
          walletId: walletId,
        ),
      ),
    );
  }
}
