import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/address_book_views/subviews/edit_contact_address_view.dart';
import 'package:stackwallet/providers/ui/address_book_providers/address_entry_data_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';

class DesktopAddressCard extends ConsumerWidget {
  const DesktopAddressCard({
    Key? key,
    required this.entry,
    required this.contactId,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  final ContactAddressEntry entry;
  final String contactId;
  final ClipboardInterface clipboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          ref.watch(coinIconProvider(entry.coin)),
          height: 32,
          width: 32,
        ),
        const SizedBox(
          width: 16,
        ),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                "${contactId == "default" ? entry.other! : entry.label} (${entry.coin.ticker})",
                style: STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                  color: Theme.of(context).extension<StackColors>()!.textDark,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              SelectableText(
                entry.address,
                style: STextStyles.desktopTextExtraExtraSmall(context),
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  CustomTextButton(
                    text: "Copy",
                    onTap: () {
                      clipboard.setData(
                        ClipboardData(text: entry.address),
                      );
                      showFloatingFlushBar(
                        type: FlushBarType.info,
                        message: "Copied to clipboard",
                        iconAsset: Assets.svg.copy,
                        context: context,
                      );
                    },
                  ),
                  if (contactId != "default")
                    const SizedBox(
                      width: 16,
                    ),
                  if (contactId != "default")
                    Consumer(
                      builder: (context, ref, child) {
                        return CustomTextButton(
                          text: "Edit",
                          onTap: () async {
                            ref.refresh(
                                addressEntryDataProviderFamilyRefresher);
                            ref.read(addressEntryDataProvider(0)).address =
                                entry.address;
                            ref.read(addressEntryDataProvider(0)).addressLabel =
                                entry.label;
                            ref.read(addressEntryDataProvider(0)).coin =
                                entry.coin;

                            await showDialog<void>(
                              context: context,
                              builder: (context) => DesktopDialog(
                                maxWidth: 580,
                                maxHeight: 566,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 8,
                                        ),
                                        const AppBarBackButton(
                                          isCompact: true,
                                        ),
                                        Text(
                                          "Edit address",
                                          style: STextStyles.desktopH3(context),
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 20,
                                          left: 32,
                                          right: 32,
                                          bottom: 32,
                                        ),
                                        child: EditContactAddressView(
                                          contactId: contactId,
                                          addressEntry: entry,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}
