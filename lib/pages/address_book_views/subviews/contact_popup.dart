import 'package:epicmobile/models/send_view_auto_fill_data.dart';
import 'package:epicmobile/pages/address_book_views/subviews/contact_details_view.dart';
import 'package:epicmobile/pages/send_view/send_view.dart';
import 'package:epicmobile/providers/global/address_book_service_provider.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/clipboard_interface.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/rounded_container.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tuple/tuple.dart';

final exchangeFromAddressBookAddressStateProvider =
    StateProvider<String>((ref) => "");

class ContactPopUp extends ConsumerWidget {
  const ContactPopUp({
    Key? key,
    required this.contactId,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  final String contactId;
  final ClipboardInterface clipboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxHeight = MediaQuery.of(context).size.height * 0.6;
    final contact = ref.watch(addressBookServiceProvider
        .select((value) => value.getContactById(contactId)));

    final active = ref
        .read(walletsChangeNotifierProvider)
        .managers
        .where((e) => e.isActiveWallet)
        .toList(growable: false);

    assert(active.isEmpty || active.length == 1);

    bool hasActiveWallet = active.length == 1;

    final addresses = contact.addresses.where((e) {
      if (hasActiveWallet) {
        return e.coin == active[0].coin;
      } else {
        return true;
      }
    }).toList(growable: false);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LimitedBox(
            maxHeight: maxHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Material(
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).extension<StackColors>()!.popupBG,
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: LimitedBox(
                      maxHeight: maxHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            // spacing: 10,
                            children: [
                              const SizedBox(
                                height: 24,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .textFieldDefaultBG,
                                        borderRadius: BorderRadius.circular(32),
                                      ),
                                      child: contact.id == "default"
                                          ? Center(
                                              child: SvgPicture.asset(
                                                Assets.svg.stackIcon(context),
                                                width: 20,
                                              ),
                                            )
                                          : contact.emojiChar != null
                                              ? Center(
                                                  child:
                                                      Text(contact.emojiChar!),
                                                )
                                              : Center(
                                                  child: SvgPicture.asset(
                                                    Assets.svg.user,
                                                    width: 18,
                                                  ),
                                                ),
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Expanded(
                                      child: Text(
                                        contact.name,
                                        style:
                                            STextStyles.itemSubtitle12(context),
                                      ),
                                    ),
                                    if (contact.id != "default")
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.of(context).pushNamed(
                                            ContactDetailsView.routeName,
                                            arguments: contact.id,
                                          );
                                        },
                                        style: Theme.of(context)
                                            .extension<StackColors>()!
                                            .getSecondaryEnabledButtonColor(
                                                context)!
                                            .copyWith(
                                              minimumSize:
                                                  MaterialStateProperty.all<
                                                      Size>(const Size(46, 32)),
                                            ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 18),
                                          child: Text("Details",
                                              style: STextStyles.buttonSmall(
                                                  context)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: contact.id == "default" ? 16 : 8,
                              ),
                              Container(
                                height: 1,
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .background,
                              ),
                              if (addresses.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: RoundedWhiteContainer(
                                    child: Center(
                                      child: Text(
                                        "No ${active[0].coin.prettyName} addresses found",
                                        style:
                                            STextStyles.itemSubtitle(context),
                                      ),
                                    ),
                                  ),
                                ),
                              ...addresses.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(
                                    top: 12,
                                    bottom: 12,
                                    left: 28,
                                    right: 24,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: [
                                          const SizedBox(
                                            height: 2,
                                          ),
                                          SvgPicture.asset(
                                            Assets.svg.iconFor(coin: e.coin),
                                            height: 24,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (contact.id == "default")
                                              Text(
                                                e.other!,
                                                style:
                                                    STextStyles.itemSubtitle12(
                                                        context),
                                              ),
                                            if (contact.id != "default")
                                              Text(
                                                "${e.label} (${e.coin.ticker})",
                                                style:
                                                    STextStyles.itemSubtitle12(
                                                        context),
                                              ),
                                            const SizedBox(
                                              height: 2,
                                            ),
                                            Text(
                                              e.address,
                                              style: STextStyles.itemSubtitle(
                                                      context)
                                                  .copyWith(
                                                fontSize: 8,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Column(
                                        children: [
                                          const SizedBox(
                                            height: 2,
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              clipboard.setData(
                                                ClipboardData(text: e.address),
                                              );
                                              // showFloatingFlushBar(
                                              //   type: FlushBarType.info,
                                              //   message: "Copied to clipboard",
                                              //   iconAsset: Assets.svg.copy,
                                              //   context: context,
                                              // );
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
                                                      .accentColorDark),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (contact.id != "default" &&
                                          hasActiveWallet)
                                        const SizedBox(
                                          width: 4,
                                        ),
                                      if (contact.id != "default" &&
                                          hasActiveWallet)
                                        Column(
                                          children: [
                                            const SizedBox(
                                              height: 2,
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                final String contactLabel =
                                                    "${contact.name} (${e.label})";
                                                final String address =
                                                    e.address;

                                                if (hasActiveWallet) {
                                                  Navigator.of(context)
                                                      .pushNamed(
                                                    SendView.routeName,
                                                    arguments: Tuple3(
                                                      active[0].walletId,
                                                      active[0].coin,
                                                      SendViewAutoFillData(
                                                        address: address,
                                                        contactLabel:
                                                            contactLabel,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: RoundedContainer(
                                                color: Theme.of(context)
                                                    .extension<StackColors>()!
                                                    .textFieldDefaultBG,
                                                padding:
                                                    const EdgeInsets.all(4),
                                                child: SvgPicture.asset(
                                                    Assets
                                                        .svg.circleArrowUpRight,
                                                    width: 12,
                                                    height: 12,
                                                    color: Theme.of(context)
                                                        .extension<
                                                            StackColors>()!
                                                        .accentColorDark),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
