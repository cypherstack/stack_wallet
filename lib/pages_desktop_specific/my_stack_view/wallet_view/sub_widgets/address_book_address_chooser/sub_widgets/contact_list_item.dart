import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/address_book_card.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/expandable.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_coin_icon.dart';

class ContactListItem extends ConsumerStatefulWidget {
  const ContactListItem({
    Key? key,
    required this.contactId,
    this.filterByCoin,
  }) : super(key: key);

  final String contactId;
  final Coin? filterByCoin;

  @override
  ConsumerState<ContactListItem> createState() => _ContactListItemState();
}

class _ContactListItemState extends ConsumerState<ContactListItem> {
  late final String contactId;
  late final Coin? filterByCoin;

  ExpandableState _state = ExpandableState.collapsed;

  @override
  void initState() {
    contactId = widget.contactId;
    filterByCoin = widget.filterByCoin;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final contact = ref.watch(addressBookServiceProvider
        .select((value) => value.getContactById(contactId)));

    // hack fix until we use a proper database (not Hive)
    int i = 0;

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      borderColor: Theme.of(context).extension<StackColors>()!.background,
      child: Expandable(
        onExpandChanged: (state) {
          setState(() {
            _state = state;
          });
        },
        header: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          child: AddressBookCard(
            contactId: contactId,
            indicatorDown: _state,
          ),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // filter addresses by coin is provided before building address list
            ...contact.addresses
                .where((e) =>
                    filterByCoin != null ? e.coin == filterByCoin! : true)
                .map(
                  (e) => Column(
                    key: Key(
                        "contactAddress_${e.address}_${e.label}_${++i}_key"),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 1,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .background,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  WalletInfoCoinIcon(coin: e.coin),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Flexible(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${contactId == "default" ? e.other! : e.label} (${e.coin.ticker})",
                                          style: STextStyles
                                                  .desktopTextExtraExtraSmall(
                                                      context)
                                              .copyWith(
                                            color: Theme.of(context)
                                                .extension<StackColors>()!
                                                .textDark,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                e.address,
                                                style: STextStyles
                                                    .desktopTextExtraExtraSmall(
                                                        context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CustomTextButton(
                              text: "Select wallet",
                              onTap: () {
                                Navigator.of(context).pop(e);
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
