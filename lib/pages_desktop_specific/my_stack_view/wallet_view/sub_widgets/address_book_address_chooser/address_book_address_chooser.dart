import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackduo/models/contact.dart';
import 'package:stackduo/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/address_book_address_chooser/sub_widgets/contact_list_item.dart';
import 'package:stackduo/providers/global/address_book_service_provider.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/icon_widgets/x_icon.dart';
import 'package:stackduo/widgets/stack_text_field.dart';
import 'package:stackduo/widgets/textfield_icon_button.dart';

class AddressBookAddressChooser extends StatefulWidget {
  const AddressBookAddressChooser({
    Key? key,
    this.coin,
  }) : super(key: key);

  final Coin? coin;

  @override
  State<AddressBookAddressChooser> createState() =>
      _AddressBookAddressChooserState();
}

class _AddressBookAddressChooserState extends State<AddressBookAddressChooser> {
  late final bool isDesktop;
  late final TextEditingController _searchController;
  late final FocusNode searchFieldFocusNode;

  String _searchTerm = "";

  int _compareContactFavorite(Contact a, Contact b) {
    if (a.isFavorite && b.isFavorite) {
      return 0;
    } else if (a.isFavorite) {
      return 1;
    } else {
      return -1;
    }
  }

  List<Contact> pullOutFavorites(List<Contact> contacts) {
    final List<Contact> favorites = [];
    contacts.removeWhere((contact) {
      if (contact.isFavorite) {
        favorites.add(contact);
        return true;
      }
      return false;
    });

    return favorites;
  }

  List<Contact> filter(List<Contact> contacts, String searchTerm) {
    if (widget.coin != null) {
      contacts.removeWhere(
          (e) => e.addresses.where((a) => a.coin == widget.coin!).isEmpty);
    }

    contacts.retainWhere((e) => _matches(searchTerm, e));

    if (contacts.length < 2) {
      return contacts;
    }

    // redundant due to pullOutFavorites?
    contacts.sort(_compareContactFavorite);

    return contacts;
  }

  bool _matches(String term, Contact contact) {
    final text = term.toLowerCase();
    if (contact.name.toLowerCase().contains(text)) {
      return true;
    }
    for (int i = 0; i < contact.addresses.length; i++) {
      if (contact.addresses[i].label.toLowerCase().contains(text) ||
          contact.addresses[i].coin.name.toLowerCase().contains(text) ||
          contact.addresses[i].coin.prettyName.toLowerCase().contains(text) ||
          contact.addresses[i].coin.ticker.toLowerCase().contains(text) ||
          contact.addresses[i].address.toLowerCase().contains(text)) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    isDesktop = Util.isDesktop;
    searchFieldFocusNode = FocusNode();
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
    return Column(
      children: [
        // search field
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
          ),
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
                  _searchTerm = value;
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
                                    _searchTerm = "";
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
          height: 16,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 32,
              right: 32,
              bottom: 32,
            ),
            child: Consumer(
              builder: (context, ref, _) {
                List<Contact> contacts = ref
                    .watch(addressBookServiceProvider
                        .select((value) => value.contacts))
                    .toList();

                contacts = filter(contacts, _searchTerm);

                final favorites = pullOutFavorites(contacts);

                final totalLength = favorites.length +
                    contacts.length +
                    2; // +2 for "fav" and "all" headers

                return ListView.separated(
                  primary: false,
                  shrinkWrap: true,
                  itemCount: totalLength,
                  separatorBuilder: (context, index) {
                    return const SizedBox(
                      height: 10,
                    );
                  },
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        key: const Key(
                            "addressBookCAddressChooserFavoritesHeaderItemKey"),
                        padding: const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: Text(
                          "Favorites",
                          style:
                              STextStyles.desktopTextExtraExtraSmall(context),
                        ),
                      );
                    } else if (index < favorites.length + 1) {
                      final id = favorites[index - 1].id;
                      return ContactListItem(
                        key: Key("contactContactListItem_${id}_key"),
                        contactId: id,
                        filterByCoin: widget.coin,
                      );
                    } else if (index == favorites.length + 1) {
                      return Padding(
                        key: const Key(
                            "addressBookCAddressChooserAllContactsHeaderItemKey"),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        child: Text(
                          "All contacts",
                          style:
                              STextStyles.desktopTextExtraExtraSmall(context),
                        ),
                      );
                    } else {
                      final id = contacts[index - favorites.length - 2].id;
                      return ContactListItem(
                        key: Key("contactContactListItem_${id}_key"),
                        contactId: id,
                        filterByCoin: widget.coin,
                      );
                    }
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
