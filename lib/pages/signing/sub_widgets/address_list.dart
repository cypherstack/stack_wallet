import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../models/isar/models/address_label.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/isar/providers/wallet_info_provider.dart';
import '../../../widgets/background.dart';
import '../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../receive_view/addresses/address_card.dart';

class AddressList extends ConsumerStatefulWidget {
  const AddressList({super.key, required this.walletId});

  final String walletId;

  @override
  ConsumerState<AddressList> createState() => _AddressListState();
}

class _AddressListState extends ConsumerState<AddressList> {
  String _searchString = "";

  late final TextEditingController _searchController;
  final searchFieldFocusNode = FocusNode();

  List<Id> _search(String term) {
    if (term.isEmpty) {
      return ref
          .read(mainDBProvider)
          .getAddresses(widget.walletId)
          .filter()
          .group(
            (q) => q
                .subTypeEqualTo(AddressSubType.change)
                .or()
                .subTypeEqualTo(AddressSubType.receiving)
                .or()
                .subTypeEqualTo(AddressSubType.paynymReceive)
                .or()
                .subTypeEqualTo(AddressSubType.paynymNotification),
          )
          .and()
          .not()
          .typeEqualTo(AddressType.nonWallet)
          .and()
          .group(
            (q) => q
                .group(
                  (q2) => q2
                      .typeEqualTo(AddressType.frostMS)
                      .and()
                      .zSafeFrostEqualTo(true),
                )
                .or()
                .not()
                .typeEqualTo(AddressType.frostMS),
          )
          .sortByDerivationIndex()
          .idProperty()
          .findAllSync();
    }

    final labels = ref
        .read(mainDBProvider)
        .getAddressLabels(widget.walletId)
        .filter()
        .group(
          (q) => q
              .valueContains(term, caseSensitive: false)
              .or()
              .addressStringContains(term, caseSensitive: false)
              .or()
              .group(
                (q) => q.tagsIsNotNull().and().tagsElementContains(
                  term,
                  caseSensitive: false,
                ),
              ),
        )
        .findAllSync();

    if (labels.isEmpty) {
      return [];
    }

    return ref
        .read(mainDBProvider)
        .getAddresses(widget.walletId)
        .filter()
        .anyOf<AddressLabel, Address>(
          labels,
          (q, e) => q.valueEqualTo(e.addressString),
        )
        .group(
          (q) => q
              .subTypeEqualTo(AddressSubType.change)
              .or()
              .subTypeEqualTo(AddressSubType.receiving)
              .or()
              .subTypeEqualTo(AddressSubType.paynymReceive)
              .or()
              .subTypeEqualTo(AddressSubType.paynymNotification),
        )
        .and()
        .not()
        .typeEqualTo(AddressType.nonWallet)
        .and()
        .group(
          (q) => q
              .group(
                (q2) => q2
                    .typeEqualTo(AddressType.frostMS)
                    .and()
                    .zSafeFrostEqualTo(true),
              )
              .or()
              .not()
              .typeEqualTo(AddressType.frostMS),
        )
        .sortByDerivationIndex()
        .idProperty()
        .findAllSync();
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
    final coin = ref.watch(pWalletCoin(widget.walletId));

    final ids = _search(_searchString);

    return ListView.separated(
      shrinkWrap: true,
      itemCount: ids.length,
      separatorBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Util.isDesktop
            ? Container(
                height: 1,
                color: Theme.of(
                  context,
                ).extension<StackColors>()!.textFieldDefaultBG,
              )
            : const SizedBox(height: 2),
      ),
      itemBuilder: (_, index) => Padding(
        padding: const EdgeInsets.all(4),
        child: AddressCard(
          key: Key("addressCardDesktop_key_${ids[index]}"),
          walletId: widget.walletId,
          compact: true,
          addressId: ids[index],
          coin: coin,
          onPressed: () => Navigator.of(
            context,
          ).pop(ref.read(mainDBProvider).isar.addresses.getSync(ids[index])!),
        ),
      ),
    );
  }
}

class CompactAddressListView extends StatelessWidget {
  const CompactAddressListView({super.key, required this.walletId});

  final String walletId;

  static const routeName = "/compactAddressListView";

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Choose address",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: Constants.size.standardPadding,
              left: Constants.size.standardPadding,
              right: Constants.size.standardPadding,
            ),
            child: AddressList(walletId: walletId),
          ),
        ),
      ),
    );
  }
}
