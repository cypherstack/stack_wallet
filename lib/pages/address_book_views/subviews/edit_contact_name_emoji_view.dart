import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/emoji_select_sheet.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

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

    return Scaffold(
      backgroundColor: Theme.of(context).extension<StackColors>()!.background,
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
          style: STextStyles.navBarTitle(context),
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
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_selectedEmoji != null) {
                              setState(() {
                                _selectedEmoji = null;
                              });
                              return;
                            }
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
                          },
                          child: SizedBox(
                            height: 48,
                            width: 48,
                            child: Stack(
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
                                    child: _selectedEmoji == null
                                        ? SvgPicture.asset(
                                            Assets.svg.user,
                                            height: 24,
                                            width: 24,
                                          )
                                        : Text(
                                            _selectedEmoji!.char,
                                            style: STextStyles.pageTitleH1(
                                                context),
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
                        const SizedBox(
                          height: 8,
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Constants.size.circularBorderRadius,
                          ),
                          child: TextField(
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
                              child: TextButton(
                                style: Theme.of(context)
                                    .extension<StackColors>()!
                                    .getSecondaryEnabledButtonColor(context),
                                child: Text(
                                  "Cancel",
                                  style: STextStyles.button(context).copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .accentColorDark),
                                ),
                                onPressed: () async {
                                  if (FocusScope.of(context).hasFocus) {
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
                              child: Builder(
                                builder: (context) {
                                  bool shouldEnableSave =
                                      nameController.text.isNotEmpty;

                                  return TextButton(
                                    style: shouldEnableSave
                                        ? Theme.of(context)
                                            .extension<StackColors>()!
                                            .getPrimaryEnabledButtonColor(
                                                context)
                                        : Theme.of(context)
                                            .extension<StackColors>()!
                                            .getPrimaryDisabledButtonColor(
                                                context),
                                    onPressed: shouldEnableSave
                                        ? () async {
                                            if (FocusScope.of(context)
                                                .hasFocus) {
                                              FocusScope.of(context).unfocus();
                                              await Future<void>.delayed(
                                                const Duration(
                                                    milliseconds: 75),
                                              );
                                            }
                                            final editedContact =
                                                contact.copyWith(
                                              shouldCopyEmojiWithNull: true,
                                              name: nameController.text,
                                              emojiChar: _selectedEmoji == null
                                                  ? null
                                                  : _selectedEmoji!.char,
                                            );
                                            ref
                                                .read(
                                                    addressBookServiceProvider)
                                                .editContact(
                                                  editedContact,
                                                );
                                            if (mounted) {
                                              Navigator.of(context).pop();
                                            }
                                          }
                                        : null,
                                    child: Text(
                                      "Save",
                                      style: STextStyles.button(context),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
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
