import 'package:epicmobile/models/contact.dart';
import 'package:epicmobile/models/contact_address_entry.dart';
import 'package:epicmobile/pages/address_book_views/subviews/new_contact_address_entry_form.dart';
import 'package:epicmobile/providers/global/address_book_service_provider.dart';
import 'package:epicmobile/providers/ui/address_book_providers/address_entry_data_provider.dart';
import 'package:epicmobile/providers/ui/address_book_providers/contact_name_is_not_empty_state_provider.dart';
import 'package:epicmobile/providers/ui/address_book_providers/valid_contact_state_provider.dart';
import 'package:epicmobile/utilities/barcode_scanner_interface.dart';
import 'package:epicmobile/utilities/clipboard_interface.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/desktop/primary_button.dart';
import 'package:epicmobile/widgets/desktop/secondary_button.dart';
import 'package:epicmobile/widgets/icon_widgets/x_icon.dart';
import 'package:epicmobile/widgets/textfield_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  initState() {
    ref.refresh(addressEntryDataProviderFamilyRefresher);
    scanner = widget.barcodeScanner;
    clipboard = widget.clipboard;

    nameController = TextEditingController();
    nameFocusNode = FocusNode();
    scrollController = ScrollController();

    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    nameFocusNode.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Background(
      child: Scaffold(
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
          centerTitle: true,
          title: Text(
            "New Address",
            style: STextStyles.titleH4(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraint) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraint.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          NewContactAddressEntryForm(
                            key: const Key("contactAddressEntryForm_0"),
                            id: ref.read(addressEntryDataProvider(0)).id,
                            clipboard: clipboard,
                            barcodeScanner: scanner,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          TextField(
                            autocorrect: false,
                            enableSuggestions: false,
                            controller: nameController,
                            focusNode: nameFocusNode,
                            textAlignVertical: TextAlignVertical.center,
                            style: STextStyles.body(context),
                            onChanged: (newValue) {
                              ref
                                  .read(
                                      contactNameIsNotEmptyStateProvider.state)
                                  .state = newValue.isNotEmpty;
                            },
                            decoration: InputDecoration(
                              fillColor: nameFocusNode.hasFocus
                                  ? Theme.of(context)
                                      .extension<StackColors>()!
                                      .textFieldActiveBG
                                  : Theme.of(context)
                                      .extension<StackColors>()!
                                      .textFieldDefaultBG,
                              isCollapsed: true,
                              hintText: "Name",
                              hintStyle: STextStyles.body(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textMedium,
                              ),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 0),
                                child: UnconstrainedBox(
                                  child: Row(
                                    children: [
                                      if (ref
                                          .watch(
                                              contactNameIsNotEmptyStateProvider
                                                  .state)
                                          .state)
                                        TextFieldIconButton(
                                          child: const XIcon(),
                                          onTap: () async {
                                            ref
                                                .read(
                                                    contactNameIsNotEmptyStateProvider
                                                        .state)
                                                .state = false;
                                            setState(() {
                                              nameController.text = "";
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: SecondaryButton(
                                  label: "Cancel",
                                  onPressed: () async {
                                    if (FocusScope.of(context).hasFocus) {
                                      FocusScope.of(context).unfocus();
                                      await Future<void>.delayed(
                                        const Duration(milliseconds: 75),
                                      );
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
                                        .watch(
                                            contactNameIsNotEmptyStateProvider
                                                .state)
                                        .state;

                                    bool validForms = ref
                                        .watch(validContactStateProvider([0]));

                                    bool shouldEnableSave =
                                        validForms && nameExists;

                                    return PrimaryButton(
                                      label: "Save",
                                      enabled: shouldEnableSave,
                                      onPressed: shouldEnableSave
                                          ? () async {
                                              if (FocusScope.of(context)
                                                  .hasFocus) {
                                                FocusScope.of(context)
                                                    .unfocus();
                                                await Future<void>.delayed(
                                                  const Duration(
                                                      milliseconds: 75),
                                                );
                                              }
                                              List<ContactAddressEntry>
                                                  entries = [
                                                ref
                                                    .read(
                                                        addressEntryDataProvider(
                                                            0))
                                                    .buildAddressEntry()
                                              ];

                                              Contact contact = Contact(
                                                name: nameController.text,
                                                addresses: entries,
                                                isFavorite: false,
                                              );

                                              if (await ref
                                                  .read(
                                                      addressBookServiceProvider)
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
