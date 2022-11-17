import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

class DesktopContactDetails extends ConsumerStatefulWidget {
  const DesktopContactDetails({
    Key? key,
    required this.contactId,
  }) : super(key: key);

  final String contactId;

  @override
  ConsumerState<DesktopContactDetails> createState() =>
      _DesktopContactDetailsState();
}

class _DesktopContactDetailsState extends ConsumerState<DesktopContactDetails> {
  @override
  Widget build(BuildContext context) {
    final contact = ref.watch(addressBookServiceProvider
        .select((value) => value.getContactById(widget.contactId)));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
                              child: Text(contact.emojiChar!),
                            )
                          : Center(
                              child: SvgPicture.asset(
                                Assets.svg.user,
                                width: 18,
                              ),
                            ),
                ),
                const SizedBox(
                  width: 16,
                ),
                Text(
                  contact.name,
                  style: STextStyles.desktopTextSmall(context),
                ),
              ],
            ),
            SecondaryButton(
              label: "Options",
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(
          height: 24,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Addresses",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                  context),
                            ),
                            BlueTextButton(
                              text: "Add new",
                              onTap: () {},
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...contact.addresses
                                .map((e) => AddressCard(entry: e)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class AddressCard extends StatelessWidget {
  const AddressCard({
    Key? key,
    required this.entry,
  }) : super(key: key);

  final ContactAddressEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          Assets.svg.iconFor(
            coin: entry.coin,
          ),
          height: 32,
          width: 32,
        ),
        const SizedBox(
          width: 16,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              "${entry.label} ${entry.coin.ticker}",
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
                BlueTextButton(
                  text: "Copy",
                  onTap: () {},
                ),
                const SizedBox(
                  width: 16,
                ),
                BlueTextButton(
                  text: "Edit",
                  onTap: () {},
                ),
              ],
            )
          ],
        ),
      ],
    );
  }
}
