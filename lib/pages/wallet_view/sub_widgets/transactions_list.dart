import 'dart:async';

import 'package:epicpay/models/contact.dart';
import 'package:epicpay/models/paymint/transactions_model.dart';
import 'package:epicpay/models/transaction_filter.dart';
import 'package:epicpay/pages/wallet_view/sub_widgets/no_transactions_found.dart';
import 'package:epicpay/providers/global/address_book_service_provider.dart';
import 'package:epicpay/providers/global/wallet_provider.dart';
import 'package:epicpay/providers/ui/transaction_filter_provider.dart';
import 'package:epicpay/providers/wallet/notes_service_provider.dart';
import 'package:epicpay/utilities/format.dart';
import 'package:epicpay/widgets/loading_indicator.dart';
import 'package:epicpay/widgets/transaction_card.dart';
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
  bool _hasLoaded = false;
  Map<String, Transaction> _transactions = {};

  bool _matchesFilter(Transaction tx, List<Contact> contacts,
      Map<String, String> notes, TransactionFilter? filter) {
    if (filter == null) {
      return true;
    }

    if (!filter.sent && !filter.received) {
      return false;
    }

    if (filter.received && !filter.sent && tx.txType == "Sent") {
      return false;
    }

    if (filter.sent && !filter.received && tx.txType == "Received") {
      return false;
    }

    final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000);
    if ((filter.to != null &&
            date.millisecondsSinceEpoch > filter.to!.millisecondsSinceEpoch) ||
        (filter.from != null &&
            date.millisecondsSinceEpoch <
                filter.from!.millisecondsSinceEpoch)) {
      return false;
    }

    if (filter.amount != null && filter.amount != tx.amount) {
      return false;
    }

    return _isKeywordMatch(tx, filter.keyword.toLowerCase(), contacts, notes);
  }

  bool _isKeywordMatch(Transaction tx, String keyword, List<Contact> contacts,
      Map<String, String> notes) {
    if (keyword.isEmpty) {
      return true;
    }

    bool contains = false;

    // check if address book name contains
    contains |= contacts
        .where((e) =>
            e.addresses.where((a) => a.address == tx.address).isNotEmpty &&
            e.name.toLowerCase().contains(keyword))
        .isNotEmpty;

    // check if address contains
    contains |= tx.address.toLowerCase().contains(keyword);

    // check if note contains
    contains |= notes[tx.txid] != null &&
        notes[tx.txid]!.toLowerCase().contains(keyword);

    // check if txid contains
    contains |= tx.txid.toLowerCase().contains(keyword);

    // check if subType contains
    contains |=
        tx.subType.isNotEmpty && tx.subType.toLowerCase().contains(keyword);

    // check if txType contains
    contains |= tx.txType.toLowerCase().contains(keyword);

    // check if date contains
    contains |=
        Format.extractDateFrom(tx.timestamp).toLowerCase().contains(keyword);

    return contains;
  }

  void updateTransactions(TransactionData newData, TransactionFilter? filter) {
    debugPrint("FILTER: $filter");

    _transactions = {};
    final newTransactions =
        newData.txChunks.expand((element) => element.transactions);

    final contacts = ref.read(addressBookServiceProvider).contacts;
    final notes =
        ref.read(notesServiceChangeNotifierProvider(widget.walletId)).notesSync;

    for (final tx in newTransactions) {
      if (_matchesFilter(tx, contacts, notes, filter)) {
        _transactions[tx.txid] = tx;
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(transactionFilterProvider.state).state;
    return FutureBuilder(
      future:
          ref.watch(walletProvider.select((value) => value!.transactionData)),
      builder: (fbContext, AsyncSnapshot<TransactionData> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          updateTransactions(snapshot.data!, filter);
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
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(
                height: 16,
              ),
              itemBuilder: (context, index) {
                final tx = list[index];
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
