import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/address_book_views/subviews/edit_contact_name_emoji_view.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';

class DesktopContactOptionsMenuPopup extends ConsumerStatefulWidget {
  const DesktopContactOptionsMenuPopup({Key? key, required this.contactId})
      : super(key: key);

  final String contactId;

  @override
  ConsumerState<DesktopContactOptionsMenuPopup> createState() =>
      _DesktopContactOptionsMenuPopupState();
}

class _DesktopContactOptionsMenuPopupState
    extends ConsumerState<DesktopContactOptionsMenuPopup> {
  bool hoveredOnStar = false;
  bool hoveredOnPencil = false;
  bool hoveredOnTrash = false;

  void editContact() {
    // pop context menu
    Navigator.of(context).pop();

    showDialog<dynamic>(
      context: context,
      useSafeArea: true,
      barrierDismissible: true,
      builder: (_) => DesktopDialog(
        maxWidth: 580,
        maxHeight: 400,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 32,
                  ),
                  child: Text(
                    "Edit contact",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                  left: 32,
                  right: 32,
                  bottom: 32,
                ),
                child: EditContactNameEmojiView(
                  contactId: widget.contactId,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void attemptDeleteContact() {
    final contact =
        ref.read(addressBookServiceProvider).getContactById(widget.contactId);

    // pop context menu
    Navigator.of(context).pop();

    showDialog<dynamic>(
      context: context,
      useSafeArea: true,
      barrierDismissible: true,
      builder: (_) => DesktopDialog(
        maxWidth: 500,
        maxHeight: 400,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 32,
                  ),
                  child: Text(
                    "Delete ${contact.name}?",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                  right: 32,
                  bottom: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(
                      flex: 1,
                    ),
                    Text(
                      "Contact will be deleted permanently!",
                      style: STextStyles.desktopTextSmall(context),
                    ),
                    const Spacer(
                      flex: 2,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: "Cancel",
                            onPressed: Navigator.of(context).pop,
                            buttonHeight: ButtonHeight.l,
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, __) => PrimaryButton(
                              label: "Delete",
                              buttonHeight: ButtonHeight.l,
                              onPressed: () {
                                ref
                                    .read(addressBookServiceProvider)
                                    .removeContact(contact.customId);
                                Navigator.of(context).pop();
                                showFloatingFlushBar(
                                  type: FlushBarType.success,
                                  message: "${contact.name} deleted",
                                  context: context,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 210,
          left: MediaQuery.of(context).size.width - 280,
          child: Container(
            width: 270,
            decoration: BoxDecoration(
              color: Theme.of(context).extension<StackColors>()!.popupBG,
              borderRadius: BorderRadius.circular(
                20,
              ),
              boxShadow: [
                Theme.of(context).extension<StackColors>()!.standardBoxShadow,
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        hoveredOnStar = true;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        hoveredOnStar = false;
                      });
                    },
                    child: RawMaterialButton(
                      hoverColor: Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldDefaultBG,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          1000,
                        ),
                      ),
                      onPressed: () {
                        final contact =
                            ref.read(addressBookServiceProvider).getContactById(
                                  widget.contactId,
                                );
                        ref.read(addressBookServiceProvider).editContact(
                              contact.copyWith(
                                isFavorite: !contact.isFavorite,
                              ),
                            );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              Assets.svg.star,
                              width: 24,
                              height: 22,
                              color: hoveredOnStar
                                  ? Theme.of(context)
                                      .extension<StackColors>()!
                                      .textDark
                                  : Theme.of(context)
                                      .extension<StackColors>()!
                                      .textFieldDefaultSearchIconLeft,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Text(
                              ref.watch(addressBookServiceProvider.select(
                                      (value) => value
                                          .getContactById(widget.contactId)
                                          .isFavorite))
                                  ? "Remove from favorites"
                                  : "Add to favorites",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                      context)
                                  .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (widget.contactId != "default")
                    const SizedBox(
                      height: 2,
                    ),
                  if (widget.contactId != "default")
                    MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          hoveredOnPencil = true;
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          hoveredOnPencil = false;
                        });
                      },
                      child: RawMaterialButton(
                        hoverColor: Theme.of(context)
                            .extension<StackColors>()!
                            .textFieldDefaultBG,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            1000,
                          ),
                        ),
                        onPressed: editContact,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                Assets.svg.pencil,
                                width: 24,
                                height: 22,
                                color: hoveredOnPencil
                                    ? Theme.of(context)
                                        .extension<StackColors>()!
                                        .textDark
                                    : Theme.of(context)
                                        .extension<StackColors>()!
                                        .textFieldDefaultSearchIconLeft,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Text(
                                "Edit contact",
                                style: STextStyles.desktopTextExtraExtraSmall(
                                        context)
                                    .copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textDark,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (widget.contactId != "default")
                    const SizedBox(
                      height: 2,
                    ),
                  if (widget.contactId != "default")
                    MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          hoveredOnTrash = true;
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          hoveredOnTrash = false;
                        });
                      },
                      child: RawMaterialButton(
                        hoverColor: Theme.of(context)
                            .extension<StackColors>()!
                            .textFieldDefaultBG,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            1000,
                          ),
                        ),
                        onPressed: attemptDeleteContact,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                Assets.svg.trash,
                                width: 24,
                                height: 22,
                                color: hoveredOnTrash
                                    ? Theme.of(context)
                                        .extension<StackColors>()!
                                        .textDark
                                    : Theme.of(context)
                                        .extension<StackColors>()!
                                        .textFieldDefaultSearchIconLeft,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Text(
                                "Delete contact",
                                style: STextStyles.desktopTextExtraExtraSmall(
                                        context)
                                    .copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textDark,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
