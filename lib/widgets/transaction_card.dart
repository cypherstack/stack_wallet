import 'dart:async';

import 'package:epicpay/models/paymint/transactions_model.dart';
import 'package:epicpay/pages/wallet_view/sub_widgets/tx_icon.dart';
import 'package:epicpay/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:epicpay/providers/providers.dart';
import 'package:epicpay/utilities/constants.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:epicpay/utilities/format.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

class TransactionCard extends ConsumerStatefulWidget {
  const TransactionCard({
    Key? key,
    required this.transaction,
    required this.walletId,
  }) : super(key: key);

  final Transaction transaction;
  final String walletId;

  @override
  ConsumerState<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends ConsumerState<TransactionCard> {
  late final Transaction _transaction;
  late final String walletId;

  String whatIsIt(String type, Coin coin) {
    if (coin == Coin.epicCash && _transaction.slateId == null) {
      return "Restored Funds";
    }

    if (type == "Received") {
      // if (_transaction.isMinting) {
      //   return "Minting";
      // } else
      if (_transaction.confirmedStatus) {
        return "Received";
      } else {
        return "Receiving...";
      }
    } else if (type == "Sent") {
      if (_transaction.confirmedStatus) {
        return "Sent";
      } else {
        return "Sending...";
      }
    } else {
      return type;
    }
  }

  @override
  void initState() {
    walletId = widget.walletId;
    _transaction = widget.transaction;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.of(context).size.height < 600;

    final locale = ref.watch(
        localeServiceChangeNotifierProvider.select((value) => value.locale));
    final manager = ref.watch(walletProvider)!;

    final baseCurrency = ref
        .watch(prefsChangeNotifierProvider.select((value) => value.currency));

    final coin = manager.coin;

    final price = ref
        .watch(priceAnd24hChangeNotifierProvider
            .select((value) => value.getPrice(coin)))
        .item1;

    return Material(
      color: Theme.of(context).extension<StackColors>()!.popupBG,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(Constants.size.circularBorderRadius),
      ),
      child: Padding(
        padding: small ? const EdgeInsets.all(0) : const EdgeInsets.all(6),
        child: RawMaterialButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
          ),
          onPressed: () async {
            if (coin == Coin.epicCash && _transaction.slateId == null) {
              // unawaited(showFloatingFlushBar(
              //   context: context,
              //   message:
              //       "Restored Epic funds from your Seed have no Data.\nUse Stack Backup to keep your transaction history.",
              //   type: FlushBarType.warning,
              //   duration: const Duration(seconds: 5),
              // ));
              return;
            }

            unawaited(
              Navigator.of(context).pushNamed(
                TransactionDetailsView.routeName,
                arguments: Tuple3(
                  _transaction,
                  coin,
                  walletId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const SizedBox(
                  width: 4,
                ),
                TxIcon(transaction: _transaction),
                const SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _transaction.isCancelled
                                    ? "Cancelled"
                                    : whatIsIt(_transaction.txType, coin),
                                style: STextStyles.bodySmallBold(context),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Builder(
                                builder: (_) {
                                  final amount = Format.satoshisToAmount(
                                      _transaction.amount,
                                      coin: coin);
                                  String amountString =
                                      amount.toStringAsFixed(8);
                                  // I'd love to do this more simply
                                  // Step from the right of the string to the left, break at first non-zero character and make substring up to that point (LTR, unless it's zero)
                                  for (int i = amountString.length - 1;
                                      i > 0;
                                      i--) {
                                    if (amountString.split('')[i] != '0') {
                                      String subStr =
                                          amountString.substring(0, i + 1);
                                      if (subStr.isNotEmpty) {
                                        amountString = subStr;
                                      }
                                      break;
                                    }
                                  }

                                  return Text(
                                    "$amountString ${coin.ticker}",
                                    style: STextStyles.bodySmall(context),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        // crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                Format.extractDateFrom(_transaction.timestamp,
                                    simple: true),
                                style: STextStyles.bodySmall(context),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Builder(
                                builder: (_) {
                                  // TODO: modify Format.<functions> to take optional Coin parameter so this type oif check isn't done in ui
                                  int value = _transaction.amount;

                                  return Text(
                                    "${Format.localizedStringAsFixed(
                                      value: Format.satoshisToAmount(value) *
                                          price,
                                      locale: locale,
                                      decimalPlaces: 2,
                                    )} $baseCurrency",
                                    style: STextStyles.bodySmall(context),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
