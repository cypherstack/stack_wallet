import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/tx_icon.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/tx_v2/transaction_v2_details_view.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/price_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/spark_interface.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';

class TransactionCardV2 extends ConsumerStatefulWidget {
  const TransactionCardV2({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  final TransactionV2 transaction;

  @override
  ConsumerState<TransactionCardV2> createState() => _TransactionCardStateV2();
}

class _TransactionCardStateV2 extends ConsumerState<TransactionCardV2> {
  late final TransactionV2 _transaction;
  late final String walletId;
  late final String prefix;
  late final String unit;
  late final Coin coin;
  late final TransactionType txType;

  String whatIsIt(
    Coin coin,
    int currentHeight,
  ) =>
      _transaction.statusLabel(
        currentChainHeight: currentHeight,
        minConfirms:
            ref.read(pWallets).getWallet(walletId).cryptoCurrency.minConfirms,
      );

  @override
  void initState() {
    _transaction = widget.transaction;
    walletId = _transaction.walletId;

    if (Util.isDesktop) {
      if (_transaction.type == TransactionType.outgoing &&
          _transaction.subType != TransactionSubType.cashFusion) {
        prefix = "-";
      } else if (_transaction.type == TransactionType.incoming) {
        prefix = "+";
      } else {
        prefix = "";
      }
    } else {
      prefix = "";
    }
    coin = ref.read(pWalletCoin(walletId));

    unit = coin.ticker;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(
        localeServiceChangeNotifierProvider.select((value) => value.locale));

    final baseCurrency = ref
        .watch(prefsChangeNotifierProvider.select((value) => value.currency));

    final price = ref
        .watch(priceAnd24hChangeNotifierProvider
            .select((value) => value.getPrice(coin)))
        .item1;

    final currentHeight = ref.watch(pWalletChainHeight(walletId));

    final Amount amount;

    if (_transaction.subType == TransactionSubType.cashFusion) {
      amount = _transaction.getAmountReceivedInThisWallet(coin: coin);
    } else {
      switch (_transaction.type) {
        case TransactionType.outgoing:
          amount = _transaction.getAmountSentFromThisWallet(coin: coin);
          break;

        case TransactionType.incoming:
        case TransactionType.sentToSelf:
          if (_transaction.subType == TransactionSubType.sparkMint) {
            amount = _transaction.getAmountSparkSelfMinted(coin: coin);
          } else if (_transaction.subType == TransactionSubType.sparkSpend) {
            final changeAddress =
                (ref.watch(pWallets).getWallet(walletId) as SparkInterface)
                    .sparkChangeAddress;
            amount = Amount(
              rawValue: _transaction.outputs
                  .where((e) =>
                      e.walletOwns && !e.addresses.contains(changeAddress))
                  .fold(BigInt.zero, (p, e) => p + e.value),
              fractionDigits: coin.decimals,
            );
          } else {
            amount = _transaction.getAmountReceivedInThisWallet(coin: coin);
          }
          break;

        case TransactionType.unknown:
          amount = _transaction.getAmountSentFromThisWallet(coin: coin);
          break;
      }
    }

    return Material(
      color: Theme.of(context).extension<StackColors>()!.popupBG,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(Constants.size.circularBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: RawMaterialButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
          ),
          onPressed: () async {
            if (Util.isDesktop) {
              await showDialog<void>(
                context: context,
                builder: (context) => DesktopDialog(
                  maxHeight: MediaQuery.of(context).size.height - 64,
                  maxWidth: 580,
                  child: TransactionV2DetailsView(
                    transaction: _transaction,
                    coin: coin,
                    walletId: walletId,
                  ),
                ),
              );
            } else {
              unawaited(
                Navigator.of(context).pushNamed(
                  TransactionV2DetailsView.routeName,
                  arguments: (
                    tx: _transaction,
                    coin: coin,
                    walletId: walletId,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                TxIcon(
                  transaction: _transaction,
                  coin: coin,
                  currentHeight: currentHeight,
                ),
                const SizedBox(
                  width: 14,
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
                                whatIsIt(
                                  coin,
                                  currentHeight,
                                ),
                                style: STextStyles.itemSubtitle12(context),
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
                                  return Text(
                                    "$prefix${ref.watch(pAmountFormatter(coin)).format(amount)}",
                                    style: STextStyles.itemSubtitle12(context),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        // crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                Format.extractDateFrom(_transaction.timestamp),
                                style: STextStyles.label(context),
                              ),
                            ),
                          ),
                          if (ref.watch(prefsChangeNotifierProvider
                              .select((value) => value.externalCalls)))
                            const SizedBox(
                              width: 10,
                            ),
                          if (ref.watch(prefsChangeNotifierProvider
                              .select((value) => value.externalCalls)))
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Builder(
                                  builder: (_) {
                                    return Text(
                                      "$prefix${Amount.fromDecimal(
                                        amount.decimal * price,
                                        fractionDigits: 2,
                                      ).fiatString(
                                        locale: locale,
                                      )} $baseCurrency",
                                      style: STextStyles.label(context),
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
