import 'dart:async';

import 'package:epicpay/models/send_view_auto_fill_data.dart';
import 'package:epicpay/pages/address_book_views/address_book_view.dart';
import 'package:epicpay/pages/home_view/home_view.dart';
import 'package:epicpay/pages/send_view/send_amount_view.dart';
import 'package:epicpay/providers/providers.dart';
import 'package:epicpay/services/coins/manager.dart';
import 'package:epicpay/utilities/address_utils.dart';
import 'package:epicpay/utilities/barcode_scanner_interface.dart';
import 'package:epicpay/utilities/clipboard_interface.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:epicpay/utilities/logger.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/desktop/primary_button.dart';
import 'package:epicpay/widgets/icon_widgets/addressbook_icon.dart';
import 'package:epicpay/widgets/icon_widgets/clipboard_icon.dart';
import 'package:epicpay/widgets/icon_widgets/qrcode_icon.dart';
import 'package:epicpay/widgets/icon_widgets/x_icon.dart';
import 'package:epicpay/widgets/rounded_container.dart';
import 'package:epicpay/widgets/stack_dialog.dart';
import 'package:epicpay/widgets/textfield_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

final sendViewFillDataProvider =
    StateProvider<SendViewAutoFillData?>((ref) => null);

class SendView extends ConsumerStatefulWidget {
  const SendView({
    Key? key,
    required this.walletId,
    required this.coin,
    this.barcodeScanner = const BarcodeScannerWrapper(),
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/sendView";

  final String walletId;
  final Coin coin;

  final BarcodeScannerInterface barcodeScanner;
  final ClipboardInterface? clipboard;

  @override
  ConsumerState<SendView> createState() => _SendViewState();
}

class _SendViewState extends ConsumerState<SendView> {
  late final String walletId;
  late final Coin coin;
  late final BarcodeScannerInterface scanner;

  late TextEditingController sendToController;

  SendViewAutoFillData? _fillData;

  final _addressFocusNode = FocusNode();
  String? _address;

  bool _addressToggleFlag = false;

  late VoidCallback onCryptoAmountChanged;

  String? _updateInvalidAddressText(String address, Manager manager) {
    if (_fillData != null && _fillData!.contactLabel == address) {
      return null;
    }
    if (address.isNotEmpty && !manager.validateAddress(address)) {
      return "Invalid address";
    }
    return null;
  }

  @override
  void initState() {
    walletId = widget.walletId;
    coin = widget.coin;
    scanner = widget.barcodeScanner;

    sendToController = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    sendToController.dispose();
    _addressFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    _fillData = ref.watch(sendViewFillDataProvider.state).state;
    if (_fillData != null) {
      sendToController.text = _fillData!.contactLabel;
      _address = _fillData!.address;
      _addressToggleFlag = true;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        ref.read(sendViewFillDataProvider.state).state = null;
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).extension<StackColors>()!.background,
      body: LayoutBuilder(
        builder: (builderContext, constraints) {
          return Padding(
            padding: const EdgeInsets.only(
              left: 12,
              top: 12,
              right: 12,
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // subtract top and bottom padding set in parent
                  minHeight: constraints.maxHeight - 24,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(
                          flex: 2,
                        ),
                        Text(
                          "Send EPIC",
                          style: STextStyles.titleH3(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textGold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          "Enter your recipient's address:",
                          style: STextStyles.bodySmallBold(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textMedium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        RoundedContainer(
                          color:
                              Theme.of(context).extension<StackColors>()!.coal,
                          child: Column(
                            children: [
                              TextField(
                                key: const Key("sendViewAddressFieldKey"),
                                controller: sendToController,
                                readOnly: false,
                                autocorrect: false,
                                enableSuggestions: false,
                                keyboardType: TextInputType.multiline,
                                minLines: 3,
                                maxLines: 3,
                                toolbarOptions: const ToolbarOptions(
                                  copy: false,
                                  cut: false,
                                  paste: true,
                                  selectAll: false,
                                ),
                                onChanged: (newValue) {
                                  _address = newValue;

                                  setState(() {
                                    _addressToggleFlag = ref
                                        .read(walletProvider)!
                                        .validateAddress(newValue);
                                  });
                                },
                                focusNode: _addressFocusNode,
                                style: STextStyles.body(context),
                                decoration: InputDecoration(
                                  hintText: "Paste address...",
                                  hintStyle: STextStyles.body(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textMedium,
                                  ),
                                  isCollapsed: true,
                                  border: InputBorder.none,
                                  focusColor: Colors.transparent,
                                  fillColor: Colors.transparent,
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 4,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _addressToggleFlag
                                      ? TextFieldIconButton(
                                          key: const Key(
                                              "sendViewClearAddressFieldButtonKey"),
                                          onTap: () {
                                            sendToController.text = "";
                                            _address = "";
                                            setState(() {
                                              _addressToggleFlag = false;
                                            });
                                          },
                                          child: const XIcon(),
                                        )
                                      : TextFieldIconButton(
                                          key: const Key(
                                              "sendViewPasteAddressFieldButtonKey"),
                                          onTap: () async {
                                            final ClipboardData? data =
                                                await widget.clipboard?.getData(
                                                    Clipboard.kTextPlain);
                                            if (data?.text != null &&
                                                data!.text!.isNotEmpty) {
                                              String content =
                                                  data.text!.trim();
                                              if (content.contains("\n")) {
                                                content = content.substring(
                                                    0, content.indexOf("\n"));
                                              }
                                              if ((content.startsWith(
                                                          "http://") ||
                                                      content.startsWith(
                                                  content.contains("@")) {
                                                content = content.replaceAll(
                                                    "http://", "");
                                                content = content.replaceAll(
                                                    "https://", "");
                                              }

                                              sendToController.text = content;
                                              _address = content;

                                              setState(() {
                                                _addressToggleFlag =
                                                    sendToController
                                                        .text.isNotEmpty;
                                              });
                                            }
                                          },
                                          child: sendToController.text.isEmpty
                                              ? const ClipboardIcon()
                                              : const XIcon(),
                                        ),
                                  //
                                  TextFieldIconButton(
                                    key: const Key("sendViewScanQrButtonKey"),
                                    onTap: () async {
                                      try {
                                        if (FocusScope.of(context).hasFocus) {
                                          FocusScope.of(context).unfocus();
                                          await Future<void>.delayed(
                                              const Duration(milliseconds: 75));
                                        }

                                        final qrResult = await scanner.scan();

                                        Logging.instance.log(
                                            "qrResult content: ${qrResult.rawContent}",
                                            level: LogLevel.Info);

                                        final results = AddressUtils.parseUri(
                                            qrResult.rawContent);

                                        Logging.instance.log(
                                            "qrResult parsed: $results",
                                            level: LogLevel.Info);

                                        if (results.isNotEmpty &&
                                            results["scheme"] ==
                                                coin.uriScheme) {
                                          // auto fill address
                                          _address = results["address"] ?? "";
                                          sendToController.text = _address!;

                                          setState(() {
                                            _addressToggleFlag =
                                                sendToController
                                                    .text.isNotEmpty;
                                          });

                                          // now check for non standard encoded basic address
                                        } else if (ref
                                            .read(walletProvider)!
                                            .validateAddress(
                                                qrResult.rawContent)) {
                                          _address = qrResult.rawContent;
                                          sendToController.text =
                                              _address ?? "";

                                          setState(() {
                                            _addressToggleFlag =
                                                sendToController
                                                    .text.isNotEmpty;
                                          });
                                        }
                                      } on PlatformException catch (e, s) {
                                        // here we ignore the exception caused by not giving permission
                                        // to use the camera to scan a qr code
                                        Logging.instance.log(
                                            "Failed to get camera permissions while trying to scan qr code in SendView: $e\n$s",
                                            level: LogLevel.Warning);
                                      }
                                    },
                                    child: const QrCodeIcon(),
                                  ),
                                  TextFieldIconButton(
                                    key: const Key(
                                        "sendViewAddressBookButtonKey"),
                                    onTap: () async {
                                      FocusScope.of(context).unfocus();

                                      await Navigator.of(context).pushNamed(
                                        AddressBookView.routeName,
                                        arguments:
                                            (String name, String address) {
                                          _address = address;
                                          sendToController.text = name;

                                          Navigator.of(context).popUntil(
                                              ModalRoute.withName(
                                                  HomeView.routeName));
                                          ref
                                              .read(
                                                  homeViewPageIndexStateProvider
                                                      .state)
                                              .state = 0;
                                        },
                                      );

                                      setState(() {
                                        _addressToggleFlag = _address != null &&
                                            _address!.isNotEmpty;
                                      });
                                    },
                                    child: AddressBookIcon(
                                      width: 24,
                                      height: 24,
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .textFieldActiveSearchIconRight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Builder(
                          builder: (_) {
                            final error = _updateInvalidAddressText(
                              _address ?? "",
                              ref.read(walletProvider)!,
                            );

                            if (error == null || error.isEmpty) {
                              return Container();
                            } else {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 12.0,
                                    top: 4.0,
                                  ),
                                  child: Text(
                                    error,
                                    textAlign: TextAlign.left,
                                    style: STextStyles.label(context).copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .textError,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        PrimaryButton(
                          label: "NEXT",
                          enabled: _addressToggleFlag,
                          onPressed: () async {
                            final bool isAddress = await ref
                                .read(walletProvider)
                                ?.isOwnAddress(_address!) as bool;

                            isAddress
                                ? await showDialog<dynamic>(
                                    context: context,
                                    useSafeArea: false,
                                    barrierDismissible: true,
                                    builder: (context) {
                                      return StackDialog(
                                        title: "Transaction failed",
                                        message:
                                            "Sending to self is currently disabled",
                                        rightButton: TextButton(
                                          style: Theme.of(context)
                                              .extension<StackColors>()!
                                              .getSecondaryEnabledButtonColor(
                                                  context),
                                          child: Text(
                                            "Ok",
                                            style:
                                                STextStyles.buttonText(context)
                                                    .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorDark,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      );
                                    },
                                  )
                                : Navigator.of(context).pushNamed(
                                    SendAmountView.routeName,
                                    arguments: Tuple3(
                                      ref.read(walletProvider)!.walletId,
                                      _address!,
                                      Coin.epicCash,
                                    ),
                                  );
                            debugPrint(_address!);
                          },
                        ),
                        const Spacer(
                          flex: 2,
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
