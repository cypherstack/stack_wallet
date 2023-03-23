import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/pages/address_book_views/address_book_view.dart';
import 'package:stackwallet/pages/address_book_views/subviews/contact_popup.dart';
import 'package:stackwallet/pages/exchange_view/choose_from_stack_view.dart';
import 'package:stackwallet/pages/exchange_view/exchange_step_views/step_3_view.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/step_row.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/exchange/majestic_bank/majestic_bank_exchange.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
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

  bool enableNext = false;

  bool isStackCoin(String ticker) {
    try {
      coinFromTickerCaseInsensitive(ticker);
      return true;
    } on ArgumentError catch (_) {
      return false;
    }
  }

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
            .then((value) {
          _toController.text = value;
          model.recipientAddress = _toController.text;
        });
      } else {
        if (model.sendTicker.toUpperCase() ==
            tuple.item2.ticker.toUpperCase()) {
          ref
              .read(walletsChangeNotifierProvider)
              .getManager(tuple.item1)
              .currentReceivingAddress
              .then((value) {
            _refundController.text = value;
            model.refundAddress = _refundController.text;
          });
        }
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
    final supportsRefund = ref.watch(
            exchangeFormStateProvider.select((value) => value.exchange.name)) !=
        MajesticBankExchange.exchangeName;

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
          title: Text(
            "Swap",
            style: STextStyles.navBarTitle(context),
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
                            style: STextStyles.pageTitleH1(context),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            "Enter your recipient and refund addresses",
                            style: STextStyles.itemSubtitle(context),
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Recipient Wallet",
                                style: STextStyles.smallMed12(context),
                              ),
                              if (isStackCoin(model.receiveTicker))
                                CustomTextButton(
                                  text: "Choose from Stack",
                                  onTap: () {
                                    try {
                                      final coin =
                                          coinFromTickerCaseInsensitive(
                                        model.receiveTicker,
                                      );
                                      Navigator.of(context)
                                          .pushNamed(
                                        ChooseFromStackView.routeName,
                                        arguments: coin,
                                      )
                                          .then((value) async {
                                        if (value is String) {
                                          final manager = ref
                                              .read(
                                                  walletsChangeNotifierProvider)
                                              .getManager(value);

                                          _toController.text =
                                              manager.walletName;
                                          model.recipientAddress = await manager
                                              .currentReceivingAddress;

                                          setState(() {
                                            enableNext =
                                                _toController.text.isNotEmpty &&
                                                    (_refundController
                                                            .text.isNotEmpty ||
                                                        !supportsRefund);
                                          });
                                        }
                                      });
                                    } catch (e, s) {
                                      Logging.instance
                                          .log("$e\n$s", level: LogLevel.Info);
                                    }
                                  },
                                ),
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
                              style: STextStyles.field(context),
                              onChanged: (value) {
                                model.recipientAddress = _toController.text;
                                setState(() {
                                  enableNext = _toController.text.isNotEmpty &&
                                      (_refundController.text.isNotEmpty ||
                                          !supportsRefund);
                                });
                              },
                              decoration: standardInputDecoration(
                                "Enter the ${model.receiveTicker.toUpperCase()} payout address",
                                _toFocusNode,
                                context,
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
                                                  model.recipientAddress =
                                                      _toController.text;

                                                  setState(() {
                                                    enableNext = _toController
                                                            .text.isNotEmpty &&
                                                        (_refundController.text
                                                                .isNotEmpty ||
                                                            !supportsRefund);
                                                  });
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

                                                    _toController.text =
                                                        content;
                                                    model.recipientAddress =
                                                        _toController.text;

                                                    setState(() {
                                                      enableNext = _toController
                                                              .text
                                                              .isNotEmpty &&
                                                          (_refundController
                                                                  .text
                                                                  .isNotEmpty ||
                                                              !supportsRefund);
                                                    });
                                                  }
                                                },
                                                child:
                                                    _toController.text.isEmpty
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
                                                  .then((_) {
                                                ref
                                                    .read(
                                                        exchangeFlowIsActiveStateProvider
                                                            .state)
                                                    .state = false;

                                                final address = ref
                                                    .read(
                                                        exchangeFromAddressBookAddressStateProvider
                                                            .state)
                                                    .state;
                                                if (address.isNotEmpty) {
                                                  _toController.text = address;
                                                  model.recipientAddress =
                                                      _toController.text;
                                                  ref
                                                      .read(
                                                          exchangeFromAddressBookAddressStateProvider
                                                              .state)
                                                      .state = "";
                                                }
                                                setState(() {
                                                  enableNext = _toController
                                                          .text.isNotEmpty &&
                                                      (_refundController.text
                                                              .isNotEmpty ||
                                                          !supportsRefund);
                                                });
                                              });
                                            },
                                            child: const AddressBookIcon(),
                                          ),
                                        if (_toController.text.isEmpty)
                                          TextFieldIconButton(
                                            key: const Key(
                                                "sendViewScanQrButtonKey"),
                                            onTap: () async {
                                              try {
                                                final qrResult =
                                                    await scanner.scan();

                                                final results =
                                                    AddressUtils.parseUri(
                                                        qrResult.rawContent);
                                                if (results.isNotEmpty) {
                                                  // auto fill address
                                                  _toController.text =
                                                      results["address"] ?? "";
                                                  model.recipientAddress =
                                                      _toController.text;

                                                  setState(() {
                                                    enableNext = _toController
                                                            .text.isNotEmpty &&
                                                        (_refundController.text
                                                                .isNotEmpty ||
                                                            !supportsRefund);
                                                  });
                                                } else {
                                                  _toController.text =
                                                      qrResult.rawContent;
                                                  model.recipientAddress =
                                                      _toController.text;

                                                  setState(() {
                                                    enableNext = _toController
                                                            .text.isNotEmpty &&
                                                        (_refundController.text
                                                                .isNotEmpty ||
                                                            !supportsRefund);
                                                  });
                                                }
                                              } on PlatformException catch (e, s) {
                                                Logging.instance.log(
                                                  "Failed to get camera permissions while trying to scan qr code in SendView: $e\n$s",
                                                  level: LogLevel.Warning,
                                                );
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
                              "This is the wallet where your ${model.receiveTicker.toUpperCase()} will be sent to.",
                              style: STextStyles.label(context),
                            ),
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          if (supportsRefund)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Refund Wallet (required)",
                                  style: STextStyles.smallMed12(context),
                                ),
                                if (isStackCoin(model.sendTicker))
                                  CustomTextButton(
                                    text: "Choose from Stack",
                                    onTap: () {
                                      try {
                                        final coin =
                                            coinFromTickerCaseInsensitive(
                                          model.sendTicker,
                                        );
                                        Navigator.of(context)
                                            .pushNamed(
                                          ChooseFromStackView.routeName,
                                          arguments: coin,
                                        )
                                            .then((value) async {
                                          if (value is String) {
                                            final manager = ref
                                                .read(
                                                    walletsChangeNotifierProvider)
                                                .getManager(value);

                                            _refundController.text =
                                                manager.walletName;
                                            model.refundAddress = await manager
                                                .currentReceivingAddress;
                                          }
                                          setState(() {
                                            enableNext =
                                                _toController.text.isNotEmpty &&
                                                    _refundController
                                                        .text.isNotEmpty;
                                          });
                                        });
                                      } catch (e, s) {
                                        Logging.instance.log("$e\n$s",
                                            level: LogLevel.Info);
                                      }
                                    },
                                  ),
                              ],
                            ),
                          if (supportsRefund)
                            const SizedBox(
                              height: 4,
                            ),
                          if (supportsRefund)
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
                                style: STextStyles.field(context),
                                onChanged: (value) {
                                  model.refundAddress = _refundController.text;
                                  setState(() {
                                    enableNext =
                                        _toController.text.isNotEmpty &&
                                            _refundController.text.isNotEmpty;
                                  });
                                },
                                decoration: standardInputDecoration(
                                  "Enter ${model.sendTicker.toUpperCase()} refund address",
                                  _refundFocusNode,
                                  context,
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
                                                    model.refundAddress =
                                                        _refundController.text;

                                                    setState(() {
                                                      enableNext = _toController
                                                              .text
                                                              .isNotEmpty &&
                                                          _refundController
                                                              .text.isNotEmpty;
                                                    });
                                                  },
                                                  child: const XIcon(),
                                                )
                                              : TextFieldIconButton(
                                                  key: const Key(
                                                      "sendViewPasteAddressFieldButtonKey"),
                                                  onTap: () async {
                                                    final ClipboardData? data =
                                                        await clipboard.getData(
                                                            Clipboard
                                                                .kTextPlain);
                                                    if (data?.text != null &&
                                                        data!
                                                            .text!.isNotEmpty) {
                                                      final content =
                                                          data.text!.trim();

                                                      _refundController.text =
                                                          content;
                                                      model.refundAddress =
                                                          _refundController
                                                              .text;

                                                      setState(() {
                                                        enableNext = _toController
                                                                .text
                                                                .isNotEmpty &&
                                                            _refundController
                                                                .text
                                                                .isNotEmpty;
                                                      });
                                                    }
                                                  },
                                                  child: _refundController
                                                          .text.isEmpty
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
                                                    .then((_) {
                                                  ref
                                                      .read(
                                                          exchangeFlowIsActiveStateProvider
                                                              .state)
                                                      .state = false;
                                                  final address = ref
                                                      .read(
                                                          exchangeFromAddressBookAddressStateProvider
                                                              .state)
                                                      .state;
                                                  if (address.isNotEmpty) {
                                                    _refundController.text =
                                                        address;
                                                    model.refundAddress =
                                                        _refundController.text;
                                                  }
                                                  setState(() {
                                                    enableNext = _toController
                                                            .text.isNotEmpty &&
                                                        _refundController
                                                            .text.isNotEmpty;
                                                  });
                                                });
                                              },
                                              child: const AddressBookIcon(),
                                            ),
                                          if (_refundController.text.isEmpty)
                                            TextFieldIconButton(
                                              key: const Key(
                                                  "sendViewScanQrButtonKey"),
                                              onTap: () async {
                                                try {
                                                  final qrResult =
                                                      await scanner.scan();

                                                  final results =
                                                      AddressUtils.parseUri(
                                                          qrResult.rawContent);
                                                  if (results.isNotEmpty) {
                                                    // auto fill address
                                                    _refundController.text =
                                                        results["address"] ??
                                                            "";
                                                    model.refundAddress =
                                                        _refundController.text;

                                                    setState(() {
                                                      enableNext = _toController
                                                              .text
                                                              .isNotEmpty &&
                                                          _refundController
                                                              .text.isNotEmpty;
                                                    });
                                                  } else {
                                                    _refundController.text =
                                                        qrResult.rawContent;
                                                    model.refundAddress =
                                                        _refundController.text;

                                                    setState(() {
                                                      enableNext = _toController
                                                              .text
                                                              .isNotEmpty &&
                                                          _refundController
                                                              .text.isNotEmpty;
                                                    });
                                                  }
                                                } on PlatformException catch (e, s) {
                                                  Logging.instance.log(
                                                    "Failed to get camera permissions while trying to scan qr code in SendView: $e\n$s",
                                                    level: LogLevel.Warning,
                                                  );
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
                          if (supportsRefund)
                            const SizedBox(
                              height: 6,
                            ),
                          if (supportsRefund)
                            RoundedWhiteContainer(
                              child: Text(
                                "In case something goes wrong during the exchange, we might need a refund address so we can return your coins back to you.",
                                style: STextStyles.label(context),
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
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: Theme.of(context)
                                      .extension<StackColors>()!
                                      .getSecondaryEnabledButtonStyle(context),
                                  child: Text(
                                    "Back",
                                    style: STextStyles.button(context).copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .buttonTextSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 16,
                              ),
                              Expanded(
                                child: PrimaryButton(
                                  label: "Next",
                                  enabled: enableNext,
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      Step3View.routeName,
                                      arguments: model,
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
      ),
    );
  }
}
