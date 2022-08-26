import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/contact.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/pages/address_book_views/subviews/new_contact_address_entry_form.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/providers/ui/address_book_providers/address_entry_data_provider.dart';
import 'package:stackwallet/providers/ui/address_book_providers/valid_contact_state_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';

class EditContactAddressView extends ConsumerStatefulWidget {
  const EditContactAddressView({
    Key? key,
    required this.contactId,
    required this.addressEntry,
    this.barcodeScanner = const BarcodeScannerWrapper(),
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/editContactAddress";

  final String contactId;
  final ContactAddressEntry addressEntry;

  final BarcodeScannerInterface barcodeScanner;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<EditContactAddressView> createState() =>
      _EditContactAddressViewState();
}

class _EditContactAddressViewState
    extends ConsumerState<EditContactAddressView> {
  late final String contactId;
  late final ContactAddressEntry addressEntry;

  late final BarcodeScannerInterface barcodeScanner;
  late final ClipboardInterface clipboard;

  @override
  void initState() {
    contactId = widget.contactId;
    addressEntry = widget.addressEntry;
    barcodeScanner = widget.barcodeScanner;
    clipboard = widget.clipboard;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final contact = ref.watch(addressBookServiceProvider
        .select((value) => value.getContactById(contactId)));

    return Scaffold(
      backgroundColor: CFColors.almostWhite,
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
          "Edit address",
          style: STextStyles.navBarTitle,
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
                        Row(
                          children: [
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                color: CFColors.textFieldActive,
                              ),
                              child: Center(
                                child: contact.emojiChar == null
                                    ? SvgPicture.asset(
                                        Assets.svg.user,
                                        height: 24,
                                        width: 24,
                                      )
                                    : Text(
                                        contact.emojiChar!,
                                        style: STextStyles.pageTitleH1,
                                      ),
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  contact.name,
                                  style: STextStyles.pageTitleH2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        NewContactAddressEntryForm(
                          id: 0,
                          barcodeScanner: barcodeScanner,
                          clipboard: clipboard,
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        GestureDetector(
                          onTap: () async {
                            // delete address
                            final _addresses = contact.addresses;
                            final entry = _addresses.firstWhere(
                              (e) =>
                                  e.label == addressEntry.label &&
                                  e.address == addressEntry.address &&
                                  e.coin == addressEntry.coin,
                            );

                            _addresses.remove(entry);
                            Contact editedContact =
                                contact.copyWith(addresses: _addresses);
                            if (await ref
                                .read(addressBookServiceProvider)
                                .editContact(editedContact)) {
                              Navigator.of(context).pop();
                              // TODO show success notification
                            } else {
                              // TODO show error notification
                            }
                          },
                          child: Text(
                            "Delete address",
                            style: STextStyles.link,
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
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                    CFColors.buttonGray,
                                  ),
                                ),
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
                                  bool shouldEnableSave =
                                      ref.watch(validContactStateProvider([0]));

                                  return TextButton(
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                        shouldEnableSave
                                            ? CFColors.stackAccent
                                            : CFColors.disabledButton,
                                      ),
                                    ),
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
                                            List<ContactAddressEntry> entries =
                                                contact.addresses.toList();

                                            final entry = entries.firstWhere(
                                              (e) =>
                                                  e.label ==
                                                      addressEntry.label &&
                                                  e.address ==
                                                      addressEntry.address &&
                                                  e.coin == addressEntry.coin,
                                            );

                                            final index =
                                                entries.indexOf(entry);
                                            entries.remove(entry);

                                            ContactAddressEntry editedEntry = ref
                                                .read(
                                                    addressEntryDataProvider(0))
                                                .buildAddressEntry();

                                            entries.insert(index, editedEntry);

                                            Contact editedContact = contact
                                                .copyWith(addresses: entries);

                                            if (await ref
                                                .read(
                                                    addressBookServiceProvider)
                                                .editContact(editedContact)) {
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
            ),
          );
        },
      ),
    );
  }
}
