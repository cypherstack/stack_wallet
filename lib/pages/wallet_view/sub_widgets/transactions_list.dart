import 'dart:async';

import 'package:epicmobile/models/paymint/transactions_model.dart';
import 'package:epicmobile/pages/wallet_view/sub_widgets/no_transactions_found.dart';
import 'package:epicmobile/providers/global/wallet_provider.dart';
import 'package:epicmobile/widgets/loading_indicator.dart';
import 'package:epicmobile/widgets/transaction_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionsList extends ConsumerStatefulWidget {
  const TransactionsList({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  ConsumerState<TransactionsList> createState() => _TransactionsListState();
}

class _TransactionsListState extends ConsumerState<TransactionsList> {
  //
  bool _hasLoaded = false;
  Map<String, Transaction> _transactions = {};

  void updateTransactions(TransactionData newData) {
    _transactions = {};
    final newTransactions =
        newData.txChunks.expand((element) => element.transactions);
    for (final tx in newTransactions) {
      _transactions[tx.txid] = tx;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          ref.watch(walletProvider.select((value) => value!.transactionData)),
      builder: (fbContext, AsyncSnapshot<TransactionData> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          updateTransactions(snapshot.data!);
          _hasLoaded = true;
        }
        if (!_hasLoaded) {
          return Column(
            children: const [
              Spacer(),
              Center(
                child: LoadingIndicator(
                  height: 50,
                  width: 50,
                ),
              ),
              Spacer(
                flex: 4,
              ),
            ],
          );
        }
        if (_transactions.isEmpty) {
          return const NoTransActionsFound();
        } else {
          final list = _transactions.values.toList(growable: false);
          list.sort((a, b) => b.timestamp - a.timestamp);
          return RefreshIndicator(
            onRefresh: () async {
              debugPrint("pulled down to refresh on transaction list");

              if (!ref.read(walletProvider)!.isRefreshing) {
                unawaited(ref.read(walletProvider)!.refresh());
              }
            },
            child: ListView.separated(
              itemCount: list.length * 10,
              separatorBuilder: (_, __) => const SizedBox(
                height: 16,
              ),
              itemBuilder: (context, index) {
                final tx = list[0];
                return TransactionCard(
                  // this may mess with combined firo transactions
                  key: Key(tx.toString()), //
                  transaction: tx,
                  walletId: widget.walletId,
                );
              },
            ),
          );
        }
      },
    );
  }
}
