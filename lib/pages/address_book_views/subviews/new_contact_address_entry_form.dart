// import 'package:epicpay/providers/global/should_show_lockscreen_on_resume_state_provider.dart';
import 'package:epicpay/providers/ui/address_book_providers/address_entry_data_provider.dart';
import 'package:epicpay/utilities/barcode_scanner_interface.dart';
import 'package:epicpay/utilities/clipboard_interface.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utilities/address_utils.dart';
import '../../../utilities/logger.dart';
import '../../../widgets/icon_widgets/clipboard_icon.dart';
import '../../../widgets/icon_widgets/qrcode_icon.dart';
import '../../../widgets/icon_widgets/x_icon.dart';
import '../../../widgets/textfield_icon_button.dart';
// import 'package:epicpay/widgets/textfield_icon_button';

class NewContactAddressEntryForm extends ConsumerStatefulWidget {
  const NewContactAddressEntryForm({
    Key? key,
    required this.id,
    required this.barcodeScanner,
    required this.clipboard,
  }) : super(key: key);

  final int id;

  final BarcodeScannerInterface barcodeScanner;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<NewContactAddressEntryForm> createState() =>
      _NewContactAddressEntryFormState();
}

class _NewContactAddressEntryFormState
    extends ConsumerState<NewContactAddressEntryForm> {
  late final TextEditingController addressController;

  late final FocusNode addressFocusNode;

  @override
  void initState() {
    addressController = TextEditingController()
      ..text = ref.read(addressEntryDataProvider(widget.id)).address ?? "";
    addressFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    addressController.dispose();
    addressFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          enableSuggestions: false,
          focusNode: addressFocusNode,
          controller: addressController,
          style: STextStyles.body(context),
          textAlignVertical: TextAlignVertical.center,
          key: const Key("addAddressBookEntryViewAddressField"),
          readOnly: false,
          autocorrect: false,
          toolbarOptions: const ToolbarOptions(
            copy: false,
            cut: false,
            paste: true,
            selectAll: false,
          ),
          onChanged: (newValue) {
            ref.read(addressEntryDataProvider(widget.id)).address = newValue;
          },
          decoration: InputDecoration(
            fillColor: addressFocusNode.hasFocus
                ? Theme.of(context).extension<StackColors>()!.textFieldActiveBG
                : Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
            isCollapsed: true,
            hintText: "Address",
            hintStyle: STextStyles.body(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textMedium,
            ),
            suffixIcon: UnconstrainedBox(
              child: Row(
                children: [
                  if (ref.watch(addressEntryDataProvider(widget.id)
                          .select((value) => value.address)) !=
                      null)
                    TextFieldIconButton(
                      key: const Key("addAddressBookClearAddressButtonKey"),
                      onTap: () async {
                        addressController.text = "";
                        ref.read(addressEntryDataProvider(widget.id)).address =
                            null;
                      },
                      child: const XIcon(),
                    ),
                  if (ref.watch(addressEntryDataProvider(widget.id)
                          .select((value) => value.address)) ==
                      null)
                    TextFieldIconButton(
                      key: const Key("addAddressPasteAddressButtonKey"),
                      onTap: () async {
                        final ClipboardData? data = await widget.clipboard
                            .getData(Clipboard.kTextPlain);

                        if (data?.text != null && data!.text!.isNotEmpty) {
                          String content = data.text!.trim();
                          if (content.contains("\n")) {
                            content =
                                content.substring(0, content.indexOf("\n"));
                          }
                          if ((content.startsWith("http://") ||
                                  content.startsWith("https://")) &&
                              content.contains("@")) {
                            content.replaceAll("http://", "");
                            content.replaceAll("https://", "");
                          }
                          addressController.text = content;
                          ref
                              .read(addressEntryDataProvider(widget.id))
                              .address = content.isEmpty ? null : content;
                        }
                      },
                      child: const ClipboardIcon(),
                    ),
                  if (ref.watch(addressEntryDataProvider(widget.id)
                          .select((value) => value.address)) ==
                      null)
                    TextFieldIconButton(
                      key: const Key("addAddressBookEntryScanQrButtonKey"),
                      onTap: () async {
                        try {
                          final qrResult = await widget.barcodeScanner.scan();

                          final results =
                              AddressUtils.parseUri(qrResult.rawContent);
                          if (results.isNotEmpty) {
                            addressController.text = results["address"] ?? "";
                            ref
                                    .read(addressEntryDataProvider(widget.id))
                                    .address =
                                addressController.text.isEmpty
                                    ? null
                                    : addressController.text;

                            // now check for non standard encoded basic address
                          } else if (ref
                                  .read(addressEntryDataProvider(widget.id))
                                  .coin !=
                              null) {
                            if (AddressUtils.validateAddress(
                                qrResult.rawContent,
                                ref
                                    .read(addressEntryDataProvider(widget.id))
                                    .coin!)) {
                              addressController.text = qrResult.rawContent;
                              ref
                                  .read(addressEntryDataProvider(widget.id))
                                  .address = qrResult.rawContent;
                            }
                          }
                        } on PlatformException catch (e, s) {
                          Logging.instance.log(
                              "Failed to get camera permissions to scan address qr code: $e\n$s",
                              level: LogLevel.Warning);
                        }
                      },
                      child: const QrCodeIcon(),
                    ),
                  const SizedBox(
                    width: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!ref.watch(addressEntryDataProvider(widget.id)
                .select((value) => value.isValidAddress)) &&
            addressController.text.isNotEmpty)
          Row(
            children: [
              const SizedBox(
                width: 12,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    "Invalid address",
                    textAlign: TextAlign.left,
                    style: STextStyles.label(context).copyWith(
                      color:
                          Theme.of(context).extension<StackColors>()!.textError,
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
