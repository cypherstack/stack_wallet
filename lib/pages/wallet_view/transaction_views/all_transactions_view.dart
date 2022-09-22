import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/contact.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart';
import 'package:stackwallet/models/transaction_filter.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_search_filter_view.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/ui/transaction_filter_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';
import 'package:stackwallet/widgets/transaction_card.dart';
import 'package:tuple/tuple.dart';

class AllTransactionsView extends ConsumerStatefulWidget {
  const AllTransactionsView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  static const String routeName = "/allTransactions";

  final String walletId;

  @override
  ConsumerState<AllTransactionsView> createState() =>
      _TransactionDetailsViewState();
}

class _TransactionDetailsViewState extends ConsumerState<AllTransactionsView> {
  late final String walletId;

  late final TextEditingController _searchController;
  final searchFieldFocusNode = FocusNode();

  @override
  void initState() {
    walletId = widget.walletId;
    _searchController = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    searchFieldFocusNode.dispose();
    super.dispose();
  }

  // TODO: optimise search+filter
  List<Transaction> filter(
      {required List<Transaction> transactions, TransactionFilter? filter}) {
    if (filter == null) {
      return transactions;
    }

    debugPrint("FILTER: $filter");

    final contacts = ref.read(addressBookServiceProvider).contacts;
    final notes =
        ref.read(notesServiceChangeNotifierProvider(walletId)).notesSync;

    return transactions.where((tx) {
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
      if (date.millisecondsSinceEpoch > filter.to.millisecondsSinceEpoch ||
          date.millisecondsSinceEpoch < filter.from.millisecondsSinceEpoch) {
        return false;
      }

      if (filter.amount != null && filter.amount != tx.amount) {
        return false;
      }

      return _isKeywordMatch(tx, filter.keyword.toLowerCase(), contacts, notes);
    }).toList();
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
    contains |= tx.address.contains(keyword);

    // check if note contains
    contains |= notes[tx.txid] != null && notes[tx.txid]!.contains(keyword);

    // check if txid contains
    contains |= tx.txid.contains(keyword);

    return contains;
  }

  String _searchString = "";

  // TODO search more tx fields
  List<Transaction> search(String text, List<Transaction> transactions) {
    if (text.isEmpty) {
      return transactions;
    }
    text = text.toLowerCase();
    final contacts = ref.read(addressBookServiceProvider).contacts;
    final notes =
        ref.read(notesServiceChangeNotifierProvider(walletId)).notesSync;

    return transactions
        .where((tx) => _isKeywordMatch(tx, text, contacts, notes))
        .toList();
  }

  List<Tuple2<String, List<Transaction>>> groupTransactionsByMonth(
      List<Transaction> transactions) {
    Map<String, List<Transaction>> map = {};

    for (var tx in transactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000);
      final monthYear = "${Constants.monthMap[date.month]} ${date.year}";
      if (map[monthYear] == null) {
        map[monthYear] = [];
      }
      map[monthYear]!.add(tx);
    }

    List<Tuple2<String, List<Transaction>>> result = [];
    map.forEach((key, value) {
      result.add(Tuple2(key, value));
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StackTheme.instance.color.background,
      appBar: AppBar(
        backgroundColor: StackTheme.instance.color.background,
        leading: AppBarBackButton(
          onPressed: () async {
            if (FocusScope.of(context).hasFocus) {
              FocusScope.of(context).unfocus();
              await Future<void>.delayed(const Duration(milliseconds: 75));
            }
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          "Transactions",
          style: STextStyles.navBarTitle(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 10,
              right: 20,
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: AppBarIconButton(
                key: const Key("transactionSearchFilterViewButton"),
                size: 36,
                shadows: const [],
                color: StackTheme.instance.color.background,
                icon: SvgPicture.asset(
                  Assets.svg.filter,
                  color: StackTheme.instance.color.accentColorDark,
                  width: 20,
                  height: 20,
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    TransactionSearchFilterView.routeName,
                    arguments: ref
                        .read(walletsChangeNotifierProvider)
                        .getManager(walletId)
                        .coin,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 12,
          top: 12,
          right: 12,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: searchFieldFocusNode,
                  onChanged: (value) {
                    setState(() {
                      _searchString = value;
                    });
                  },
                  style: STextStyles.field(context),
                  decoration: standardInputDecoration(
                    "Search",
                    searchFieldFocusNode,
                    context,
                  ).copyWith(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 16,
                      ),
                      child: SvgPicture.asset(
                        Assets.svg.search,
                        width: 16,
                        height: 16,
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(right: 0),
                            child: UnconstrainedBox(
                              child: Row(
                                children: [
                                  TextFieldIconButton(
                                    child: const XIcon(),
                                    onTap: () async {
                                      setState(() {
                                        _searchController.text = "";
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Expanded(
              child: Consumer(
                builder: (_, ref, __) {
                  final managerProvider = ref.watch(
                      walletsChangeNotifierProvider.select(
                          (value) => value.getManagerProvider(walletId)));

                  final criteria =
                      ref.watch(transactionFilterProvider.state).state;

                  debugPrint("Consumer build called");

                  return FutureBuilder(
                    future: ref.watch(managerProvider
                        .select((value) => value.transactionData)),
                    builder: (_, AsyncSnapshot<TransactionData> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        final filtered = filter(
                            transactions: snapshot.data!
                                .getAllTransactions()
                                .values
                                .toList(),
                            filter: criteria);

                        final searched = search(_searchString, filtered);

                        final monthlyList = groupTransactionsByMonth(searched);
                        return ListView.builder(
                          itemCount: monthlyList.length,
                          itemBuilder: (_, index) {
                            final month = monthlyList[index];
                            return Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (index != 0)
                                    const SizedBox(
                                      height: 12,
                                    ),
                                  Text(
                                    month.item1,
                                    style: STextStyles.smallMed12(context),
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  RoundedWhiteContainer(
                                    padding: const EdgeInsets.all(0),
                                    child: Column(
                                      children: [
                                        ...month.item2.map(
                                          (tx) => TransactionCard(
                                            key: Key(
                                                "transactionCard_key_${tx.txid}"),
                                            transaction: tx,
                                            walletId: walletId,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      } else {
                        // TODO: proper loading indicator
                        return const LoadingIndicator();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
