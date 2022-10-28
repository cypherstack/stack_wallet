import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/contact.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart';
import 'package:stackwallet/models/transaction_filter.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/tx_icon.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_search_filter_view.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/ui/transaction_filter_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
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
    final isDesktop = Util.isDesktop;

    return MasterScaffold(
      background: Theme.of(context).extension<StackColors>()!.background,
      isDesktop: isDesktop,
      appBar: isDesktop
          ? DesktopAppBar(
              isCompactHeight: true,
              background: Theme.of(context).extension<StackColors>()!.popupBG,
              leading: Row(
                children: [
                  const SizedBox(
                    width: 32,
                  ),
                  AppBarIconButton(
                    size: 32,
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldDefaultBG,
                    shadows: const [],
                    icon: SvgPicture.asset(
                      Assets.svg.arrowLeft,
                      width: 18,
                      height: 18,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .topNavIconPrimary,
                    ),
                    onPressed: Navigator.of(context).pop,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Text(
                    "Transactions",
                    style: STextStyles.desktopH3(context),
                  ),
                ],
              ),
            )
          : AppBar(
              backgroundColor:
                  Theme.of(context).extension<StackColors>()!.background,
              leading: AppBarBackButton(
                onPressed: () async {
                  if (FocusScope.of(context).hasFocus) {
                    FocusScope.of(context).unfocus();
                    await Future<void>.delayed(
                        const Duration(milliseconds: 75));
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
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .background,
                      icon: SvgPicture.asset(
                        Assets.svg.filter,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark,
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
        padding: EdgeInsets.only(
          left: isDesktop ? 20 : 12,
          top: isDesktop ? 20 : 12,
          right: isDesktop ? 20 : 12,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  SizedBox(
                    width: isDesktop ? 570 : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                      child: TextField(
                        autocorrect: !isDesktop,
                        enableSuggestions: !isDesktop,
                        controller: _searchController,
                        focusNode: searchFieldFocusNode,
                        onChanged: (value) {
                          setState(() {
                            _searchString = value;
                          });
                        },
                        style: isDesktop
                            ? STextStyles.desktopTextExtraSmall(context)
                                .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textFieldActiveText,
                                height: 1.8,
                              )
                            : STextStyles.field(context),
                        decoration: standardInputDecoration(
                          "Search",
                          searchFieldFocusNode,
                          context,
                          desktopMed: isDesktop,
                        ).copyWith(
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 12 : 10,
                              vertical: isDesktop ? 18 : 16,
                            ),
                            child: SvgPicture.asset(
                              Assets.svg.search,
                              width: isDesktop ? 20 : 16,
                              height: isDesktop ? 20 : 16,
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
                                              _searchString = "";
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
                  if (isDesktop)
                    const SizedBox(
                      width: 20,
                    ),
                  if (isDesktop)
                    SecondaryButton(
                      desktopMed: isDesktop,
                      width: 200,
                      label: "Filter",
                      icon: SvgPicture.asset(
                        Assets.svg.filter,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark,
                        width: 20,
                        height: 20,
                      ),
                      onPressed: () {
                        final coin = ref
                            .read(walletsChangeNotifierProvider)
                            .getManager(walletId)
                            .coin;
                        if (isDesktop) {
                          showDialog<void>(
                            context: context,
                            builder: (context) {
                              return TransactionSearchFilterView(
                                coin: coin,
                              );
                            },
                          );
                        } else {
                          Navigator.of(context).pushNamed(
                            TransactionSearchFilterView.routeName,
                            arguments: coin,
                          );
                        }
                      },
                    ),
                ],
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
                          primary: isDesktop ? false : null,
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
                                  if (isDesktop)
                                    RoundedWhiteContainer(
                                      padding: const EdgeInsets.all(0),
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        primary: false,
                                        separatorBuilder: (context, _) =>
                                            Container(
                                          height: 1,
                                          color: Theme.of(context)
                                              .extension<StackColors>()!
                                              .background,
                                        ),
                                        itemCount: month.item2.length,
                                        itemBuilder: (context, index) =>
                                            Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: DesktopTransactionCardRow(
                                            transaction: month.item2[index],
                                            walletId: walletId,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (!isDesktop)
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

class DesktopTransactionCardRow extends ConsumerStatefulWidget {
  const DesktopTransactionCardRow({
    Key? key,
    required this.transaction,
    required this.walletId,
  }) : super(key: key);

  final Transaction transaction;
  final String walletId;

  @override
  ConsumerState<DesktopTransactionCardRow> createState() =>
      _DesktopTransactionCardRowState();
}

class _DesktopTransactionCardRowState
    extends ConsumerState<DesktopTransactionCardRow> {
  late final Transaction _transaction;
  late final String walletId;

  String whatIsIt(String type, Coin coin) {
    if (coin == Coin.epicCash && _transaction.slateId == null) {
      return "Restored Funds";
    }

    if (_transaction.subType == "mint") {
      if (_transaction.confirmedStatus) {
        return "Anonymized";
      } else {
        return "Anonymizing";
      }
    }

    if (type == "Received") {
      if (_transaction.confirmedStatus) {
        return "Received";
      } else {
        return "Receiving";
      }
    } else if (type == "Sent") {
      if (_transaction.confirmedStatus) {
        return "Sent";
      } else {
        return "Sending";
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
    final locale = ref.watch(
        localeServiceChangeNotifierProvider.select((value) => value.locale));
    final manager = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(walletId)));

    final baseCurrency = ref
        .watch(prefsChangeNotifierProvider.select((value) => value.currency));

    final coin = manager.coin;

    final price = ref
        .watch(priceAnd24hChangeNotifierProvider
            .select((value) => value.getPrice(coin)))
        .item1;

    late final String prefix;
    if (Util.isDesktop) {
      if (_transaction.txType == "Sent") {
        prefix = "-";
      } else if (_transaction.txType == "Received") {
        prefix = "+";
      }
    } else {
      prefix = "";
    }

    return Material(
      color: Theme.of(context).extension<StackColors>()!.popupBG,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(Constants.size.circularBorderRadius),
      ),
      child: RawMaterialButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        onPressed: () async {
          if (coin == Coin.epicCash && _transaction.slateId == null) {
            unawaited(
              showFloatingFlushBar(
                context: context,
                message:
                    "Restored Epic funds from your Seed have no Data.\nUse Stack Backup to keep your transaction history.",
                type: FlushBarType.warning,
                duration: const Duration(seconds: 5),
              ),
            );
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
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 16,
          ),
          child: Row(
            children: [
              TxIcon(transaction: _transaction),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                flex: 3,
                child: Text(
                  _transaction.isCancelled
                      ? "Cancelled"
                      : whatIsIt(_transaction.txType, coin),
                  style:
                      STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  Format.extractDateFrom(_transaction.timestamp),
                  style: STextStyles.label(context),
                ),
              ),
              Expanded(
                flex: 6,
                child: Builder(
                  builder: (_) {
                    final amount = coin == Coin.monero
                        ? (_transaction.amount ~/ 10000)
                        : coin == Coin.wownero
                            ? (_transaction.amount ~/ 1000)
                            : _transaction.amount;
                    return Text(
                      "$prefix${Format.satoshiAmountToPrettyString(amount, locale)} ${coin.ticker}",
                      style: STextStyles.desktopTextExtraExtraSmall(context)
                          .copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark,
                      ),
                    );
                  },
                ),
              ),
              if (ref.watch(prefsChangeNotifierProvider
                  .select((value) => value.externalCalls)))
                Expanded(
                  flex: 4,
                  child: Builder(
                    builder: (_) {
                      // TODO: modify Format.<functions> to take optional Coin parameter so this type oif check isn't done in ui
                      int value = _transaction.amount;
                      if (coin == Coin.monero) {
                        value = (value ~/ 10000);
                      } else if (coin == Coin.wownero) {
                        value = (value ~/ 1000);
                      }

                      return Text(
                        "$prefix${Format.localizedStringAsFixed(
                          value: Format.satoshisToAmount(value) * price,
                          locale: locale,
                          decimalPlaces: 2,
                        )} $baseCurrency",
                        style: STextStyles.desktopTextExtraExtraSmall(context),
                      );
                    },
                  ),
                ),
              SvgPicture.asset(
                Assets.svg.circleInfo,
                width: 20,
                height: 20,
                color:
                    Theme.of(context).extension<StackColors>()!.textSubtitle2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
