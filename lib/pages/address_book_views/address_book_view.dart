import 'package:epicmobile/models/contact.dart';
import 'package:epicmobile/models/contact_address_entry.dart';
import 'package:epicmobile/pages/address_book_views/subviews/add_address_book_entry_view.dart';
import 'package:epicmobile/pages/address_book_views/subviews/contact_popup.dart';
import 'package:epicmobile/providers/global/address_book_service_provider.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/icon_widgets/x_icon.dart';
import 'package:epicmobile/widgets/rounded_container.dart';
import 'package:epicmobile/widgets/stack_dialog.dart';
import 'package:epicmobile/widgets/textfield_icon_button.dart';
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
  bool _enableSearch = false;

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
  void initState() {
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

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

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final contacts = ref.watch(addressBookServiceProvider
        .select((value) => value.search(_searchTerm)));

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
          title: !_enableSearch
              ? Text(
                  "Address book",
                  style: STextStyles.titleH4(context),
                )
              : Row(
                  children: [
                    const SizedBox(
                      width: 2,
                    ),
                    Expanded(
                      child: TextField(
                        autocorrect: false,
                        enableSuggestions: false,
                        autofocus: true,
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (value) {
                          setState(() {
                            _searchTerm = value;
                          });
                        },
                        style: STextStyles.body(context),
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          focusColor: Colors.transparent,
                          fillColor: Colors.transparent,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 0,
                          ),
                          // labelStyle: STextStyles.fieldLabel(context),
                          // hintStyle: STextStyles.fieldLabel(context),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 1,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textGold,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 1,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textGold,
                            ),
                          ),
                          errorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 1,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textGold,
                            ),
                          ),
                          disabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 1,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textGold,
                            ),
                          ),
                          focusedErrorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 1,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textGold,
                            ),
                          ),
                          // border: InputBorder.none,
                          isCollapsed: true,
                          hintText: "Search...",
                          hintStyle: STextStyles.body(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          prefixIcon: SizedBox(
                            width: 32,
                            height: 39,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: SvgPicture.asset(
                                  Assets.svg.search,
                                  width: 24,
                                  height: 24,
                                ),
                              ),
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
                    const SizedBox(
                      width: 40,
                    ),
                  ],
                ),
          actions: [
            if (!_enableSearch)
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
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    icon: SvgPicture.asset(
                      Assets.svg.search,
                    ),
                    onPressed: () {
                      setState(() {
                        _enableSearch = true;
                      });
                    },
                  ),
                ),
              ),
            // Padding(
            //   padding: const EdgeInsets.only(
            //     top: 10,
            //     bottom: 10,
            //     right: 16,
            //   ),
            //   child: AspectRatio(
            //     aspectRatio: 1,
            //     child: AppBarIconButton(
            //       key: const Key("addressBookAddNewContactViewButton"),
            //       size: 36,
            //       shadows: const [],
            //       color: Theme.of(context).extension<StackColors>()!.background,
            //       icon: SvgPicture.asset(
            //         Assets.svg.ellipsis,
            //       ),
            //       onPressed: () {
            //         showContextMenu();
            //       },
            //     ),
            //   ),
            // ),
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
      ),
    );
  }
}
