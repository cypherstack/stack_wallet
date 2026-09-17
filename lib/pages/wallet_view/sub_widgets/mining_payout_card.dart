/*
 * This file is part of BitFinite Wallet.
 *
 * A miner's summary of what mining has actually paid into this wallet.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../../wallets/isar/models/wallet_info.dart';
import '../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/amount/amount_formatter.dart';
import '../../../utilities/mining_payouts.dart';
import '../../../utilities/text_styles.dart';
import '../../../wallets/crypto_currency/crypto_currency.dart';
import '../transaction_views/tx_v2/all_transactions_v2_view.dart';

/// Shows how mining is going, for wallets that mining actually pays.
///
/// A miner opens the wallet to answer one question: are the payouts still
/// arriving. The balance alone does not answer it, because a wallet that
/// stopped earning yesterday looks exactly like one still earning. So the
/// card leads with when the last payout landed.
///
/// It renders nothing at all when the wallet has no payouts in it, which is
/// every ordinary wallet. Nobody who does not mine ever sees this.
class MiningPayoutCard extends ConsumerStatefulWidget {
  const MiningPayoutCard({
    super.key,
    required this.walletId,
    required this.coin,
  });

  final String walletId;
  final CryptoCurrency coin;

  @override
  ConsumerState<MiningPayoutCard> createState() => _MiningPayoutCardState();
}

class _MiningPayoutCardState extends ConsumerState<MiningPayoutCard> {
  late final Query<TransactionV2> _query;
  late final StreamSubscription<List<TransactionV2>> _subscription;
  MiningPayoutSummary? _summary;

  void _recompute(List<TransactionV2> txns) {
    _summary = summariseMiningPayouts(txns, widget.coin);
  }

  @override
  void initState() {
    _query = ref
        .read(mainDBProvider)
        .isar
        .transactionV2s
        .buildQuery<TransactionV2>(
          whereClauses: [
            IndexWhereClause.equalTo(
              indexName: 'walletId',
              value: [widget.walletId],
            ),
          ],
          sortBy: [const SortProperty(property: "timestamp", sort: Sort.desc)],
        );

    _recompute(_query.findAllSync());

    _subscription = _query.watch().listen((event) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _recompute(event));
        }
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  /// 5033 -> "5,033", so the count is grouped like every other number here.
  static String _grouped(int n) {
    final digits = n.toString();
    final out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(",");
      out.write(digits[i]);
    }
    return out.toString();
  }

  /// The total, without the trailing zeros that carry no information.
  ///
  /// It used to call withoutDustDecimals with minWholeDigits: 1, which drops
  /// the entire fraction whenever there is at least one whole digit. Every
  /// formatted amount here has eight decimals, so that condition was always
  /// true, and the guard never guarded anything: a miner whose payouts totalled
  /// 0.87654321 BFX was shown "0 BFX", and 12.5 BFX was shown "12 BFX". No
  /// marker, no rounding, just gone.
  ///
  /// The reason it was there was width, and width was already solved: this
  /// string goes into a FittedBox capped at 42% of the row, so a long number
  /// shrinks instead of pushing the payout count into an ellipsis. Nothing
  /// needed to be dropped to make it fit.
  ///
  /// trimTrailingZeros does the part that was actually wanted. It removes
  /// decimals that are only zeros, which is the common case for block rewards,
  /// and it cannot change the value: 49,850.00000000 becomes 49,850 and
  /// 0.87654321 stays itself.
  String _totalLabel(AmountFormatter formatter, Amount total) {
    return formatter.format(total, trimTrailingZeros: true);
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    if (summary == null || summary.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).extension<StackColors>()!;
    final formatter = ref.watch(pAmountFormatter(widget.coin));

    // Whether this wallet's history was capped during sync. When it was, the
    // count and the total below are floors, not lifetime figures: they sum the
    // payouts the wallet actually holds.
    //
    // The card carried "recent" for this once and lost it, on the grounds that
    // the truncation notice says it properly further down. It does not say it
    // here, and "further down" is past a 20px gap and a "Transactions" header,
    // which is far enough that a pool address capped at 1,000 transactions read
    // as a complete lifetime record. The other half of that removal was width:
    // the extra word pushed the count into an ellipsis. That objection is gone,
    // because the line scales down rather than ellipsising now.
    final truncated =
        (ref
                .watch(pWalletInfo(widget.walletId))
                .otherData[WalletInfoKeys.historyTruncatedTotal]
            as int?) !=
        null;

    final countLabel = summary.count == 1
        ? "1 payout"
        : "${_grouped(summary.count)} payouts";

    final last = summary.last;
    final first = summary.first;

    // Headline: how fresh. Subtitle: how many, and over what span. The card
    // led with the total once, which reads well but answers the wrong
    // question — a wallet that stopped earning yesterday has the same total
    // as one still earning.
    final headline = last == null
        ? "No payouts yet"
        : "Last payout ${describeAge(last)}";
    // "at least", and only when it is true. On a complete history the phrase
    // would be hedging about a number that is exact, which is its own kind of
    // wrong.
    final counted = truncated ? "at least $countLabel" : countLabel;
    final subtitle = first == null
        ? counted
        : "$counted since ${describeShortDate(first)}";

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: colors.popupBG,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed(
            AllTransactionsV2View.routeName,
            arguments: (walletId: widget.walletId, payoutsOnly: true),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: LayoutBuilder(
              builder: (context, rowConstraints) => Row(
                children: [
                  // The payout mark: the same glyph the payout rows in the
                  // list carry, so the card and the rows it summarises read
                  // as the same thing.
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.textDark3.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 17,
                      color: colors.textDark3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          headline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: STextStyles.w600_14(
                            context,
                          ).copyWith(color: colors.textDark),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            // Scales down rather than ellipsising. "997
                            // payouts since 16 Jul" is a couple of characters
                            // wider than the space left beside the total, and
                            // cutting it to "997 payouts since 1…" loses the
                            // month — the one part of the line that is not
                            // already implied. A point smaller keeps all of
                            // it, and most wallets never reach the cap.
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  subtitle,
                                  maxLines: 1,
                                  style: STextStyles.w500_12(
                                    context,
                                  ).copyWith(color: colors.textSubtitle1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Capped rather than sharing the free space
                            // evenly. Two Flexibles split the row down the
                            // middle, so the payout count was cut to "99..."
                            // while the total sat in space it did not need.
                            // FittedBox needs the bound to scale into at all.
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: rowConstraints.maxWidth * 0.42,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _totalLabel(formatter, summary.total),
                                  maxLines: 1,
                                  style: STextStyles.w600_14(
                                    context,
                                  ).copyWith(color: colors.textDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.textSubtitle1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
