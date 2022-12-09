import 'dart:async';

import 'package:epicmobile/providers/global/address_book_service_provider.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/clipboard_interface.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/rounded_container.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
import 'package:epicmobile/widgets/textfield_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class ContactPopUp extends ConsumerWidget {
  const ContactPopUp({
    Key? key,
    required this.contactId,
    this.onSendPressed,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  final String contactId;
  final ClipboardInterface clipboard;
  final void Function(String, String)? onSendPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contact = ref.watch(addressBookServiceProvider
        .select((value) => value.getContactById(contactId)));

    if (contact == null) {
      return RoundedWhiteContainer(
        child: Text(
          "Contact does not exist!",
          style: STextStyles.titleH4(context),
        ),
      );
    }

    final active = ref.read(walletProvider);

    bool hasActiveWallet = active != null;

    final addresses = contact.addresses.where((e) {
      if (hasActiveWallet) {
        return e.coin == active.coin;
      } else {
        return true;
      }
    }).toList(growable: false);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [
            AppBarBackButton(
              padding: EdgeInsets.only(
                left: 8,
                top: 8,
              ),
            ),
          ],
        ),
        Text(
          contact.name,
          style: STextStyles.titleH4(context),
        ),
        const SizedBox(
          height: 16,
        ),
        if (addresses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RoundedWhiteContainer(
              child: Center(
                child: Text(
                  "No ${active!.coin.prettyName} addresses found",
                  style: STextStyles.itemSubtitle(context),
                ),
              ),
            ),
          ),
        // ...addresses.map(
        //   (e) =>
        Padding(
          padding: const EdgeInsets.only(
            bottom: 8,
            left: 16,
            right: 16,
          ),
          child: RoundedContainer(
            color: Theme.of(context).extension<StackColors>()!.coal,
            child: Column(
              children: [
                SelectableText(
                  contact.addresses.first.address,
                  style: STextStyles.body(context),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CopyButton(
                      onTap: () async {
                        await clipboard.setData(
                          ClipboardData(
                            text: contact.addresses.first.address,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop("delete_contact");
                },
                child: Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "DELETE",
                      style: STextStyles.buttonText(context),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final String contactLabel = contact.name;
                  final String address = contact.addresses.first.address;

                  if (hasActiveWallet) {
                    onSendPressed?.call(contactLabel, address);
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "SEND EPIC",
                      style: STextStyles.buttonText(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textGold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

class CopyButton extends StatefulWidget {
  const CopyButton({Key? key, this.onTap}) : super(key: key);

  final VoidCallback? onTap;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  String assetName = Assets.svg.copy;

  void onCopy() {
    setState(() {
      assetName = Assets.svg.check;
    });
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          assetName = Assets.svg.copy;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFieldIconButton(
      key: const Key("contactPopupCopyButtonKey"),
      onTap: () async {
        widget.onTap?.call();
        onCopy();
      },
      child: SvgPicture.asset(
        assetName,
        width: 24,
        height: 24,
        color: Theme.of(context).extension<StackColors>()!.textDark,
      ),
    );
  }
}
