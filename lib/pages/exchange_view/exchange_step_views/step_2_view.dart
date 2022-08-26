import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/pages/address_book_views/address_book_view.dart';
import 'package:stackwallet/pages/exchange_view/exchange_step_views/step_3_view.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/step_row.dart';
import 'package:stackwallet/providers/exchange/exchange_flow_is_active_state_provider.dart';
import 'package:stackwallet/providers/exchange/exchange_send_from_wallet_id_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/icon_widgets/addressbook_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class Step2View extends ConsumerStatefulWidget {
  const Step2View({
    Key? key,
    required this.model,
    this.clipboard = const ClipboardWrapper(),
    this.barcodeScanner = const BarcodeScannerWrapper(),
  }) : super(key: key);

  static const String routeName = "/exchangeStep2";

  final IncompleteExchangeModel model;
  final ClipboardInterface clipboard;
  final BarcodeScannerInterface barcodeScanner;

  @override
  ConsumerState<Step2View> createState() => _Step2ViewState();
}

class _Step2ViewState extends ConsumerState<Step2View> {
  late final IncompleteExchangeModel model;
  late final ClipboardInterface clipboard;
  late final BarcodeScannerInterface scanner;

  late final TextEditingController _toController;
  late final TextEditingController _refundController;

  late final FocusNode _toFocusNode;
  late final FocusNode _refundFocusNode;

  @override
  void initState() {
    model = widget.model;
    clipboard = widget.clipboard;
    scanner = widget.barcodeScanner;

    _toController = TextEditingController();
    _refundController = TextEditingController();

    _toFocusNode = FocusNode();
    _refundFocusNode = FocusNode();

    final tuple = ref.read(exchangeSendFromWalletIdStateProvider.state).state;
    if (tuple != null) {
      if (model.receiveTicker.toLowerCase() ==
          tuple.item2.ticker.toLowerCase()) {
        ref
            .read(walletsChangeNotifierProvider)
            .getManager(tuple.item1)
            .currentReceivingAddress
            .then((value) => _toController.text = value);
      }
    }

    super.initState();
  }

  @override
  void dispose() {
    _toController.dispose();
    _refundController.dispose();

    _toFocusNode.dispose();
    _refundFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          "Exchange",
          style: STextStyles.navBarTitle,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = MediaQuery.of(context).size.width - 32;
          return Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StepRow(
                          count: 4,
                          current: 1,
                          width: width,
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        Text(
                          "Exchange details",
                          style: STextStyles.pageTitleH1,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          "Enter your recipient and refund addresses",
                          style: STextStyles.itemSubtitle,
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Recipient Wallet",
                              style: STextStyles.itemSubtitle.copyWith(
                                color: CFColors.neutral50,
                              ),
                            ),
                            // GestureDetector(
                            //   onTap: () {
                            //     // TODO: choose from stack?
                            //   },
                            //   child: Text(
                            //     "Choose from Stack",
                            //     style: STextStyles.link2,
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Constants.size.circularBorderRadius,
                          ),
                          child: TextField(
                            onTap: () {},
                            key: const Key(
                                "recipientExchangeStep2ViewAddressFieldKey"),
                            controller: _toController,
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
                            focusNode: _toFocusNode,
                            style: STextStyles.field,
                            decoration: standardInputDecoration(
                              "Enter the ${model.receiveTicker} payout address",
                              _toFocusNode,
                            ).copyWith(
                              contentPadding: const EdgeInsets.only(
                                left: 16,
                                top: 6,
                                bottom: 8,
                                right: 5,
                              ),
                              suffixIcon: Padding(
                                padding: _toController.text.isEmpty
                                    ? const EdgeInsets.only(right: 8)
                                    : const EdgeInsets.only(right: 0),
                                child: UnconstrainedBox(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _toController.text.isNotEmpty
                                          ? TextFieldIconButton(
                                              key: const Key(
                                                  "sendViewClearAddressFieldButtonKey"),
                                              onTap: () {
                                                _toController.text = "";

                                                setState(() {});
                                              },
                                              child: const XIcon(),
                                            )
                                          : TextFieldIconButton(
                                              key: const Key(
                                                  "sendViewPasteAddressFieldButtonKey"),
                                              onTap: () async {
                                                final ClipboardData? data =
                                                    await clipboard.getData(
                                                        Clipboard.kTextPlain);
                                                if (data?.text != null &&
                                                    data!.text!.isNotEmpty) {
                                                  final content =
                                                      data.text!.trim();

                                                  _toController.text = content;

                                                  setState(() {});
                                                }
                                              },
                                              child: _toController.text.isEmpty
                                                  ? const ClipboardIcon()
                                                  : const XIcon(),
                                            ),
                                      if (_toController.text.isEmpty)
                                        TextFieldIconButton(
                                          key: const Key(
                                              "sendViewAddressBookButtonKey"),
                                          onTap: () {
                                            ref
                                                .read(
                                                    exchangeFlowIsActiveStateProvider
                                                        .state)
                                                .state = true;
                                            Navigator.of(context)
                                                .pushNamed(
                                                  AddressBookView.routeName,
                                                )
                                                .then((_) => ref
                                                    .read(
                                                        exchangeFlowIsActiveStateProvider
                                                            .state)
                                                    .state = false);
                                          },
                                          child: const AddressBookIcon(),
                                        ),
                                      if (_toController.text.isEmpty)
                                        TextFieldIconButton(
                                          key: const Key(
                                              "sendViewScanQrButtonKey"),
                                          onTap: () async {
                                            try {
                                              // ref
                                              //     .read(
                                              //         shouldShowLockscreenOnResumeStateProvider
                                              //             .state)
                                              //     .state = false;
                                              final qrResult =
                                                  await scanner.scan();

                                              // Future<void>.delayed(
                                              //   const Duration(seconds: 2),
                                              //   () => ref
                                              //       .read(
                                              //           shouldShowLockscreenOnResumeStateProvider
                                              //               .state)
                                              //       .state = true,
                                              // );

                                              final results =
                                                  AddressUtils.parseUri(
                                                      qrResult.rawContent);
                                              if (results.isNotEmpty) {
                                                // auto fill address
                                                _toController.text =
                                                    results["address"] ?? "";

                                                setState(() {});
                                              } else {
                                                _toController.text =
                                                    qrResult.rawContent;

                                                setState(() {});
                                              }
                                            } on PlatformException catch (e, s) {
                                              // ref
                                              //     .read(
                                              //         shouldShowLockscreenOnResumeStateProvider
                                              //             .state)
                                              //     .state = true;
                                              // here we ignore the exception caused by not giving permission
                                              // to use the camera to scan a qr code
                                              Logging.instance.log(
                                                  "Failed to get camera permissions while trying to scan qr code in SendView: $e\n$s",
                                                  level: LogLevel.Warning);
                                            }
                                          },
                                          child: const QrCodeIcon(),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        RoundedWhiteContainer(
                          child: Text(
                            "This is the wallet where your BTC will be sent to.",
                            style: STextStyles.label,
                          ),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Refund Wallet (required)",
                              style: STextStyles.smallMed12,
                            ),
                            // GestureDetector(
                            //   onTap: () {
                            //     // TODO: choose from stack?
                            //   },
                            //   child: Text(
                            //     "Choose from Stack",
                            //     style: STextStyles.link2,
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Constants.size.circularBorderRadius,
                          ),
                          child: TextField(
                            key: const Key(
                                "refundExchangeStep2ViewAddressFieldKey"),
                            controller: _refundController,
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
                            focusNode: _refundFocusNode,
                            style: STextStyles.field,
                            decoration: standardInputDecoration(
                              "Enter ${model.sendTicker} refund address",
                              _refundFocusNode,
                            ).copyWith(
                              contentPadding: const EdgeInsets.only(
                                left: 16,
                                top: 6,
                                bottom: 8,
                                right: 5,
                              ),
                              suffixIcon: Padding(
                                padding: _refundController.text.isEmpty
                                    ? const EdgeInsets.only(right: 16)
                                    : const EdgeInsets.only(right: 0),
                                child: UnconstrainedBox(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _refundController.text.isNotEmpty
                                          ? TextFieldIconButton(
                                              key: const Key(
                                                  "sendViewClearAddressFieldButtonKey"),
                                              onTap: () {
                                                _refundController.text = "";

                                                setState(() {});
                                              },
                                              child: const XIcon(),
                                            )
                                          : TextFieldIconButton(
                                              key: const Key(
                                                  "sendViewPasteAddressFieldButtonKey"),
                                              onTap: () async {
                                                final ClipboardData? data =
                                                    await clipboard.getData(
                                                        Clipboard.kTextPlain);
                                                if (data?.text != null &&
                                                    data!.text!.isNotEmpty) {
                                                  final content =
                                                      data.text!.trim();

                                                  _refundController.text =
                                                      content;

                                                  setState(() {});
                                                }
                                              },
                                              child:
                                                  _refundController.text.isEmpty
                                                      ? const ClipboardIcon()
                                                      : const XIcon(),
                                            ),
                                      if (_refundController.text.isEmpty)
                                        TextFieldIconButton(
                                          key: const Key(
                                              "sendViewAddressBookButtonKey"),
                                          onTap: () {
                                            ref
                                                .read(
                                                    exchangeFlowIsActiveStateProvider
                                                        .state)
                                                .state = true;
                                            Navigator.of(context)
                                                .pushNamed(
                                                  AddressBookView.routeName,
                                                )
                                                .then((_) => ref
                                                    .read(
                                                        exchangeFlowIsActiveStateProvider
                                                            .state)
                                                    .state = false);
                                          },
                                          child: const AddressBookIcon(),
                                        ),
                                      if (_refundController.text.isEmpty)
                                        TextFieldIconButton(
                                          key: const Key(
                                              "sendViewScanQrButtonKey"),
                                          onTap: () async {
                                            try {
                                              // ref
                                              //     .read(
                                              //         shouldShowLockscreenOnResumeStateProvider
                                              //             .state)
                                              //     .state = false;
                                              final qrResult =
                                                  await scanner.scan();

                                              // Future<void>.delayed(
                                              //   const Duration(seconds: 2),
                                              //   () => ref
                                              //       .read(
                                              //           shouldShowLockscreenOnResumeStateProvider
                                              //               .state)
                                              //       .state = true,
                                              // );

                                              final results =
                                                  AddressUtils.parseUri(
                                                      qrResult.rawContent);
                                              if (results.isNotEmpty) {
                                                // auto fill address
                                                _refundController.text =
                                                    results["address"] ?? "";

                                                setState(() {});
                                              } else {
                                                _refundController.text =
                                                    qrResult.rawContent;

                                                setState(() {});
                                              }
                                            } on PlatformException catch (e, s) {
                                              // ref
                                              //     .read(
                                              //         shouldShowLockscreenOnResumeStateProvider
                                              //             .state)
                                              //     .state = true;
                                              // here we ignore the exception caused by not giving permission
                                              // to use the camera to scan a qr code
                                              Logging.instance.log(
                                                  "Failed to get camera permissions while trying to scan qr code in SendView: $e\n$s",
                                                  level: LogLevel.Warning);
                                            }
                                          },
                                          child: const QrCodeIcon(),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        RoundedWhiteContainer(
                          child: Text(
                            "In case something goes wrong during the exchange, we might need a refund address so we can return your coins back to you.",
                            style: STextStyles.label,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  "Back",
                                  style: STextStyles.button.copyWith(
                                    color: CFColors.stackAccent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  model.recipientAddress = _toController.text;
                                  model.refundAddress = _refundController.text;

                                  Navigator.of(context).pushNamed(
                                      Step3View.routeName,
                                      arguments: model);
                                },
                                style: Theme.of(context)
                                    .textButtonTheme
                                    .style
                                    ?.copyWith(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                        CFColors.stackAccent,
                                      ),
                                    ),
                                child: Text(
                                  "Next",
                                  style: STextStyles.button,
                                ),
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
