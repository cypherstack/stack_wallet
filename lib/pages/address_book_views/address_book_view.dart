import 'package:epicmobile/models/contact.dart';
import 'package:epicmobile/models/contact_address_entry.dart';
import 'package:epicmobile/providers/global/address_book_service_provider.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/providers/ui/address_book_providers/address_book_filter_provider.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:epicmobile/widgets/address_book_card.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/icon_widgets/x_icon.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
import 'package:epicmobile/widgets/stack_text_field.dart';
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

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final contacts =
        ref.watch(addressBookServiceProvider.select((value) => value.contacts));

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
                right: 10,
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
                    // Navigator.of(context).pushNamed(
                    //   AddAddressBookEntryView.routeName,
                    // );
                  },
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 12,
              top: 12,
              right: 12,
            ),
            child: LayoutBuilder(
              builder: (builderContext, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                Constants.size.circularBorderRadius,
                              ),
                              child: TextField(
                                autocorrect: Util.isDesktop ? false : true,
                                enableSuggestions:
                                    Util.isDesktop ? false : true,
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                onChanged: (value) {
                                  setState(() {
                                    _searchTerm = value;
                                  });
                                },
                                style: STextStyles.field(context),
                                decoration: standardInputDecoration(
                                  "Search",
                                  _searchFocusNode,
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
                                          padding:
                                              const EdgeInsets.only(right: 0),
                                          child: UnconstrainedBox(
                                            child: Row(
                                              children: [
                                                TextFieldIconButton(
                                                  child: const XIcon(),
                                                  onTap: () async {
                                                    setState(() {
                                                      _searchController.text =
                                                          "";
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
                              height: 16,
                            ),
                            Text(
                              "Favorites",
                              style: STextStyles.smallMed12(context),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Builder(
                              builder: (context) {
                                final filteredFavorites = contacts.where((e) =>
                                    e.isFavorite &&
                                    ref
                                        .read(addressBookServiceProvider)
                                        .matches(_searchTerm, e));

                                if (filteredFavorites.isNotEmpty) {
                                  return RoundedWhiteContainer(
                                    padding: const EdgeInsets.all(0),
                                    child: Column(
                                      children: [
                                        ...filteredFavorites.map(
                                          (e) => AddressBookCard(
                                            key: Key(
                                                "favContactCard_${e.id}_key"),
                                            contactId: e.id,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  return RoundedWhiteContainer(
                                    child: Center(
                                      child: Text(
                                        "Your favorite contacts will appear here",
                                        style:
                                            STextStyles.itemSubtitle(context),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            Text(
                              "All contacts",
                              style: STextStyles.smallMed12(context),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Builder(
                              builder: (context) {
                                final filtered = contacts.where((e) =>
                                    !e.isFavorite &&
                                    ref
                                        .read(addressBookServiceProvider)
                                        .matches(_searchTerm, e));

                                if (filtered.isNotEmpty) {
                                  return RoundedWhiteContainer(
                                    padding: const EdgeInsets.all(0),
                                    child: Column(
                                      children: [
                                        ...filtered.map(
                                          (e) => AddressBookCard(
                                            key: Key("contactCard_${e.id}_key"),
                                            contactId: e.id,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  return RoundedWhiteContainer(
                                    child: Center(
                                      child: Text(
                                        "Your contacts will appear here",
                                        style:
                                            STextStyles.itemSubtitle(context),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
