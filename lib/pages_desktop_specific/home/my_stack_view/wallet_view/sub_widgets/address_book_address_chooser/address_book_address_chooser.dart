import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/contact.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/wallet_view/sub_widgets/address_book_address_chooser/sub_widgets/contact_list_item.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';

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

  List<Contact> filter(List<Contact> contacts) {
    if (widget.coin != null) {
      contacts.removeWhere(
          (e) => e.addresses.where((a) => a.coin == widget.coin!).isEmpty);
    }

    if (contacts.length < 2) {
      return contacts;
    }

    contacts.sort(_compareContactFavorite);

    // TODO: other filtering?

    return contacts;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // search field
        const TextField(),
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

                contacts = filter(contacts);

                final favorites = pullOutFavorites(contacts);

                return ListView.builder(
                  primary: false,
                  shrinkWrap: true,
                  itemCount: favorites.length +
                      contacts.length +
                      2, // +2 for "fav" and "all" headers
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: Text(
                          "Favorites",
                          style:
                              STextStyles.desktopTextExtraExtraSmall(context),
                        ),
                      );
                    } else if (index <= favorites.length) {
                      final id = favorites[index - 1].id;
                      return ContactListItem(
                        key: Key("contactCard_${id}_key"),
                        contactId: id,
                        filterByCoin: widget.coin,
                      );
                    } else if (index == favorites.length + 1) {
                      return Padding(
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
                      final id = contacts[index - favorites.length - 1].id;
                      return ContactListItem(
                        key: Key("contactCard_${id}_key"),
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
