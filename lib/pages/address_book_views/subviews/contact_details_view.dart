import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/address_book_views/subviews/add_new_contact_address_view.dart';
import 'package:stackwallet/pages/address_book_views/subviews/edit_contact_address_view.dart';
import 'package:stackwallet/pages/address_book_views/subviews/edit_contact_name_emoji_view.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/ui/address_book_providers/address_entry_data_provider.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/transaction_card.dart';
import 'package:tuple/tuple.dart';

class ContactDetailsView extends ConsumerStatefulWidget {
  const ContactDetailsView({
    Key? key,
    required this.contactId,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/contactDetails";

  final String contactId;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<ContactDetailsView> createState() => _ContactDetailsViewState();
}

class _ContactDetailsViewState extends ConsumerState<ContactDetailsView> {
  late String _contactId;
  late final ClipboardInterface clipboard;

  List<Tuple2<String, Transaction>> _cachedTransactions = [];

  Future<List<Tuple2<String, Transaction>>> _filteredTransactionsByContact(
    List<Manager> managers,
  ) async {
    final contact =
        ref.read(addressBookServiceProvider).getContactById(_contactId);

    // TODO: optimise

    List<Tuple2<String, Transaction>> result = [];
    for (final manager in managers) {
      final transactions = await MainDB.instance
          .getTransactions(manager.walletId)
          .filter()
          .anyOf(contact.addresses.map((e) => e.address),
              (q, String e) => q.address((q) => q.valueEqualTo(e)))
          .sortByTimestampDesc()
          .findAll();

      for (final tx in transactions) {
        result.add(Tuple2(manager.walletId, tx));
      }
    }

    return result;
  }

  @override
  void initState() {
    ref.refresh(addressEntryDataProviderFamilyRefresher);
    _contactId = widget.contactId;
    clipboard = widget.clipboard;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final _contact = ref.watch(addressBookServiceProvider
        .select((value) => value.getContactById(_contactId)));

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
            "Contact details",
            style: STextStyles.navBarTitle(context),
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
                  key: const Key("contactDetails"),
                  size: 36,
                  shadows: const [],
                  color: Theme.of(context).extension<StackColors>()!.background,
                  icon: SvgPicture.asset(
                    Assets.svg.star,
                    color: _contact.isFavorite
                        ? Theme.of(context)
                            .extension<StackColors>()!
                            .favoriteStarActive
                        : Theme.of(context)
                            .extension<StackColors>()!
                            .favoriteStarInactive,
                    width: 20,
                    height: 20,
                  ),
                  onPressed: () {
                    bool isFavorite = _contact.isFavorite;

                    ref.read(addressBookServiceProvider).editContact(
                        _contact.copyWith(isFavorite: !isFavorite));
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
                  key: const Key("contactDetailsViewDeleteContactButtonKey"),
                  size: 36,
                  shadows: const [],
                  color: Theme.of(context).extension<StackColors>()!.background,
                  icon: SvgPicture.asset(
                    Assets.svg.trash,
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorDark,
                    width: 20,
                    height: 20,
                  ),
                  onPressed: () {
                    showDialog<dynamic>(
                      context: context,
                      useSafeArea: true,
                      barrierDismissible: true,
                      builder: (_) => StackDialog(
                        title: "Delete ${_contact.name}?",
                        message: "Contact will be deleted permanently!",
                        leftButton: TextButton(
                          style: Theme.of(context)
                              .extension<StackColors>()!
                              .getSecondaryEnabledButtonStyle(context),
                          child: Text(
                            "Cancel",
                            style: STextStyles.itemSubtitle12(context),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        rightButton: TextButton(
                          style: Theme.of(context)
                              .extension<StackColors>()!
                              .getPrimaryEnabledButtonStyle(context),
                          child: Text(
                            "Delete",
                            style: STextStyles.button(context),
                          ),
                          onPressed: () {
                            ref
                                .read(addressBookServiceProvider)
                                .removeContact(_contact.id);
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            showFloatingFlushBar(
                              type: FlushBarType.success,
                              message: "${_contact.name} deleted",
                              context: context,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 12,
                  ),
                  Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textFieldActiveBG,
                        ),
                        child: Center(
                          child: _contact.emojiChar == null
                              ? SvgPicture.asset(
                                  Assets.svg.user,
                                  height: 24,
                                  width: 24,
                                )
                              : Text(
                                  _contact.emojiChar!,
                                  style: STextStyles.pageTitleH1(context),
                                ),
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _contact.name,
                          textAlign: TextAlign.left,
                          style: STextStyles.pageTitleH2(context),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            EditContactNameEmojiView.routeName,
                            arguments: _contact.id,
                          );
                        },
                        style: Theme.of(context)
                            .extension<StackColors>()!
                            .getSecondaryEnabledButtonStyle(context)!
                            .copyWith(
                              minimumSize: MaterialStateProperty.all<Size>(
                                  const Size(46, 32)),
                            ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              SvgPicture.asset(Assets.svg.pencil,
                                  width: 10,
                                  height: 10,
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .accentColorDark),
                              const SizedBox(
                                width: 4,
                              ),
                              Text(
                                "Edit",
                                style: STextStyles.buttonSmall(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Addresses",
                        style: STextStyles.itemSubtitle(context),
                      ),
                      CustomTextButton(
                        text: "Add new",
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AddNewContactAddressView.routeName,
                            arguments: _contact.id,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  RoundedWhiteContainer(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      children: [
                        ..._contact.addresses.map(
                          (e) => Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  ref.watch(coinIconProvider(e.coin)),
                                  height: 24,
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${e.label} (${e.coin.ticker})",
                                        style:
                                            STextStyles.itemSubtitle12(context),
                                      ),
                                      const SizedBox(
                                        height: 2,
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          e.address,
                                          style:
                                              STextStyles.itemSubtitle(context)
                                                  .copyWith(
                                            fontSize: 8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(addressEntryDataProvider(0))
                                        .address = e.address;
                                    ref
                                        .read(addressEntryDataProvider(0))
                                        .addressLabel = e.label;
                                    ref.read(addressEntryDataProvider(0)).coin =
                                        e.coin;

                                    Navigator.of(context).pushNamed(
                                      EditContactAddressView.routeName,
                                      arguments: Tuple2(_contact.id, e),
                                    );
                                  },
                                  child: RoundedContainer(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textFieldDefaultBG,
                                    padding: const EdgeInsets.all(6),
                                    child: SvgPicture.asset(
                                      Assets.svg.pencil,
                                      width: 14,
                                      height: 14,
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .accentColorDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 4,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    clipboard.setData(
                                      ClipboardData(text: e.address),
                                    );
                                    showFloatingFlushBar(
                                      type: FlushBarType.info,
                                      message: "Copied to clipboard",
                                      iconAsset: Assets.svg.copy,
                                      context: context,
                                    );
                                  },
                                  child: RoundedContainer(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textFieldDefaultBG,
                                    padding: const EdgeInsets.all(6),
                                    child: SvgPicture.asset(
                                      Assets.svg.copy,
                                      width: 16,
                                      height: 16,
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .accentColorDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Text(
                    "Transaction history",
                    style: STextStyles.itemSubtitle(context),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  FutureBuilder(
                    future: _filteredTransactionsByContact(
                        ref.watch(walletsChangeNotifierProvider).managers),
                    builder: (_,
                        AsyncSnapshot<List<Tuple2<String, Transaction>>>
                            snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        _cachedTransactions = snapshot.data!;

                        if (_cachedTransactions.isNotEmpty) {
                          return RoundedWhiteContainer(
                            padding: const EdgeInsets.all(0),
                            child: Column(
                              children: [
                                ..._cachedTransactions.map(
                                  (e) => TransactionCard(
                                    key: Key(
                                        "contactDetailsTransaction_${e.item1}_${e.item2.txid}_cardKey"),
                                    transaction: e.item2,
                                    walletId: e.item1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return RoundedWhiteContainer(
                            child: Center(
                              child: Text(
                                "No transactions found",
                                style: STextStyles.itemSubtitle(context),
                              ),
                            ),
                          );
                        }
                      } else {
                        // TODO: proper loading animation
                        if (_cachedTransactions.isEmpty) {
                          return const LoadingIndicator();
                        } else {
                          return RoundedWhiteContainer(
                            padding: const EdgeInsets.all(0),
                            child: Column(
                              children: [
                                ..._cachedTransactions.map(
                                  (e) => TransactionCard(
                                    key: Key(
                                        "contactDetailsTransaction_${e.item1}_${e.item2.txid}_cardKey"),
                                    transaction: e.item2,
                                    walletId: e.item1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
