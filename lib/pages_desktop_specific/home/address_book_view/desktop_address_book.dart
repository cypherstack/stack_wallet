import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/contact.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/pages/address_book_views/subviews/add_address_book_entry_view.dart';
import 'package:stackwallet/pages/address_book_views/subviews/address_book_filter_view.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/address_book_card.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

import '../../../providers/providers.dart';
import '../../../providers/ui/address_book_providers/address_book_filter_provider.dart';

class DesktopAddressBook extends ConsumerStatefulWidget {
  const DesktopAddressBook({Key? key}) : super(key: key);

  static const String routeName = "/desktopAddressBook";

  @override
  ConsumerState<DesktopAddressBook> createState() => _DesktopAddressBook();
}

class _DesktopAddressBook extends ConsumerState<DesktopAddressBook> {
  late final TextEditingController _searchController;

  late final FocusNode _searchFocusNode;

  String _searchTerm = "";

  Future<void> selectCryptocurrency() async {
    await showDialog<dynamic>(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      builder: (context) {
        return const DesktopDialog(
          maxHeight: 609,
          maxWidth: 576,
          child: AddressBookFilterView(),
        );
      },
    );
  }

  Future<void> newContact() async {
    await showDialog<dynamic>(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      builder: (context) {
        return const DesktopDialog(
          maxHeight: 609,
          maxWidth: 576,
          child: AddAddressBookEntryView(),
        );
      },
    );
  }

  @override
  void initState() {
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    ref.refresh(addressBookFilterProvider);

    // if (widget.coin == null) {
    List<Coin> coins = Coin.values.where((e) => !(e == Coin.epicCash)).toList();
    coins.remove(Coin.firoTestNet);

    bool showTestNet = ref.read(prefsChangeNotifierProvider).showTestNetCoins;

    if (showTestNet) {
      ref.read(addressBookFilterProvider).addAll(coins, false);
    } else {
      ref.read(addressBookFilterProvider).addAll(
          coins.getRange(0, coins.length - kTestNetCoinCount + 1), false);
    }
    // } else {
    //   ref.read(addressBookFilterProvider).add(widget.coin!, false);
    // }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      List<ContactAddressEntry> addresses = [];
      final managers = ref.read(walletsChangeNotifierProvider).managers;
      for (final manager in managers) {
        addresses.add(
          ContactAddressEntry(
            coin: manager.coin,
            address: await manager.currentReceivingAddress,
            label: "Current Receiving",
            other: manager.walletName,
          ),
        );
      }
      final self = Contact(
        name: "My Stack",
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

    final allContacts = contacts
        .where((element) => element.addresses
            .where((e) => ref.watch(addressBookFilterProvider
                .select((value) => value.coins.contains(e.coin))))
            .isNotEmpty)
        .where((e) =>
            ref.read(addressBookServiceProvider).matches(_searchTerm, e));

    final favorites = contacts
        .where((element) => element.addresses
            .where((e) => ref.watch(addressBookFilterProvider
                .select((value) => value.coins.contains(e.coin))))
            .isNotEmpty)
        .where((e) =>
            e.isFavorite &&
            ref.read(addressBookServiceProvider).matches(_searchTerm, e))
        .where((element) => element.isFavorite);

    return DesktopScaffold(
      appBar: DesktopAppBar(
        isCompactHeight: true,
        leading: Row(
          children: [
            const SizedBox(
              width: 24,
            ),
            Text(
              "Address Book",
              style: STextStyles.desktopH3(context),
            )
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 24,
        ),
        child: DesktopAddressBookScaffold(
          controlsLeft: ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: TextField(
              autocorrect: Util.isDesktop ? false : true,
              enableSuggestions: Util.isDesktop ? false : true,
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
                    vertical: 20,
                  ),
                  child: SvgPicture.asset(
                    Assets.svg.search,
                    width: 16,
                    height: 16,
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
          controlsRight: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SecondaryButton(
                width: 184,
                label: "Filter",
                desktopMed: true,
                icon: SvgPicture.asset(
                  Assets.svg.filter,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .buttonTextSecondary,
                ),
                onPressed: selectCryptocurrency,
              ),
              const SizedBox(
                width: 20,
              ),
              PrimaryButton(
                width: 184,
                label: "Add new",
                desktopMed: true,
                icon: SvgPicture.asset(
                  Assets.svg.circlePlus,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .buttonTextPrimary,
                ),
                onPressed: newContact,
              ),
            ],
          ),
          filterItems: Container(),
          upperLabel: favorites.isEmpty && allContacts.isEmpty
              ? null
              : Text(
                  favorites.isEmpty ? "All contacts" : "Favorites",
                  style: STextStyles.smallMed12(context),
                ),
          lowerLabel: favorites.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(
                    top: 20,
                    bottom: 12,
                  ),
                  child: Text(
                    "All contacts",
                    style: STextStyles.smallMed12(context),
                  ),
                ),
          favorites: favorites.isEmpty
              ? contacts.isNotEmpty
                  ? null
                  : RoundedWhiteContainer(
                      child: Center(
                        child: Text(
                          "Your favorite contacts will appear here",
                          style: STextStyles.itemSubtitle(context),
                        ),
                      ),
                    )
              : RoundedWhiteContainer(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      ...favorites.map(
                        (e) => AddressBookCard(
                          key: Key("favContactCard_${e.id}_key"),
                          contactId: e.id,
                        ),
                      ),
                    ],
                  ),
                ),
          all: allContacts.isEmpty
              ? contacts.isNotEmpty
                  ? null
                  : RoundedWhiteContainer(
                      child: Center(
                        child: Text(
                          "Your contacts will appear here",
                          style: STextStyles.itemSubtitle(context),
                        ),
                      ),
                    )
              : Column(
                  children: [
                    RoundedWhiteContainer(
                      padding: const EdgeInsets.all(0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            ...allContacts.map(
                              (e) => AddressBookCard(
                                key: Key("desktopContactCard_${e.id}_key"),
                                contactId: e.id,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
          details: Container(
            color: Colors.purple,
          ),
        ),
      ),
    );
  }
}

class DesktopAddressBookScaffold extends StatelessWidget {
  const DesktopAddressBookScaffold({
    Key? key,
    required this.controlsLeft,
    required this.controlsRight,
    required this.filterItems,
    required this.upperLabel,
    required this.lowerLabel,
    required this.favorites,
    required this.all,
    required this.details,
  }) : super(key: key);

  final Widget? controlsLeft;
  final Widget? controlsRight;
  final Widget? filterItems;
  final Widget? upperLabel;
  final Widget? lowerLabel;
  final Widget? favorites;
  final Widget? all;
  final Widget? details;

  static const double weirdRowHeight = 30;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              flex: 6,
              child: controlsLeft ?? Container(),
            ),
            const SizedBox(
              width: 20,
            ),
            Expanded(
              flex: 5,
              child: controlsRight ?? Container(),
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          children: [
            Expanded(
              child: filterItems ?? Container(),
            ),
          ],
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: weirdRowHeight,
                                child: upperLabel,
                              ),
                              favorites ?? Container(),
                              lowerLabel ?? Container(),
                              all ?? Container(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    const SizedBox(
                      height: weirdRowHeight,
                    ),
                    Expanded(
                      child: details ?? Container(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
