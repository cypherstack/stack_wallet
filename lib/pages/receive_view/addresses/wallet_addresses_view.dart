import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';
import 'package:stackduo/db/main_db.dart';
import 'package:stackduo/models/isar/models/isar_models.dart';
import 'package:stackduo/pages/receive_view/addresses/address_card.dart';
import 'package:stackduo/providers/global/wallets_provider.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/background.dart';
import 'package:stackduo/widgets/conditional_parent.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackduo/widgets/loading_indicator.dart';
import 'package:stackduo/widgets/toggle.dart';

class WalletAddressesView extends ConsumerStatefulWidget {
  const WalletAddressesView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  static const String routeName = "/walletAddressesView";

  final String walletId;

  @override
  ConsumerState<WalletAddressesView> createState() =>
      _WalletAddressesViewState();
}

class _WalletAddressesViewState extends ConsumerState<WalletAddressesView> {
  final bool isDesktop = Util.isDesktop;

  String _searchString = "";

  late final TextEditingController _searchController;
  final searchFieldFocusNode = FocusNode();

  Future<List<int>> _search(String term) async {
    if (term.isEmpty) {
      return MainDB.instance
          .getAddresses(widget.walletId)
          .filter()
          .group((q) => q
              .subTypeEqualTo(AddressSubType.change)
              .or()
              .subTypeEqualTo(AddressSubType.receiving)
              .or()
              .subTypeEqualTo(AddressSubType.paynymReceive)
              .or()
              .subTypeEqualTo(AddressSubType.paynymNotification))
          .and()
          .not()
          .typeEqualTo(AddressType.nonWallet)
          .sortByDerivationIndex()
          .idProperty()
          .findAll();
    }

    final labels = await MainDB.instance
        .getAddressLabels(widget.walletId)
        .filter()
        .group(
          (q) => q
              .valueContains(term, caseSensitive: false)
              .or()
              .addressStringContains(term, caseSensitive: false)
              .or()
              .group(
                (q) => q
                    .tagsIsNotNull()
                    .and()
                    .tagsElementContains(term, caseSensitive: false),
              ),
        )
        .findAll();

    if (labels.isEmpty) {
      return [];
    }

    return MainDB.instance
        .getAddresses(widget.walletId)
        .filter()
        .anyOf<AddressLabel, Address>(
            labels, (q, e) => q.valueEqualTo(e.addressString))
        .group((q) => q
            .subTypeEqualTo(AddressSubType.change)
            .or()
            .subTypeEqualTo(AddressSubType.receiving)
            .or()
            .subTypeEqualTo(AddressSubType.paynymReceive)
            .or()
            .subTypeEqualTo(AddressSubType.paynymNotification))
        .and()
        .not()
        .typeEqualTo(AddressType.nonWallet)
        .sortByDerivationIndex()
        .idProperty()
        .findAll();
  }

  @override
  void initState() {
    _searchController = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    searchFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId).coin));
    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) => Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.backgroundAppBar,
            leading: AppBarBackButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            titleSpacing: 0,
            title: Text(
              "Wallet addresses",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: isDesktop ? 490 : null,
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
                    ? STextStyles.desktopTextExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textFieldActiveText,
                        height: 1.8,
                      )
                    : STextStyles.field(context),
                decoration: standardInputDecoration(
                  "Search...",
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
          SizedBox(
            height: isDesktop ? 20 : 16,
          ),
          Expanded(
            child: FutureBuilder(
              future: _search(_searchString),
              builder: (context, AsyncSnapshot<List<int>> snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data != null) {
                  // listview
                  return ListView.separated(
                    itemCount: snapshot.data!.length,
                    separatorBuilder: (_, __) => Container(
                      height: 10,
                    ),
                    itemBuilder: (_, index) => AddressCard(
                      walletId: widget.walletId,
                      addressId: snapshot.data![index],
                      coin: coin,
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AddressDetailsView.routeName,
                          arguments: Tuple2(
                            snapshot.data![index],
                            widget.walletId,
                          ),
                        );
                      },
                    ),
                  );
                } else {
                  return const Center(
                    child: LoadingIndicator(
                      height: 200,
                      width: 200,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
