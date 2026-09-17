import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../../models/isar/models/contract.dart';
import '../../../../models/isar/models/isar_models.dart';
import '../../../../providers/db/main_db_provider.dart';
import '../../../../providers/global/locale_provider.dart';
import '../../../../providers/global/prefs_provider.dart';
import '../../../../providers/global/price_provider.dart';
import '../../../../providers/global/wallets_provider.dart';
import '../../../../providers/wallet/transaction_note_provider.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/amount/amount.dart';
import '../../../../utilities/amount/amount_formatter.dart';
import '../../../../utilities/constants.dart';
import '../../../../utilities/mining_payouts.dart';
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
import 'tx_list_metrics.dart';

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
  late final Contract? tokenContract;

  bool get isTokenTx => tokenContract != null;

  /// Redesign: the row's title is the transaction's DIRECTION; its state
  /// (confirming, cancelled) moved into the subtitle where it is context,
  /// not identity. A row that renames itself from "Receiving" to "Received"
  /// is one thing changing state, and the title staying put makes that
  /// legible.
  String _titleLabel() {
    if (_transaction.isCancelled) {
      return coin is Ethereum ? "Failed" : "Cancelled";
    }
    if (_transaction.subType == TransactionSubType.cashFusion) {
      return "Fusion";
    }
    switch (_transaction.type) {
      case TransactionType.outgoing:
        return "Sent";
      case TransactionType.incoming:
        // A block reward or a pool payout is still money arriving, but a
        // miner reads a run of identical "Received" rows and cannot tell
        // earnings apart from someone paying them. Naming it is the whole
        // difference.
        if (isMiningPayout(_transaction, coin)) {
          return "Mining payout";
        }
        return "Received";
      case TransactionType.sentToSelf:
        return "Sent to self";
      case TransactionType.unknown:
        return "Unknown";
    }
  }

  /// "9:59 · 6 confirmations" | "9:59 · <the user's note>" |
  /// "9:59 · 9 recipients" | "9:59".
  ///
  /// Confirmations show while they are still news (under 10); after that the
  /// note takes the slot if one exists. The date is NOT here, the list's day
  /// headers carry it, so the row repeats nothing.
  ///
  /// The recipient count is the last resort, and it exists because without it
  /// a settled send with no note falls back to the bare time. A pool wallet
  /// pays out several times within the same minute, so three rows read "Sent
  /// 22:32" and differ only in an eight decimal amount, which is not a
  /// difference anybody scans. Only for sends, only when there is more than
  /// one, and counted on the outputs this wallet does NOT own so that change
  /// is not mistaken for a recipient.
  String _subtitle(int currentHeight, String? note) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      _transaction.timestamp * 1000,
    );
    final minutes = date.minute < 10 ? "0${date.minute}" : "${date.minute}";
    final time = "${date.hour}:$minutes";

    final confirms = _transaction.getConfirmations(currentHeight);
    if (confirms < 10) {
      return "$time · $confirms confirmation${confirms == 1 ? "" : "s"}";
    }
    if (note != null && note.isNotEmpty) {
      return "$time · $note";
    }
    if (_transaction.type == TransactionType.outgoing) {
      final recipients = _transaction.outputs
          .where((e) => !e.walletOwns)
          .length;
      if (recipients > 1) {
        return "$time · $recipients recipients";
      }
    }
    return time;
  }

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
    } else if (_transaction.subType == TransactionSubType.splToken) {
      tokenContract = ref
          .read(mainDBProvider)
          .getSolContractSync(_transaction.contractAddress!);

      unit = tokenContract!.symbol;
    } else {
      tokenContract = null;
      unit = coin.ticker;
    }

    // Signed amounts on all platforms (was desktop-only) — part of the
    // green-in / signed-out transaction grammar.
    if (_transaction.type == TransactionType.outgoing &&
        _transaction.subType != TransactionSubType.cashFusion) {
      prefix = "-";
    } else if (_transaction.type == TransactionType.incoming) {
      prefix = "+";
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

    final privacyMode = ref.watch(
      prefsChangeNotifierProvider.select((value) => value.privacyMode),
    );

    Decimal? price;
    if (ref.watch(
      prefsChangeNotifierProvider.select((value) => value.externalCalls),
    )) {
      price = ref.watch(
        priceAnd24hChangeNotifierProvider.select(
          (value) => isTokenTx
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
      // Ledger redesign: hairline rows on the page background, not white cards.
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          Constants.size.circularBorderRadius,
        ),
      ),
      child: Padding(
        // Outer gap: the space BETWEEN cards when rows are not grouped. Inside
        // the grouped card it is simply part of kTxCardInset.
        padding: const EdgeInsets.all(kTxRowOuterGap),
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
                  maxWidth: 640,
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
            // Together with the outer gap this makes kTxCardInset, which the
            // day headers and the truncation notice also use.
            padding: const EdgeInsets.all(kTxRowInnerPad),
            child: Builder(
              builder: (context) {
                // Redesign row: [icon] [Sent / time·context] ... [amount /
                // fiat]. The ticker is gone from the amount — every row in
                // this list is the same coin and the hero already names it.
                final note = ref
                    .watch(
                      pTransactionNote((
                        walletId: walletId,
                        txid: _transaction.txid,
                      )),
                    )
                    ?.value;

                final formattedAmount = ref
                    .watch(pAmountFormatter(coin))
                    .format(
                      amount,
                      tokenContract: tokenContract,
                      withUnitName: false,
                      // The row is a label beside a number, and the number was
                      // winning on width alone: +10,000.00000000 is sixteen
                      // characters of which eight say nothing, and it squeezed
                      // "Mining payout" down to "Mining p...".
                      trimTrailingZeros: true,
                    );

                // The amount column used to be unconstrained, so it took
                // whatever width it wanted and the label beside it got the
                // remainder. On Pepecoin, where a single figure runs to twenty
                // digits, that crushed "Received" down to "Rece…". Capping the
                // number's share keeps the words readable, and past the cap the
                // number scales down instead of eating them.
                return LayoutBuilder(
                  builder: (context, rowConstraints) => Row(
                    children: [
                      TxIcon(
                        transaction: _transaction,
                        coin: coin,
                        currentHeight: currentHeight,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ConditionalParent(
                              condition:
                                  coin is Firo &&
                                  _transaction.isInstantLock &&
                                  !_transaction.isConfirmed(
                                    currentHeight,
                                    coin.minConfirms,
                                    coin.minCoinbaseConfirms,
                                  ),
                              builder: (child) => Row(
                                children: [
                                  child,
                                  const SizedBox(width: 10),
                                  const CoinTickerTag(ticker: "INSTANT"),
                                ],
                              ),
                              child: Text(
                                _titleLabel(),
                                style: STextStyles.itemSubtitle12(context)
                                    .copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).extension<StackColors>()!.textDark,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Shrinks rather than cutting. The amount column
                            // is capped at 52% of the row, so this line has
                            // under half the width and "22:32 - 9 recipients"
                            // ellipsised to "22:32 - 9 recipie...", which
                            // reads as a rendering fault rather than as a
                            // number. A point smaller keeps the whole phrase,
                            // and most rows never reach the limit.
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _subtitle(currentHeight, note),
                                maxLines: 1,
                                style: STextStyles.label(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: rowConstraints.maxWidth * 0.52,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                // Privacy mode masks per-row amounts too: hiding
                                // the balance while listing every transaction
                                // underneath it is not privacy.
                                privacyMode
                                    ? "••••"
                                    : "$prefix$formattedAmount",
                                style: STextStyles.itemSubtitle12(context)
                                    .copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                      color:
                                          _transaction.type ==
                                              TransactionType.incoming
                                          ? Theme.of(context)
                                                .extension<StackColors>()!
                                                .accentColorGreen
                                          : Theme.of(context)
                                                .extension<StackColors>()!
                                                .textDark,
                                    ),
                              ),
                            ),
                            if (price != null) const SizedBox(height: 2),
                            if (price != null)
                              Text(
                                privacyMode
                                    ? "•••• $baseCurrency"
                                    : "$prefix${(amount.decimal * price!).toAmount(fractionDigits: 2).fiatString(locale: locale)} $baseCurrency",
                                style: STextStyles.label(context),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
