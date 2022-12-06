import 'package:epicmobile/models/contact.dart';
import 'package:epicmobile/models/contact_address_entry.dart';
import 'package:epicmobile/pages/address_book_views/subviews/add_address_book_entry_view.dart';
import 'package:epicmobile/pages/address_book_views/subviews/contact_popup.dart';
import 'package:epicmobile/providers/global/address_book_service_provider.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/providers/ui/address_book_providers/address_book_filter_provider.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/rounded_container.dart';
import 'package:epicmobile/widgets/stack_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class AddressBookView extends ConsumerStatefulWidget {
  const AddressBookView({Key? key}) : super(key: key);

  static const String routeName = "/addressBook";

  @override
  ConsumerState<AddressBookView> createState() => _AddressBookViewState();
}

class _AddressBookViewState extends ConsumerState<AddressBookView> {
  late final TextEditingController _searchController;

  late final FocusNode _searchFocusNode;

  String _searchTerm = "";

  void showContextMenu() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 160,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return RoundedContainer(
                          padding: const EdgeInsets.all(8),
                          color:
                              Theme.of(context).extension<StackColors>()!.coal,
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  //
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  width: constraints.minWidth,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Import",
                                      style: STextStyles.body(context),
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  //
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  width: constraints.minWidth,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Export",
                                      style: STextStyles.body(context),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    ref.refresh(addressBookFilterProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      List<ContactAddressEntry> addresses = [];

      addresses.add(
        ContactAddressEntry(
          coin: ref.read(walletProvider)!.coin,
          address: await (ref.read(walletProvider)!).currentReceivingAddress,
          label: "Current Receiving",
          other: ref.read(walletProvider)!.walletName,
        ),
      );

      final self = Contact(
        name: "My Wallet",
        addresses: addresses,
        isFavorite: true,
        id: "default",
      );
      await ref.read(addressBookServiceProvider).editContact(self);
    });
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void sort(List<Contact> contacts, Map<int, String> charMap) {
    contacts
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    String c = "";
    String p = "";
    for (int i = 0; i < contacts.length; i++) {
      if (contacts[i].name.isNotEmpty) {
        c = contacts[i].name.characters.first.toUpperCase();

        if (c != p) {
          p = c;
          charMap[i] = c;
        }
      }
    }
  }

  Future<void> showContactPopup(String contactId) async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return StackDialogBase(
          mainAxisAlignment: MainAxisAlignment.center,
          padding: const EdgeInsets.all(0),
          child: ContactPopUp(contactId: contactId),
        );
      },
    );

    if (result == "delete_contact") {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await ref.read(addressBookServiceProvider).removeContact(contactId);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final contacts =
        ref.watch(addressBookServiceProvider.select((value) => value.contacts));

    final Map<int, String> charMap = {};

    sort(contacts, charMap);

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          centerTitle: true,
          title: Text(
            "Address book",
            style: STextStyles.titleH4(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                right: 10,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: AppBarIconButton(
                  key: const Key("addressBookSearchViewButton"),
                  size: 36,
                  shadows: const [],
                  color: Theme.of(context).extension<StackColors>()!.background,
                  icon: SvgPicture.asset(
                    Assets.svg.search,
                  ),
                  onPressed: () {
                    // Navigator.of(context).pushNamed(
                    //   AddressBookFilterView.routeName,
                    // );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                right: 16,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: AppBarIconButton(
                  key: const Key("addressBookAddNewContactViewButton"),
                  size: 36,
                  shadows: const [],
                  color: Theme.of(context).extension<StackColors>()!.background,
                  icon: SvgPicture.asset(
                    Assets.svg.ellipsis,
                  ),
                  onPressed: () {
                    showContextMenu();
                  },
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 10,
              right: 24,
              top: 24,
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];

                      return GestureDetector(
                        onTap: () => showContactPopup(contact.id),
                        child: Container(
                          color: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: Center(
                                    child: Text(
                                      charMap[index] ?? "",
                                      style: STextStyles.bodyBold(context)
                                          .copyWith(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .textMedium,
                                      ),
                                    ),
                                  ),
                                ),
                                SvgPicture.asset(
                                  Assets.svg.user,
                                ),
                                const SizedBox(
                                  width: 16,
                                ),
                                Text(
                                  contact.name,
                                  style: STextStyles.body(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: RawMaterialButton(
            fillColor: Theme.of(context).extension<StackColors>()!.textGold,
            elevation: 0,
            hoverElevation: 0,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            constraints: const BoxConstraints(
              maxWidth: 56,
              minHeight: 56,
              minWidth: 56,
              maxHeight: 56,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(56),
            ),
            onPressed: () {
              Navigator.of(context).pushNamed(
                AddAddressBookEntryView.routeName,
              );
            },
            child: SvgPicture.asset(
              Assets.svg.plus,
            ),
          ),
        ),
        // body: SafeArea(
        //   child: Padding(
        //     padding: const EdgeInsets.only(
        //       left: 12,
        //       top: 12,
        //       right: 12,
        //     ),
        //     child: LayoutBuilder(
        //       builder: (builderContext, constraints) {
        //         return SingleChildScrollView(
        //           child: ConstrainedBox(
        //             constraints: BoxConstraints(
        //               minHeight: constraints.maxHeight,
        //             ),
        //             child: IntrinsicHeight(
        //               child: Padding(
        //                 padding: const EdgeInsets.all(4),
        //                 child: Column(
        //                   crossAxisAlignment: CrossAxisAlignment.stretch,
        //                   children: [
        //                     ClipRRect(
        //                       borderRadius: BorderRadius.circular(
        //                         Constants.size.circularBorderRadius,
        //                       ),
        //                       child: TextField(
        //                         autocorrect: Util.isDesktop ? false : true,
        //                         enableSuggestions:
        //                             Util.isDesktop ? false : true,
        //                         controller: _searchController,
        //                         focusNode: _searchFocusNode,
        //                         onChanged: (value) {
        //                           setState(() {
        //                             _searchTerm = value;
        //                           });
        //                         },
        //                         style: STextStyles.field(context),
        //                         decoration: standardInputDecoration(
        //                           "Search",
        //                           _searchFocusNode,
        //                           context,
        //                         ).copyWith(
        //                           prefixIcon: Padding(
        //                             padding: const EdgeInsets.symmetric(
        //                               horizontal: 10,
        //                               vertical: 16,
        //                             ),
        //                             child: SvgPicture.asset(
        //                               Assets.svg.search,
        //                               width: 16,
        //                               height: 16,
        //                             ),
        //                           ),
        //                           suffixIcon: _searchController.text.isNotEmpty
        //                               ? Padding(
        //                                   padding:
        //                                       const EdgeInsets.only(right: 0),
        //                                   child: UnconstrainedBox(
        //                                     child: Row(
        //                                       children: [
        //                                         TextFieldIconButton(
        //                                           child: const XIcon(),
        //                                           onTap: () async {
        //                                             setState(() {
        //                                               _searchController.text =
        //                                                   "";
        //                                             });
        //                                           },
        //                                         ),
        //                                       ],
        //                                     ),
        //                                   ),
        //                                 )
        //                               : null,
        //                         ),
        //                       ),
        //                     ),
        //                     const SizedBox(
        //                       height: 16,
        //                     ),
        //                     Text(
        //                       "Favorites",
        //                       style: STextStyles.smallMed12(context),
        //                     ),
        //                     const SizedBox(
        //                       height: 12,
        //                     ),
        //                     Builder(
        //                       builder: (context) {
        //                         final filteredFavorites = contacts.where((e) =>
        //                             e.isFavorite &&
        //                             ref
        //                                 .read(addressBookServiceProvider)
        //                                 .matches(_searchTerm, e));
        //
        //                         if (filteredFavorites.isNotEmpty) {
        //                           return RoundedWhiteContainer(
        //                             padding: const EdgeInsets.all(0),
        //                             child: Column(
        //                               children: [
        //                                 ...filteredFavorites.map(
        //                                   (e) => AddressBookCard(
        //                                     key: Key(
        //                                         "favContactCard_${e.id}_key"),
        //                                     contactId: e.id,
        //                                   ),
        //                                 ),
        //                               ],
        //                             ),
        //                           );
        //                         } else {
        //                           return RoundedWhiteContainer(
        //                             child: Center(
        //                               child: Text(
        //                                 "Your favorite contacts will appear here",
        //                                 style:
        //                                     STextStyles.itemSubtitle(context),
        //                               ),
        //                             ),
        //                           );
        //                         }
        //                       },
        //                     ),
        //                     const SizedBox(
        //                       height: 16,
        //                     ),
        //                     Text(
        //                       "All contacts",
        //                       style: STextStyles.smallMed12(context),
        //                     ),
        //                     const SizedBox(
        //                       height: 12,
        //                     ),
        //                     Builder(
        //                       builder: (context) {
        //                         final filtered = contacts.where((e) =>
        //                             !e.isFavorite &&
        //                             ref
        //                                 .read(addressBookServiceProvider)
        //                                 .matches(_searchTerm, e));
        //
        //                         if (filtered.isNotEmpty) {
        //                           return RoundedWhiteContainer(
        //                             padding: const EdgeInsets.all(0),
        //                             child: Column(
        //                               children: [
        //                                 ...filtered.map(
        //                                   (e) => AddressBookCard(
        //                                     key: Key("contactCard_${e.id}_key"),
        //                                     contactId: e.id,
        //                                   ),
        //                                 ),
        //                               ],
        //                             ),
        //                           );
        //                         } else {
        //                           return RoundedWhiteContainer(
        //                             child: Center(
        //                               child: Text(
        //                                 "Your contacts will appear here",
        //                                 style:
        //                                     STextStyles.itemSubtitle(context),
        //                               ),
        //                             ),
        //                           );
        //                         }
        //                       },
        //                     ),
        //                   ],
        //                 ),
        //               ),
        //             ),
        //           ),
        //         );
        //       },
        //     ),
        //   ),
        // ),
      ),
    );
  }
}
