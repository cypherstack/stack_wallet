/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2025 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../wallet_view/sub_widgets/no_transactions_found.dart';
import '../../wallet_view/transaction_views/tx_v2/transaction_v2_list_item.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../../providers/global/wallets_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/constants.dart';
import '../../../wallets/isar/providers/solana/current_sol_token_wallet_provider.dart';
import '../../../widgets/loading_indicator.dart';

/// Solana-specific transaction list widget.
///
/// Displays transactions for a Solana token using the Solana token wallet provider.
class SolanaTokenTransactionsList extends ConsumerStatefulWidget {
  const SolanaTokenTransactionsList({
    super.key,
    required this.walletId,
  });

  final String walletId;

  @override
  ConsumerState<SolanaTokenTransactionsList> createState() =>
      _SolanaTransactionsListState();
}

class _SolanaTransactionsListState extends ConsumerState<SolanaTokenTransactionsList> {
  late final int minConfirms;

  bool _hasLoaded = false;
  List<TransactionV2> _transactions = [];

  StreamSubscription<List<TransactionV2>>? _subscription;
  Query<TransactionV2>? _query;

  BorderRadius get _borderRadiusFirst {
    return BorderRadius.only(
      topLeft: Radius.circular(
        Constants.size.circularBorderRadius,
      ),
      topRight: Radius.circular(
        Constants.size.circularBorderRadius,
      ),
    );
  }

  BorderRadius get _borderRadiusLast {
    return BorderRadius.only(
      bottomLeft: Radius.circular(
        Constants.size.circularBorderRadius,
      ),
      bottomRight: Radius.circular(
        Constants.size.circularBorderRadius,
      ),
    );
  }

  @override
  void initState() {
    minConfirms = ref
        .read(pWallets)
        .getWallet(widget.walletId)
        .cryptoCurrency
        .minConfirms;
    super.initState();
  }

  /// Initialize the query and subscription when the wallet becomes available.
  void _initializeQuery() {
    if (_query != null) {
      return; // Already initialized.
    }

    // Get transaction filter from Solana token wallet if available.
    final solanaTokenWallet = ref.read(pCurrentSolanaTokenWallet);
    FilterOperation? transactionFilter;

    if (solanaTokenWallet != null) {
      transactionFilter = solanaTokenWallet.transactionFilterOperation;
    }

    _query = ref.read(mainDBProvider).isar.transactionV2s.buildQuery<TransactionV2>(
      whereClauses: [
        IndexWhereClause.equalTo(
          indexName: 'walletId',
          value: [widget.walletId],
        ),
      ],
      filter: transactionFilter,
      sortBy: [
        const SortProperty(
          property: "timestamp",
          sort: Sort.desc,
        ),
      ],
    );

    _subscription = _query!.watch().listen((event) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _transactions = event;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet =
        ref.watch(pWallets.select((value) => value.getWallet(widget.walletId)));

    // Ensure query is initialized when wallet becomes available.
    _initializeQuery();

    // If query hasn't been initialized yet, show loading.
    if (_query == null) {
      return Center(
        child: Container(
          color: Theme.of(context).extension<StackColors>()!.background,
          child: const LoadingIndicator(
            width: 100,
            height: 100,
          ),
        ),
      );
    }

    return FutureBuilder(
      future: _query!.findAll(),
      builder: (fbContext, AsyncSnapshot<List<TransactionV2>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          if (!_hasLoaded) {
            _hasLoaded = true;
            _transactions = snapshot.data ?? [];
          }

          if (_transactions.isEmpty) {
            return const NoTransActionsFound();
          }

          return CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return TxListItem(
                      key: Key(
                        "solanaTokenTransactionV2ListItemKey_${_transactions[index].txid}",
                      ),
                      tx: _transactions[index],
                      coin: wallet.cryptoCurrency,
                      radius: index == 0
                          ? _borderRadiusFirst
                          : index == _transactions.length - 1
                              ? _borderRadiusLast
                              : null,
                    );
                  },
                  childCount: _transactions.length,
                ),
              ),
            ],
          );
        }

        return Center(
          child: Container(
            color: Theme.of(context).extension<StackColors>()!.background,
            child: const LoadingIndicator(
              width: 100,
              height: 100,
            ),
          ),
        );
      },
    );
  }
}
