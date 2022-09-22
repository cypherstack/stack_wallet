import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/address_book_views/subviews/coin_select_sheet.dart';
// import 'package:stackwallet/providers/global/should_show_lockscreen_on_resume_state_provider.dart';
import 'package:stackwallet/providers/ui/address_book_providers/address_entry_data_provider.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';

import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

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
  late final TextEditingController addressLabelController;
  late final TextEditingController addressController;

  late final FocusNode addressLabelFocusNode;
  late final FocusNode addressFocusNode;

  @override
  void initState() {
    addressLabelController = TextEditingController()
      ..text = ref.read(addressEntryDataProvider(widget.id)).addressLabel ?? "";
    addressController = TextEditingController()
      ..text = ref.read(addressEntryDataProvider(widget.id)).address ?? "";
    addressLabelFocusNode = FocusNode();
    addressFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    addressLabelController.dispose();
    addressController.dispose();
    addressLabelFocusNode.dispose();
    addressFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          readOnly: true,
          style: STextStyles.field,
          decoration: InputDecoration(
            hintText: "Select cryptocurrency",
            hintStyle: STextStyles.fieldLabel,
            prefixIcon: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: RawMaterialButton(
                  splashColor: StackTheme.instance.color.highlight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                  onPressed: () {
                    showModalBottomSheet<dynamic>(
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (_) => const CoinSelectSheet(),
                    ).then((value) {
                      if (value is Coin) {
                        ref.read(addressEntryDataProvider(widget.id)).coin =
                            value;
                      }
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ref.watch(addressEntryDataProvider(widget.id)
                                  .select((value) => value.coin)) ==
                              null
                          ? Text(
                              "Select cryptocurrency",
                              style: STextStyles.fieldLabel,
                            )
                          : Row(
                              children: [
                                SvgPicture.asset(
                                  Assets.svg.iconFor(
                                      coin: ref.watch(
                                          addressEntryDataProvider(widget.id)
                                              .select((value) => value.coin))!),
                                  height: 20,
                                  width: 20,
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Text(
                                  ref
                                      .watch(addressEntryDataProvider(widget.id)
                                          .select((value) => value.coin))!
                                      .prettyName,
                                  style: STextStyles.itemSubtitle12,
                                ),
                              ],
                            ),
                      SvgPicture.asset(
                        Assets.svg.chevronDown,
                        width: 8,
                        height: 4,
                        color: StackTheme.instance.color.textSubtitle2,
                      ),
                    ],
                  ),
                ),
              ),
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
            focusNode: addressLabelFocusNode,
            controller: addressLabelController,
            style: STextStyles.field,
            decoration: standardInputDecoration(
              "Enter address label",
              addressLabelFocusNode,
            ).copyWith(
              suffixIcon: addressLabelController.text.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 0),
                      child: UnconstrainedBox(
                        child: Row(
                          children: [
                            TextFieldIconButton(
                              child: const XIcon(),
                              onTap: () async {
                                setState(() {
                                  addressLabelController.text = "";
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
              ref.read(addressEntryDataProvider(widget.id)).addressLabel =
                  newValue;
              setState(() {});
            },
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
            focusNode: addressFocusNode,
            controller: addressController,
            style: STextStyles.field,
            decoration: standardInputDecoration(
              "Paste address",
              addressFocusNode,
            ).copyWith(
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
                          ref
                              .read(addressEntryDataProvider(widget.id))
                              .address = null;
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
                            // ref
                            //     .read(shouldShowLockscreenOnResumeStateProvider
                            //         .state)
                            //     .state = false;
                            final qrResult = await widget.barcodeScanner.scan();

                            // Future<void>.delayed(
                            //   const Duration(seconds: 2),
                            //   () => ref
                            //       .read(
                            //           shouldShowLockscreenOnResumeStateProvider
                            //               .state)
                            //       .state = true,
                            // );

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

                              addressLabelController.text = results["label"] ??
                                  addressLabelController.text;
                              ref
                                      .read(addressEntryDataProvider(widget.id))
                                      .addressLabel =
                                  addressLabelController.text.isEmpty
                                      ? null
                                      : addressLabelController.text;

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
                            // ref
                            //     .read(shouldShowLockscreenOnResumeStateProvider
                            //         .state)
                            //     .state = true;
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
            key: const Key("addAddressBookEntryViewAddressField"),
            readOnly: false,
            autocorrect: false,
            enableSuggestions: false,
            // inputFormatters: <TextInputFormatter>[
            //   FilteringTextInputFormatter.allow(RegExp("[a-zA-Z0-9]{34}")),
            // ],
            toolbarOptions: const ToolbarOptions(
              copy: false,
              cut: false,
              paste: true,
              selectAll: false,
            ),
            onChanged: (newValue) {
              ref.read(addressEntryDataProvider(widget.id)).address = newValue;
            },
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
                    style: STextStyles.label.copyWith(
                      color: StackTheme.instance.color.textError,
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
