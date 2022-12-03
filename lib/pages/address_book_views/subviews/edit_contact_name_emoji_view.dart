import 'dart:async';

import 'package:emojis/emoji.dart';
import 'package:epicmobile/providers/global/address_book_service_provider.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/conditional_parent.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/desktop/desktop_dialog.dart';
import 'package:epicmobile/widgets/desktop/primary_button.dart';
import 'package:epicmobile/widgets/desktop/secondary_button.dart';
import 'package:epicmobile/widgets/emoji_select_sheet.dart';
import 'package:epicmobile/widgets/icon_widgets/x_icon.dart';
import 'package:epicmobile/widgets/stack_text_field.dart';
import 'package:epicmobile/widgets/textfield_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class EditContactNameEmojiView extends ConsumerStatefulWidget {
  const EditContactNameEmojiView({
    Key? key,
    required this.contactId,
  }) : super(key: key);

  static const String routeName = "/editContactNameEmoji";

  final String contactId;

  @override
  ConsumerState<EditContactNameEmojiView> createState() =>
      _EditContactNameEmojiViewState();
}

class _EditContactNameEmojiViewState
    extends ConsumerState<EditContactNameEmojiView> {
  late final TextEditingController nameController;
  late final FocusNode nameFocusNode;

  late final String contactId;

  Emoji? _selectedEmoji;

  @override
  void initState() {
    contactId = widget.contactId;
    nameController = TextEditingController();
    nameFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final contact =
          ref.read(addressBookServiceProvider).getContactById(contactId);

      nameController.text = contact.name;
      setState(() {
        _selectedEmoji = Emoji.byChar(contact.emojiChar ?? "");
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contact = ref.watch(addressBookServiceProvider
        .select((value) => value.getContactById(contactId)));

    final isDesktop = Util.isDesktop;
    final double emojiSize = isDesktop ? 56 : 48;

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) => Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () async {
                if (FocusScope.of(context).hasFocus) {
                  FocusScope.of(context).unfocus();
                  await Future<void>.delayed(const Duration(milliseconds: 75));
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Text(
              "Edit contact",
              style: STextStyles.titleH4(context),
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
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
                        child: child,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (_selectedEmoji != null) {
                    setState(() {
                      _selectedEmoji = null;
                    });
                    return;
                  }
                  if (isDesktop) {
                    showDialog<dynamic>(
                        barrierColor: Colors.transparent,
                        context: context,
                        builder: (context) {
                          return const DesktopDialog(
                            maxHeight: 700,
                            maxWidth: 600,
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: 32,
                                right: 20,
                                top: 32,
                                bottom: 32,
                              ),
                              child: EmojiSelectSheet(),
                            ),
                          );
                        }).then((value) {
                      if (value is Emoji) {
                        setState(() {
                          _selectedEmoji = value;
                        });
                      }
                    });
                  } else {
                    showModalBottomSheet<dynamic>(
                      backgroundColor: Colors.transparent,
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (_) => const EmojiSelectSheet(),
                    ).then((value) {
                      if (value is Emoji) {
                        setState(() {
                          _selectedEmoji = value;
                        });
                      }
                    });
                  }
                },
                child: SizedBox(
                  height: emojiSize,
                  width: emojiSize,
                  child: Stack(
                    children: [
                      Container(
                        height: emojiSize,
                        width: emojiSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(emojiSize / 2),
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textFieldActiveBG,
                        ),
                        child: Center(
                          child: _selectedEmoji == null
                              ? SvgPicture.asset(
                                  Assets.svg.user,
                                  height: emojiSize / 2,
                                  width: emojiSize / 2,
                                )
                              : Text(
                                  _selectedEmoji!.char,
                                  style: isDesktop
                                      ? STextStyles.desktopH3(context)
                                      : STextStyles.pageTitleH1(context),
                                ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          height: 14,
                          width: 14,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .accentColorDark),
                          child: Center(
                            child: _selectedEmoji == null
                                ? SvgPicture.asset(
                                    Assets.svg.plus,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textWhite,
                                    width: 12,
                                    height: 12,
                                  )
                                : SvgPicture.asset(
                                    Assets.svg.thickX,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textWhite,
                                    width: 8,
                                    height: 8,
                                  ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              if (isDesktop)
                const SizedBox(
                  width: 8,
                ),
              if (isDesktop)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                    child: TextField(
                      autocorrect: Util.isDesktop ? false : true,
                      enableSuggestions: Util.isDesktop ? false : true,
                      controller: nameController,
                      focusNode: nameFocusNode,
                      style: STextStyles.field(context),
                      onChanged: (_) => setState(() {}),
                      decoration: standardInputDecoration(
                        "Enter contact name",
                        nameFocusNode,
                        context,
                      ).copyWith(
                        suffixIcon: nameController.text.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(right: 0),
                                child: UnconstrainedBox(
                                  child: Row(
                                    children: [
                                      TextFieldIconButton(
                                        child: const XIcon(),
                                        onTap: () async {
                                          setState(() {
                                            nameController.text = "";
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
                ),
            ],
          ),
          if (!isDesktop)
            const SizedBox(
              height: 8,
            ),
          if (!isDesktop)
            ClipRRect(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
              child: TextField(
                autocorrect: Util.isDesktop ? false : true,
                enableSuggestions: Util.isDesktop ? false : true,
                controller: nameController,
                focusNode: nameFocusNode,
                style: STextStyles.field(context),
                onChanged: (_) => setState(() {}),
                decoration: standardInputDecoration(
                  "Enter contact name",
                  nameFocusNode,
                  context,
                ).copyWith(
                  suffixIcon: nameController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 0),
                          child: UnconstrainedBox(
                            child: Row(
                              children: [
                                TextFieldIconButton(
                                  child: const XIcon(),
                                  onTap: () async {
                                    setState(() {
                                      nameController.text = "";
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
          const Spacer(),
          const SizedBox(
            height: 16,
          ),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: "Cancel",
                  onPressed: () async {
                    if (!isDesktop && FocusScope.of(context).hasFocus) {
                      FocusScope.of(context).unfocus();
                      await Future<void>.delayed(
                          const Duration(milliseconds: 75));
                    }
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: PrimaryButton(
                  label: "Save",
                  enabled: nameController.text.isNotEmpty,
                  onPressed: () async {
                    if (!isDesktop && FocusScope.of(context).hasFocus) {
                      FocusScope.of(context).unfocus();
                      await Future<void>.delayed(
                        const Duration(milliseconds: 75),
                      );
                    }
                    final editedContact = contact.copyWith(
                      shouldCopyEmojiWithNull: true,
                      name: nameController.text,
                      emojiChar:
                          _selectedEmoji == null ? null : _selectedEmoji!.char,
                    );
                    unawaited(
                      ref.read(addressBookServiceProvider).editContact(
                            editedContact,
                          ),
                    );
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
