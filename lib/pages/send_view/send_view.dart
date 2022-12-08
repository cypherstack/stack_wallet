import 'dart:async';

import 'package:epicmobile/models/send_view_auto_fill_data.dart';
import 'package:epicmobile/pages/address_book_views/address_book_view.dart';
import 'package:epicmobile/pages/home_view/home_view.dart';
import 'package:epicmobile/pages/send_view/send_amount_view.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/providers/ui/preview_tx_button_state_provider.dart';
import 'package:epicmobile/services/coins/manager.dart';
import 'package:epicmobile/utilities/address_utils.dart';
import 'package:epicmobile/utilities/barcode_scanner_interface.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/logger.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/desktop/primary_button.dart';
import 'package:epicmobile/widgets/icon_widgets/addressbook_icon.dart';
import 'package:epicmobile/widgets/icon_widgets/qrcode_icon.dart';
import 'package:epicmobile/widgets/icon_widgets/x_icon.dart';
import 'package:epicmobile/widgets/textfield_icon_button.dart';
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
  }) : super(key: key);

  static const String routeName = "/sendView";

  final String walletId;
  final Coin coin;
  final BarcodeScannerInterface barcodeScanner;

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

  void _updatePreviewButtonState(String? address) {
    final isValidAddress =
        ref.read(walletProvider)!.validateAddress(address ?? "");
    ref.read(previewTxButtonStateProvider.state).state = isValidAddress;
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
        _updatePreviewButtonState(_address);
        ref.read(sendViewFillDataProvider.state).state = null;
      });
    }

    return Background(
      child: Scaffold(
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
                                    .buttonBackPrimary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            "Enter your recipient's address:",
                            style: STextStyles.smallMed14(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              Constants.size.circularBorderRadius,
                            ),
                            child: TextField(
                              key: const Key("sendViewAddressFieldKey"),
                              controller: sendToController,
                              readOnly: false,
                              autocorrect: false,
                              enableSuggestions: false,
                              toolbarOptions: const ToolbarOptions(
                                copy: false,
                                cut: false,
                                paste: true,
                                selectAll: false,
                              ),
                              onChanged: (newValue) {
                                _address = newValue;
                                _updatePreviewButtonState(_address);

                                setState(() {
                                  _addressToggleFlag = newValue.isNotEmpty;
                                });
                              },
                              focusNode: _addressFocusNode,
                              style: STextStyles.field(context),
                              decoration: InputDecoration(
                                hintText: "Paste address...",
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: UnconstrainedBox(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        if (_addressToggleFlag == true)
                                          TextFieldIconButton(
                                            key: const Key(
                                                "sendViewClearAddressFieldButtonKey"),
                                            onTap: () {
                                              sendToController.text = "";
                                              _address = "";
                                              _updatePreviewButtonState(
                                                  _address);
                                              setState(() {
                                                _addressToggleFlag = false;
                                              });
                                            },
                                            child: const XIcon(),
                                          ),
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
                                              if (FocusScope.of(context)
                                                  .hasFocus) {
                                                FocusScope.of(context)
                                                    .unfocus();
                                                await Future<void>.delayed(
                                                    const Duration(
                                                        milliseconds: 75));
                                              }

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

                                              Logging.instance.log(
                                                  "qrResult content: ${qrResult.rawContent}",
                                                  level: LogLevel.Info);

                                              final results =
                                                  AddressUtils.parseUri(
                                                      qrResult.rawContent);

                                              Logging.instance.log(
                                                  "qrResult parsed: $results",
                                                  level: LogLevel.Info);

                                              if (results.isNotEmpty &&
                                                  results["scheme"] ==
                                                      coin.uriScheme) {
                                                // auto fill address
                                                _address =
                                                    results["address"] ?? "";
                                                sendToController.text =
                                                    _address!;

                                                _updatePreviewButtonState(
                                                    _address);
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

                                                _updatePreviewButtonState(
                                                    _address);
                                                setState(() {
                                                  _addressToggleFlag =
                                                      sendToController
                                                          .text.isNotEmpty;
                                                });
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
                                        TextFieldIconButton(
                                          key: const Key(
                                              "sendViewAddressBookButtonKey"),
                                          onTap: () async {
                                            await Navigator.of(context)
                                                .pushNamed(
                                              AddressBookView.routeName,
                                              arguments: (String name,
                                                  String address) {
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

                                            _updatePreviewButtonState(_address);

                                            setState(() {
                                              _addressToggleFlag =
                                                  _address != null &&
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
                                  ),
                                ),
                              ),
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
                                      style:
                                          STextStyles.label(context).copyWith(
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
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  SendAmountView.routeName,
                                  arguments: Tuple2(
                                    "$ref.read(walletProvider)!.walletId",
                                    Coin.epicCash,
                                  ),
                                );
                                debugPrint("$_address");
                              }),
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
      ),
    );
  }
}
