import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/models/contact.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/pages/address_book_views/subviews/new_contact_address_entry_form.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/providers/ui/address_book_providers/address_entry_data_provider.dart';
import 'package:stackwallet/providers/ui/address_book_providers/contact_name_is_not_empty_state_provider.dart';
import 'package:stackwallet/providers/ui/address_book_providers/valid_contact_state_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/emoji_select_sheet.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class AddAddressBookEntryView extends ConsumerStatefulWidget {
  const AddAddressBookEntryView({
    Key? key,
    this.barcodeScanner = const BarcodeScannerWrapper(),
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/addAddressBookEntry";

  final BarcodeScannerInterface barcodeScanner;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<AddAddressBookEntryView> createState() =>
      _AddAddressBookEntryViewState();
}

class _AddAddressBookEntryViewState
    extends ConsumerState<AddAddressBookEntryView> {
  late final TextEditingController nameController;
  late final FocusNode nameFocusNode;
  late final ScrollController scrollController;

  late final BarcodeScannerInterface scanner;
  late final ClipboardInterface clipboard;

  Emoji? _selectedEmoji;
  bool _isFavorite = false;

  @override
  initState() {
    ref.refresh(addressEntryDataProviderFamilyRefresher);
    scanner = widget.barcodeScanner;
    clipboard = widget.clipboard;

    nameController = TextEditingController();
    nameFocusNode = FocusNode();
    scrollController = ScrollController();

    _addForm();
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    nameFocusNode.dispose();
    scrollController.dispose();
    super.dispose();
  }

  List<NewContactAddressEntryForm> forms = [];
  int _formCount = 0;

  void _addForm() {
    int id = ++_formCount;
    forms.add(
      NewContactAddressEntryForm(
        key: Key("contactAddressEntryForm_$id"),
        id: ref.read(addressEntryDataProvider(id)).id,
        clipboard: clipboard,
        barcodeScanner: scanner,
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Scaffold(
      backgroundColor: StackTheme.instance.color.background,
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
          "New contact",
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
                key: const Key("addAddressBookEntryFavoriteButtonKey"),
                size: 36,
                shadows: const [],
                color: StackTheme.instance.color.background,
                icon: SvgPicture.asset(
                  Assets.svg.star,
                  color: _isFavorite
                      ? StackTheme.instance.color.accentColorRed
                      : StackTheme.instance.color.buttonBackSecondary,
                  width: 20,
                  height: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraint) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.only(
                // top: 8,
                left: 4,
                right: 4,
                bottom: 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // subtract top and bottom padding set in parent
                  minHeight: constraint.maxHeight - 16, // - 8,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 4,
                      ),
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
                                  color: StackTheme
                                      .instance.color.textFieldActiveBG,
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
                                          style: STextStyles.pageTitleH1,
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
                                    color: CFColors.stackAccent,
                                  ),
                                  child: Center(
                                    child: _selectedEmoji == null
                                        ? SvgPicture.asset(
                                            Assets.svg.plus,
                                            color: CFColors.white,
                                            width: 12,
                                            height: 12,
                                          )
                                        : SvgPicture.asset(
                                            Assets.svg.thickX,
                                            color: CFColors.white,
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
                          style: STextStyles.field,
                          decoration: standardInputDecoration(
                            "Enter contact name",
                            nameFocusNode,
                          ).copyWith(
                            suffixIcon: ref
                                    .read(contactNameIsNotEmptyStateProvider
                                        .state)
                                    .state
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
                          onChanged: (newValue) {
                            ref
                                .read(contactNameIsNotEmptyStateProvider.state)
                                .state = newValue.isNotEmpty;
                          },
                        ),
                      ),
                      if (_formCount <= 1)
                        const SizedBox(
                          height: 8,
                        ),
                      if (_formCount <= 1) forms[0],
                      if (_formCount > 1)
                        for (int i = 0; i < _formCount; i++)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height: 12,
                              ),
                              Text(
                                "Address ${i + 1}",
                                style: STextStyles.smallMed12,
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              forms[i],
                            ],
                          ),
                      const SizedBox(
                        height: 16,
                      ),
                      GestureDetector(
                        onTap: () {
                          _addForm();
                          scrollController.animateTo(
                            scrollController.position.maxScrollExtent + 500,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          "+ Add another address",
                          style: STextStyles.largeMedium14,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              style: StackTheme.instance
                                  .getSecondaryEnabledButtonColor(context),
                              child: Text(
                                "Cancel",
                                style: STextStyles.button.copyWith(
                                  color: CFColors.stackAccent,
                                ),
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
                                bool nameExists = ref
                                    .watch(contactNameIsNotEmptyStateProvider
                                        .state)
                                    .state;

                                bool validForms = ref.watch(
                                    validContactStateProvider(forms
                                        .map((e) => e.id)
                                        .toList(growable: false)));

                                bool shouldEnableSave =
                                    validForms && nameExists;

                                return TextButton(
                                  style: shouldEnableSave
                                      ? StackTheme.instance
                                          .getPrimaryEnabledButtonColor(context)
                                      : StackTheme.instance
                                          .getPrimaryDisabledButtonColor(
                                              context),
                                  onPressed: shouldEnableSave
                                      ? () async {
                                          if (FocusScope.of(context).hasFocus) {
                                            FocusScope.of(context).unfocus();
                                            await Future<void>.delayed(
                                              const Duration(milliseconds: 75),
                                            );
                                          }
                                          List<ContactAddressEntry> entries =
                                              [];
                                          for (int i = 0; i < _formCount; i++) {
                                            entries.add(ref
                                                .read(addressEntryDataProvider(
                                                    i + 1))
                                                .buildAddressEntry());
                                          }
                                          Contact contact = Contact(
                                            emojiChar: _selectedEmoji?.char,
                                            name: nameController.text,
                                            addresses: entries,
                                            isFavorite: _isFavorite,
                                          );

                                          if (await ref
                                              .read(addressBookServiceProvider)
                                              .addContact(contact)) {
                                            if (mounted) {
                                              Navigator.of(context).pop();
                                            }
                                            // TODO show success notification
                                          } else {
                                            // TODO show error notification
                                          }
                                        }
                                      : null,
                                  child: Text(
                                    "Save",
                                    style: STextStyles.button,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
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
