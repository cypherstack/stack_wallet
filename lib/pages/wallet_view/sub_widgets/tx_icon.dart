import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart' as isar_models;
import 'package:stackwallet/models/paymint/transactions_model.dart' as old;
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class TxIcon extends StatelessWidget {
  const TxIcon({Key? key, required this.transaction}) : super(key: key);
  final old.Transaction transaction;

  static const Size size = Size(32, 32);

  String _getAssetName(
      bool isCancelled, bool isReceived, bool isPending, BuildContext context) {
    if (!isReceived && transaction.subType == "mint") {
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
        return Assets.svg.receiveCancelled(context);
      }
      if (isPending) {
        return Assets.svg.receivePending(context);
      }
      return Assets.svg.receive(context);
    } else {
      if (isCancelled) {
        return Assets.svg.sendCancelled(context);
      }
      if (isPending) {
        return Assets.svg.sendPending(context);
      }
      return Assets.svg.send(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txIsReceived = transaction.txType == "Received";

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Center(
        child: SvgPicture.asset(
          _getAssetName(
            transaction.isCancelled,
            txIsReceived,
            !transaction.confirmedStatus,
            context,
          ),
          width: size.width,
          height: size.height,
        ),
      ),
    );
  }
}

class TxIcon2 extends StatelessWidget {
  const TxIcon2({
    Key? key,
    required this.transaction,
    required this.currentHeight,
    required this.coin,
  }) : super(key: key);

  final isar_models.Transaction transaction;
  final int currentHeight;
  final Coin coin;

  static const Size size = Size(32, 32);

  String _getAssetName(
      bool isCancelled, bool isReceived, bool isPending, BuildContext context) {
    if (!isReceived &&
        transaction.subType == isar_models.TransactionSubType.mint) {
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
        return Assets.svg.receiveCancelled(context);
      }
      if (isPending) {
        return Assets.svg.receivePending(context);
      }
      return Assets.svg.receive(context);
    } else {
      if (isCancelled) {
        return Assets.svg.sendCancelled(context);
      }
      if (isPending) {
        return Assets.svg.sendPending(context);
      }
      return Assets.svg.send(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txIsReceived =
        transaction.type == isar_models.TransactionType.incoming;

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
            context,
          ),
          width: size.width,
          height: size.height,
        ),
      ),
    );
  }
}
