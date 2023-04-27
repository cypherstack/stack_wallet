import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TxIcon extends ConsumerWidget {
  const TxIcon({
    Key? key,
    required this.transaction,
    required this.currentHeight,
    required this.coin,
  }) : super(key: key);

  final Transaction transaction;
  final int currentHeight;
  final Coin coin;

  static const Size size = Size(32, 32);

  String _getAssetName(
      bool isCancelled, bool isReceived, bool isPending, WidgetRef ref) {
    if (!isReceived && transaction.subType == TransactionSubType.mint) {
      if (isCancelled) {
        return Assets.svg.anonymizeFailed;
      }
      if (isPending) {
        return Assets.svg.anonymizePending;
      }
      return Assets.svg.anonymize;
    }

    if (isReceived) {
      if (isCancelled) {
        return ref.watch(themeProvider).assets.receiveCancelled;
      }
      if (isPending) {
        return ref.watch(themeProvider).assets.receivePending;
      }
      return ref.watch(themeProvider).assets.receive;
    } else {
      if (isCancelled) {
        return ref.watch(themeProvider).assets.sendCancelled;
      }
      if (isPending) {
        return ref.watch(themeProvider).assets.sendPending;
      }
      return ref.watch(themeProvider).assets.send;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txIsReceived = transaction.type == TransactionType.incoming;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Center(
        child: SvgPicture.asset(
          _getAssetName(
            transaction.isCancelled,
            txIsReceived,
            !transaction.isConfirmed(
              currentHeight,
              coin.requiredConfirmations,
            ),
            ref,
          ),
          width: size.width,
          height: size.height,
        ),
      ),
    );
  }
}
