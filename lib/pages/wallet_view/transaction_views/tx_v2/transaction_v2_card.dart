import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../../models/isar/models/isar_models.dart';
import '../../../../providers/db/main_db_provider.dart';
import '../../../../providers/global/locale_provider.dart';
import '../../../../providers/global/prefs_provider.dart';
import '../../../../providers/global/price_provider.dart';
import '../../../../providers/global/wallets_provider.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/amount/amount.dart';
import '../../../../utilities/amount/amount_formatter.dart';
import '../../../../utilities/constants.dart';
import '../../../../utilities/format.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../../wallets/wallet/wallet_mixin_interfaces/spark_interface.dart';
import '../../../../widgets/coin_ticker_tag.dart';
import '../../../../widgets/conditional_parent.dart';
import '../../../../widgets/desktop/desktop_dialog.dart';
import '../../sub_widgets/tx_icon.dart';
import 'transaction_v2_details_view.dart' as tvd;

class TransactionCardV2 extends ConsumerStatefulWidget {
  const TransactionCardV2({super.key, required this.transaction});

  final TransactionV2 transaction;

  @override
  ConsumerState<TransactionCardV2> createState() => _TransactionCardStateV2();
}

class _TransactionCardStateV2 extends ConsumerState<TransactionCardV2> {
  late final TransactionV2 _transaction;
  late final String walletId;
  late final String prefix;
  late final String unit;
  late final CryptoCurrency coin;
  late final TransactionType txType;
  late final EthContract? tokenContract;

  bool get isTokenTx => tokenContract != null;

  String whatIsIt(CryptoCurrency coin, int currentHeight) =>
      _transaction.isCancelled && coin is Ethereum
          ? "Failed"
          : _transaction.statusLabel(
            currentChainHeight: currentHeight,
            minConfirms:
                ref
                    .read(pWallets)
                    .getWallet(walletId)
                    .cryptoCurrency
                    .minConfirms,
            minCoinbaseConfirms:
                ref
                    .read(pWallets)
                    .getWallet(walletId)
                    .cryptoCurrency
                    .minCoinbaseConfirms,
          );

  @override
  void initState() {
    _transaction = widget.transaction;
    walletId = _transaction.walletId;
    coin = ref.read(pWalletCoin(walletId));

    if (_transaction.subType == TransactionSubType.ethToken) {
      tokenContract = ref
          .read(mainDBProvider)
          .getEthContractSync(_transaction.contractAddress!);

      unit = tokenContract!.symbol;
    } else {
      tokenContract = null;
      unit = coin.ticker;
    }

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

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(
      localeServiceChangeNotifierProvider.select((value) => value.locale),
    );

    final baseCurrency = ref.watch(
      prefsChangeNotifierProvider.select((value) => value.currency),
    );

    Decimal? price;
    if (ref.watch(
      prefsChangeNotifierProvider.select((value) => value.externalCalls),
    )) {
      price = ref.watch(
        priceAnd24hChangeNotifierProvider.select(
          (value) =>
              isTokenTx
                  ? value.getTokenPrice(tokenContract!.address)?.value
                  : value.getPrice(coin)?.value,
        ),
      );
    }

    final currentHeight = ref.watch(pWalletChainHeight(walletId));

    final Amount amount;

    final fractionDigits = tokenContract?.decimals ?? coin.fractionDigits;

    if (_transaction.subType == TransactionSubType.cashFusion) {
      amount = _transaction.getAmountReceivedInThisWallet(
        fractionDigits: fractionDigits,
      );
    } else {
      switch (_transaction.type) {
        case TransactionType.outgoing:
          amount = _transaction.getAmountSentFromThisWallet(
            fractionDigits: fractionDigits,
            subtractFee: coin is! Ethereum,
          );
          break;

        case TransactionType.incoming:
        case TransactionType.sentToSelf:
          if (_transaction.subType == TransactionSubType.sparkMint) {
            amount = _transaction.getAmountSparkSelfMinted(
              fractionDigits: fractionDigits,
            );
          } else if (_transaction.subType == TransactionSubType.sparkSpend) {
            final changeAddress =
                (ref.watch(pWallets).getWallet(walletId) as SparkInterface)
                    .sparkChangeAddress;
            amount = Amount(
              rawValue: _transaction.outputs
                  .where(
                    (e) => e.walletOwns && !e.addresses.contains(changeAddress),
                  )
                  .fold(BigInt.zero, (p, e) => p + e.value),
              fractionDigits: coin.fractionDigits,
            );
          } else {
            amount = _transaction.getAmountReceivedInThisWallet(
              fractionDigits: fractionDigits,
            );
          }
          break;

        case TransactionType.unknown:
          amount = _transaction.getAmountSentFromThisWallet(
            fractionDigits: fractionDigits,
            subtractFee: coin is! Ethereum,
          );
          break;
      }
    }

    return Material(
      color: Theme.of(context).extension<StackColors>()!.popupBG,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          Constants.size.circularBorderRadius,
        ),
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
                builder:
                    (context) => DesktopDialog(
                      maxHeight: MediaQuery.of(context).size.height - 64,
                      maxWidth: 580,
                      child: tvd.TransactionV2DetailsView(
                        transaction: _transaction,
                        coin: coin,
                        walletId: walletId,
                      ),
                    ),
              );
            } else {
              unawaited(
                Navigator.of(context).pushNamed(
                  tvd.TransactionV2DetailsView.routeName,
                  arguments: (tx: _transaction, coin: coin, walletId: walletId),
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
                const SizedBox(width: 14),
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
                              child: ConditionalParent(
                                condition:
                                    coin is Firo &&
                                    _transaction.isInstantLock &&
                                    !_transaction.isConfirmed(
                                      currentHeight,
                                      coin.minConfirms,
                                      coin.minCoinbaseConfirms,
                                    ),
                                builder:
                                    (child) => Row(
                                      children: [
                                        child,

                                        const SizedBox(width: 10),
                                        const CoinTickerTag(ticker: "INSTANT"),
                                      ],
                                    ),
                                child: Text(
                                  whatIsIt(coin, currentHeight),
                                  style: STextStyles.itemSubtitle12(context),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Builder(
                                builder: (_) {
                                  return Text(
                                    "$prefix${ref.watch(pAmountFormatter(coin)).format(amount, ethContract: tokenContract)}",
                                    style: STextStyles.itemSubtitle12(context),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
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
                          if (price != null) const SizedBox(width: 10),
                          if (price != null)
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Builder(
                                  builder: (_) {
                                    return Text(
                                      "$prefix${Amount.fromDecimal(amount.decimal * price!, fractionDigits: 2).fiatString(locale: locale)} $baseCurrency",
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
