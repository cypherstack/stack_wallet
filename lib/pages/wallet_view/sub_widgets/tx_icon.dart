import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

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
      bool isCancelled, bool isReceived, bool isPending, ThemeAssets assets) {
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
        return assets.receive;
      }
      if (isPending) {
        return assets.receivePending;
      }
      return assets.receive;
    } else {
      if (isCancelled) {
        return assets.sendCancelled;
      }
      if (isPending) {
        return assets.sendPending;
      }
      return assets.send;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txIsReceived = transaction.type == TransactionType.incoming;

    final assetName = _getAssetName(
      transaction.isCancelled,
      txIsReceived,
      !transaction.isConfirmed(
        currentHeight,
        coin.requiredConfirmations,
      ),
      ref.watch(themeProvider).assets,
    );

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Center(
          // if it starts with "assets" we assume its local
          // TODO: a more thorough check
          child: assetName.startsWith("assets")
              ? SvgPicture.asset(
                  assetName,
                  width: size.width,
                  height: size.height,
                )
              : SvgPicture.file(
                  File(
                    assetName,
                  ),
                  width: size.width,
                  height: size.height,
                )),
    );
  }
}
