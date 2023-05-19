import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/receive_view/addresses/address_card.dart';
import 'package:stackwallet/pages_desktop_specific/addresses/desktop_wallet_addresses_view.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class DesktopAddressList extends ConsumerStatefulWidget {
  const DesktopAddressList({
    Key? key,
    required this.walletId,
    this.searchHeight,
  }) : super(key: key);

  final String walletId;
  final double? searchHeight;

  @override
  ConsumerState<DesktopAddressList> createState() => _DesktopAddressListState();
}

class _DesktopAddressListState extends ConsumerState<DesktopAddressList> {
  final bool isDesktop = Util.isDesktop;

  String _searchString = "";

  late final TextEditingController _searchController;
  final searchFieldFocusNode = FocusNode();

  List<Id> _search(String term) {
    if (term.isEmpty) {
      return ref
          .read(mainDBProvider)
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
                (q) => q
                    .tagsIsNotNull()
                    .and()
                    .tagsElementContains(term, caseSensitive: false),
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
    final coin = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId).coin));

    final ids = _search(_searchString);

    return Column(
      children: [
        SizedBox(
          height: widget.searchHeight!,
          child: Center(
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
        ),
        const SizedBox(
          height: 20,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: RoundedWhiteContainer(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: ids.length,
                separatorBuilder: (_, __) => Container(
                  height: 1,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .backgroundAppBar,
                ),
                itemBuilder: (_, index) => Padding(
                  padding: const EdgeInsets.all(4),
                  child: AddressCard(
                    key: Key("addressCardDesktop_key_${ids[index]}"),
                    walletId: widget.walletId,
                    addressId: ids[index],
                    coin: coin,
                    onPressed: () {
                      ref.read(desktopSelectedAddressId.state).state =
                          ids[index];
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
