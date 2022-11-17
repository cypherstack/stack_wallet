import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages_desktop_specific/home/address_book_view/subwidgets/desktop_address_card.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

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
              width: 86,
              buttonHeight: ButtonHeight.xxs,
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
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedWhiteContainer(
                          padding: const EdgeInsets.all(0),
                          borderColor: Theme.of(context)
                              .extension<StackColors>()!
                              .background,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 0; i < contact.addresses.length; i++)
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (i > 0)
                                      Container(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .background,
                                        height: 1,
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: DesktopAddressCard(
                                        entry: contact.addresses[i],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
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
