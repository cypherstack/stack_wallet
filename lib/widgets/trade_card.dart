import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction_status.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class TradeCard extends ConsumerWidget {
  const TradeCard({
    Key? key,
    required this.trade,
    required this.onTap,
  }) : super(key: key);

  final ExchangeTransaction trade;
  final VoidCallback onTap;

  String _fetchIconAssetForStatus(String statusString) {
    ChangeNowTransactionStatus? status;
    try {
      if (statusString.toLowerCase().startsWith("waiting")) {
        statusString = "waiting";
      }
      status = changeNowTransactionStatusFromStringIgnoreCase(statusString);
    } on ArgumentError catch (_) {
      status = ChangeNowTransactionStatus.Failed;
    }

    switch (status) {
      case ChangeNowTransactionStatus.New:
      case ChangeNowTransactionStatus.Waiting:
      case ChangeNowTransactionStatus.Confirming:
      case ChangeNowTransactionStatus.Exchanging:
      case ChangeNowTransactionStatus.Sending:
      case ChangeNowTransactionStatus.Refunded:
      case ChangeNowTransactionStatus.Verifying:
        return Assets.svg.txExchangePending;
      case ChangeNowTransactionStatus.Finished:
        return Assets.svg.txExchange;
      case ChangeNowTransactionStatus.Failed:
        return Assets.svg.txExchangeFailed;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: RoundedWhiteContainer(
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
              ),
              child: Center(
                child: SvgPicture.asset(
                  _fetchIconAssetForStatus(
                      trade.statusObject?.status.name ?? trade.statusString),
                  width: 32,
                  height: 32,
                ),
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${trade.fromCurrency.toUpperCase()} → ${trade.toCurrency.toUpperCase()}",
                        style: STextStyles.itemSubtitle12,
                      ),
                      Text(
                        "${Decimal.tryParse(trade.statusObject?.amountSendDecimal ?? "") ?? "..."} ${trade.fromCurrency.toUpperCase()}",
                        style: STextStyles.itemSubtitle12,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "ChangeNOW",
                        style: STextStyles.label,
                      ),
                      Text(
                        Format.extractDateFrom(
                            trade.date.millisecondsSinceEpoch ~/ 1000),
                        style: STextStyles.label,
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
