import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/contact.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/pages/address_book_views/subviews/add_address_book_entry_view.dart';
import 'package:stackwallet/pages/address_book_views/subviews/address_book_filter_view.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/ui/address_book_providers/address_book_filter_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/address_book_card.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class AddressBookView extends ConsumerStatefulWidget {
  const AddressBookView({Key? key, this.coin}) : super(key: key);

  static const String routeName = "/addressBook";

  final Coin? coin;

  @override
  ConsumerState<AddressBookView> createState() => _AddressBookViewState();
}

class _AddressBookViewState extends ConsumerState<AddressBookView> {
  late TextEditingController _searchController;

  final _searchFocusNode = FocusNode();

  List<Contact>? _cache;
  List<Contact>? _cacheFav;

  String _searchTerm = "";

  @override
  void initState() {
    _searchController = TextEditingController();
    ref.refresh(addressBookFilterProvider);

    if (widget.coin == null) {
      List<Coin> coins =
          Coin.values.where((e) => !(e == Coin.epicCash)).toList();
      coins.remove(Coin.firoTestNet);

      bool showTestNet = ref.read(prefsChangeNotifierProvider).showTestNetCoins;

      if (showTestNet) {
        ref.read(addressBookFilterProvider).addAll(coins, false);
      } else {
        ref.read(addressBookFilterProvider).addAll(
            coins.getRange(0, coins.length - kTestNetCoinCount + 1), false);
      }
    } else {
      ref.read(addressBookFilterProvider).add(widget.coin!, false);
    }

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
    final addressBookEntriesFuture = ref.watch(
        addressBookServiceProvider.select((value) => value.addressBookEntries));

    return Scaffold(
      backgroundColor: CFColors.almostWhite,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Address book",
          style: STextStyles.navBarTitle,
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
                key: const Key("addressBookFilterViewButton"),
                size: 36,
                shadows: const [],
                color: CFColors.almostWhite,
                icon: SvgPicture.asset(
                  Assets.svg.filter,
                  color: CFColors.stackAccent,
                  width: 20,
                  height: 20,
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AddressBookFilterView.routeName,
                  );
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
                color: CFColors.almostWhite,
                icon: SvgPicture.asset(
                  Assets.svg.plus,
                  color: CFColors.stackAccent,
                  width: 20,
                  height: 20,
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AddAddressBookEntryView.routeName,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (builderContext, constraints) {
          return Padding(
            padding: const EdgeInsets.only(
              left: 12,
              top: 12,
              right: 12,
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
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
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (value) {
                              setState(() {
                                _searchTerm = value;
                              });
                            },
                            style: STextStyles.field,
                            decoration: standardInputDecoration(
                              "Search",
                              _searchFocusNode,
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
                                      padding: const EdgeInsets.only(right: 0),
                                      child: UnconstrainedBox(
                                        child: Row(
                                          children: [
                                            TextFieldIconButton(
                                              child: const XIcon(),
                                              onTap: () async {
                                                setState(() {
                                                  _searchController.text = "";
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
                          style: STextStyles.smallMed12,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        FutureBuilder(
                          future: addressBookEntriesFuture,
                          builder: (_, AsyncSnapshot<List<Contact>> snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData) {
                              _cacheFav = snapshot.data!;
                            }
                            if (_cacheFav == null) {
                              // TODO proper loading animation
                              return const LoadingIndicator();
                            } else {
                              if (_cacheFav!.isNotEmpty) {
                                return RoundedWhiteContainer(
                                  padding: const EdgeInsets.all(0),
                                  child: Column(
                                    children: [
                                      ..._cacheFav!
                                          .where((element) => element.addresses
                                              .where((e) => ref.watch(
                                                  addressBookFilterProvider
                                                      .select((value) => value
                                                          .coins
                                                          .contains(e.coin))))
                                              .isNotEmpty)
                                          .where((e) =>
                                              e.isFavorite &&
                                              ref
                                                  .read(
                                                      addressBookServiceProvider)
                                                  .matches(_searchTerm, e))
                                          .where(
                                              (element) => element.isFavorite)
                                          .map(
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
                                      style: STextStyles.itemSubtitle,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Text(
                          "All contacts",
                          style: STextStyles.smallMed12,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        FutureBuilder(
                          future: addressBookEntriesFuture,
                          builder: (_, AsyncSnapshot<List<Contact>> snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData) {
                              _cache = snapshot.data!;
                            }
                            if (_cache == null) {
                              // TODO proper loading animation
                              return const LoadingIndicator();
                            } else {
                              if (_cache!.isNotEmpty) {
                                return RoundedWhiteContainer(
                                  padding: const EdgeInsets.all(0),
                                  child: Column(
                                    children: [
                                      ..._cache!
                                          .where((element) => element.addresses
                                              .where((e) => ref.watch(
                                                  addressBookFilterProvider
                                                      .select((value) => value
                                                          .coins
                                                          .contains(e.coin))))
                                              .isNotEmpty)
                                          .where((e) => ref
                                              .read(addressBookServiceProvider)
                                              .matches(_searchTerm, e))
                                          .where(
                                              (element) => !element.isFavorite)
                                          .map(
                                            (e) => AddressBookCard(
                                              key: Key(
                                                  "contactCard_${e.id}_key"),
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
                                      style: STextStyles.itemSubtitle,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
